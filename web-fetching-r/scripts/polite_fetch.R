# polite_fetch.R -- shared polite HTTP fetch mechanics for R skills (httr2/rvest/xml2).
# Source with: source("<skill-dir>/scripts/polite_fetch.R")
# No skill-specific logic lives here (no state files, no domain parsing, no policy decisions):
# callers keep their own state, parsing and rules, and pass their own user agent and thresholds.
# Extracted 2026-10-24 from job-opportunity-watch/scripts/jobwatch.R and
# recipe-notes-formatter/scripts/rn_web.R, which had independently implemented the same pattern.

suppressPackageStartupMessages({
  library(httr2)
})

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || (length(a) == 1 && is.na(a))) b else a

# Default shared state for pf_wait(); pass your own new.env() instead if you need isolation
# (e.g. in tests). Using the shared default means two different skills fetching the same host in
# one session still throttle each other, which is the intended, more polite behaviour.
.pf_state <- new.env()

#' Build a consistent, identifying user-agent string.
#' @param skill Short skill or tool name, e.g. "job-opportunity-watch".
#' @param purpose Short free-text purpose/contact note shown to site operators.
pf_user_agent <- function(skill, purpose, version = "0.1") {
  sprintf("%s/%s (%s)", skill, version, purpose)
}

#' Host name from a URL, for use as a pf_wait()/state key.
pf_host <- function(url) tolower(sub("^https?://([^/:?#]+).*$", "\\1", url))

#' Sleep just long enough that `min_interval` seconds have passed since the last request to
#' `host`. Call this immediately before each request to that host.
pf_wait <- function(host, min_interval = 1.5, state = .pf_state) {
  last <- state[[host]]
  if (!is.null(last)) {
    gap <- min_interval - as.numeric(difftime(Sys.time(), last, units = "secs"))
    if (gap > 0) Sys.sleep(gap)
  }
  state[[host]] <- Sys.time()
  invisible(NULL)
}

#' One HTTP request. Never throws on HTTP or network errors -- inspect the return value instead.
#' @return list(response = <httr2_response> or NULL, error = <condition> or NULL)
pf_perform <- function(url, ua, timeout = 25, max_tries = 2,
                        retry_on = c(429L, 502L, 503L, 504L), query = list()) {
  req <- request(url) |>
    req_user_agent(ua) |>
    req_timeout(timeout) |>
    req_retry(max_tries = max_tries, is_transient = function(r) resp_status(r) %in% retry_on) |>
    req_error(is_error = function(r) FALSE)
  if (length(query)) req <- req_url_query(req, !!!query)
  resp <- tryCatch(req_perform(req), error = function(e) e)
  if (inherits(resp, "error")) list(response = NULL, error = resp) else list(response = resp, error = NULL)
}

#' Fetch a page politely (rate-limited per host) and lightly parse it.
#' @return list(url, status ("ok"/"http_error"/"error"), http, content_type,
#'   html (raw body string, NA if not HTML), doc (xml2 document or NULL), problem (character or NA))
pf_fetch_html <- function(url, ua, min_interval = 1.5, timeout = 25, max_tries = 2,
                           retry_on = c(429L, 502L, 503L, 504L), state = .pf_state) {
  pf_wait(pf_host(url), min_interval, state)
  r <- pf_perform(url, ua, timeout, max_tries, retry_on)
  if (!is.null(r$error)) {
    return(list(url = url, status = "error", http = NA_integer_, content_type = NA_character_,
                html = NA_character_, doc = NULL,
                problem = paste("request failed:", conditionMessage(r$error))))
  }
  resp <- r$response
  st <- resp_status(resp)
  ct <- resp_content_type(resp)
  is_html <- st < 400 && grepl("html|xml", ct %||% "")
  html <- if (is_html) tryCatch(resp_body_string(resp, encoding = "UTF-8"), error = function(e) NA_character_)
          else NA_character_
  doc <- if (is_html && !is.na(html)) tryCatch(xml2::read_html(html), error = function(e) NULL) else NULL
  list(url = resp$url, status = if (st >= 400) "http_error" else "ok", http = st,
       content_type = ct, html = html, doc = doc,
       problem = if (!is_html) paste0("no HTML (status ", st, ", ", ct %||% "?", ")") else NA_character_)
}

#' Heuristic: does the start of the visible text look like a CAPTCHA/bot-wall/JS-required page?
pf_blocked_text <- function(text, max_chars = 3000) {
  if (is.na(text) || !nzchar(text)) return(FALSE)
  grepl("captcha|just a moment|access denied|verify you are human|enable javascript",
        tolower(substr(text, 1, max_chars)))
}

#' Heuristic: does a page look like it needs JS rendering (thin visible text/links, many scripts)?
#' The thresholds are the ones tested in job-opportunity-watch on real portal pages; override if a
#' different kind of page needs different defaults.
pf_js_suspect <- function(text_chars, n_scripts, n_anchors,
                           min_anchors = 8, min_chars = 800, min_scripts = 5) {
  (n_anchors < min_anchors) || (text_chars < min_chars && n_scripts >= min_scripts)
}

#' All HTML tables on a parsed page as a list of data frames (thin wrapper over rvest).
pf_tables <- function(doc) {
  if (is.null(doc)) return(list())
  rvest::html_table(doc, fill = TRUE)
}

# ---- Fetch ladder: generic recovery routes chosen by failure CLASS, never by site -------------------
# Added 2026-11-23. A failing request is classified once (pf_failure_class), and the class decides which
# generic routes are tried next. No host or portal name appears here, so a new problem link needs no new code.
# Bot challenges (Cloudflare "Just a moment", CAPTCHA, WAF challenge pages) are a stop: reported, never bypassed.

# Host-level memory of the route that worked (e.g. "ua_compat"), shared across calls in one session.
.pf_learned <- new.env()

#' Googlebot-style compatible user agent: still names the tool, but starts with the "Mozilla/5.0 (compatible; ...)"
#' token that some WAF rules require. It identifies the tool honestly; it does not pretend to be a browser.
pf_ua_compat <- function(ua) {
  if (grepl("^[^ ]+/[0-9.]+ \\(.*\\)$", ua)) sub("^([^ ]+/[0-9.]+) \\((.*)\\)$", "Mozilla/5.0 (compatible; \\1; \\2)", ua)
  else sprintf("Mozilla/5.0 (compatible; %s)", ua)
}

#' Classify one response: ok, challenge (bot wall: stop), forbidden (401/403 without a challenge), not_found
#' (404/410), transient (429/5xx), client_error (other 4xx) or network (no response).
pf_failure_class <- function(resp = NULL, err = NULL) {
  if (!is.null(err) || is.null(resp)) return("network")
  st <- httr2::resp_status(resp)
  if (st < 400) return("ok")
  hdr <- tolower(httr2::resp_header(resp, "cf-mitigated") %||% "")
  body <- tryCatch(tolower(substr(httr2::resp_body_string(resp), 1, 6000)), error = function(e) "")
  if (hdr == "challenge" ||
      grepl("just a moment|challenges\\.cloudflare\\.com|cf-chl|attention required|px-captcha|datadome|verify you are human", body))
    return("challenge")
  if (st %in% c(401L, 403L)) return("forbidden")
  if (st %in% c(404L, 410L)) return("not_found")
  if (st == 429L || st >= 500L) return("transient")
  "client_error"
}

#' Ordered, de-duplicated URL variants that often work when the given one fails: a language subdomain or path
#' segment dropped (the language-neutral URL), www toggled, http upgraded to https, trailing slash toggled.
#' Same site only; query strings are kept byte for byte.
pf_url_variants <- function(url, max_n = 3) {
  lang <- "(en|de|fr|sv|fi|no|nb|da|nl|et|lt|lv|is|it|es|pl)"
  v <- list(
    "drop-language-subdomain" = sub(paste0("^(https?://)", lang, "\\."), "\\1", url),
    "drop-language-path"      = sub(paste0("^(https?://[^/]+)/", lang, "(/|$)"), "\\1/", url),
    "toggle-www"              = if (grepl("^https?://www\\.", url)) sub("^(https?://)www\\.", "\\1", url) else sub("^(https?://)", "\\1www.", url),
    "upgrade-https"           = sub("^http://", "https://", url),
    "toggle-trailing-slash"   = if (grepl("^[^?#]*/([?#]|$)", url)) sub("/([?#]|$)", "\\1", url) else sub("^([^?#]*)", "\\1/", url))
  d <- data.frame(label = names(v), url = unlist(v, use.names = FALSE))
  d <- d[d$url != url & !duplicated(d$url), , drop = FALSE]
  rownames(d) <- NULL
  utils::head(d, max_n)
}

#' Fetch with the generic recovery ladder. Order: direct request -> on `forbidden` the compatible user agent ->
#' on forbidden/not_found/network/transient the URL variants. `challenge` stops at once.
#' @return list(response, error, url_used, route ("direct", "ua_compat", "variant:<label>[+ua_compat]"),
#'   failure_class (of the first attempt; "ok" when the direct request worked), attempts (data frame), ok (logical))
pf_fetch_ladder <- function(url, ua, timeout = 25, retry_on = c(429L, 502L, 503L, 504L), min_interval = 1.5,
                            max_variants = 3, state = .pf_state, learned = .pf_learned) {
  compat <- pf_ua_compat(ua); host <- pf_host(url)
  att <- list()
  go <- function(u, ua_use, route, tries = 1) {
    pf_wait(pf_host(u), min_interval, state)
    r <- pf_perform(u, ua_use, timeout, max_tries = tries, retry_on = retry_on)
    cls <- pf_failure_class(r$response, r$error)
    att[[length(att) + 1]] <<- data.frame(route = route, url = u, class = cls,
                                          http = if (is.null(r$response)) NA_integer_ else httr2::resp_status(r$response))
    r$class <- cls; r$url_used <- u; r$route <- route; r
  }
  finish <- function(r, first) {
    if (r$class == "ok" && grepl("ua_compat", r$route)) assign(host, "ua_compat", envir = learned)
    list(response = r$response, error = r$error, url_used = r$url_used, route = r$route, failure_class = first,
         attempts = do.call(rbind, att), ok = r$class == "ok")
  }
  learned_ua <- identical(get0(host, envir = learned, inherits = FALSE), "ua_compat")
  cur_ua <- if (learned_ua) compat else ua
  a <- go(url, cur_ua, if (learned_ua) "ua_compat" else "direct", tries = 2)
  if (a$class %in% c("ok", "challenge")) return(finish(a, a$class))
  last <- a
  if (a$class == "forbidden" && !learned_ua) {
    b <- go(url, compat, "ua_compat"); last <- b
    if (b$class %in% c("ok", "challenge")) return(finish(b, a$class))
    cur_ua <- compat
  }
  vv <- pf_url_variants(url, max_variants)
  # A 404 is a wrong path, not a host problem: only the language-neutral variants are worth a request.
  if (a$class == "not_found") vv <- vv[grepl("^drop-language", vv$label), , drop = FALSE]
  for (i in seq_len(nrow(vv))) {
    route <- paste0("variant:", vv$label[i], if (identical(cur_ua, compat)) "+ua_compat" else "")
    b <- go(vv$url[i], cur_ua, route)
    if (b$class == "ok") return(finish(b, a$class))
    if (b$class == "challenge") break
  }
  finish(a, a$class)
}


#' Render a page in headless Chrome (chromote) and return the DOM as HTML, for pages whose listing is built by
#' JavaScript. Returns ok = FALSE with a note when chromote or Chrome is missing, or the rendered text is a bot wall.
#' Images, fonts and media are never loaded. `allow` is an optional function(url) -> TRUE/FALSE/NA (for example a
#' robots.txt check): every page, XHR and fetch request the browser makes is passed to it, and a FALSE request is
#' cancelled, so the page's own scripts cannot reach hosts the caller may not fetch.
#' @return list(ok, html, note, blocked (character: URLs cancelled by `allow`))
pf_render_html <- function(url, ua, wait_max = 10, settle = 2, allow = NULL) {
  fail <- function(note) list(ok = FALSE, html = NA_character_, note = note, blocked = character())
  if (!requireNamespace("chromote", quietly = TRUE)) return(fail("chromote not installed"))
  if (is.null(tryCatch(chromote::find_chrome(), error = function(e) NULL))) return(fail("no Chrome/Chromium found"))
  blocked <- character()
  tryCatch({
    b <- chromote::ChromoteSession$new(); on.exit(try(b$close(), silent = TRUE), add = TRUE)
    b$Network$setUserAgentOverride(userAgent = pf_ua_compat(ua))
    b$Fetch$enable(patterns = list(list(urlPattern = "*", requestStage = "Request")))
    b$Fetch$requestPaused(callback_ = function(ev) {
      ty <- ev$resourceType %||% ""
      u <- ev$request$url
      ok <- !(ty %in% c("Image", "Font", "Media")) &&
        (!(ty %in% c("Document", "XHR", "Fetch")) || !is.function(allow) || !isFALSE(allow(u)))
      if (!ok && !(ty %in% c("Image", "Font", "Media"))) blocked <<- c(blocked, u)
      p <- if (ok) b$Fetch$continueRequest(requestId = ev$requestId, wait_ = FALSE)
           else b$Fetch$failRequest(requestId = ev$requestId, errorReason = "BlockedByClient", wait_ = FALSE)
      # a late event after the session closed rejects the promise; that is harmless, so it is swallowed
      promises::catch(p, function(e) NULL)
    })
    b$Page$navigate(url, wait_ = TRUE)
    html <- ""; same <- 0L; t0 <- Sys.time()
    while (as.numeric(difftime(Sys.time(), t0, units = "secs")) < wait_max && same < settle) {
      Sys.sleep(1)
      h <- b$Runtime$evaluate("document.documentElement.outerHTML")$result$value %||% ""
      same <- if (nchar(h) == nchar(html)) same + 1L else 0L
      html <- h
    }
    txt <- gsub("\\s+", " ", xml2::xml_text(xml2::read_html(html)))
    if (pf_blocked_text(txt) && nchar(txt) < 3000) return(fail("rendered page is a bot wall; not bypassed"))
    list(ok = TRUE, html = html, note = "rendered with headless Chrome", blocked = unique(blocked))
  }, error = function(e) fail(paste("render failed:", substr(conditionMessage(e), 1, 100))))
}
