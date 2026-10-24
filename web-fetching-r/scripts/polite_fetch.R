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
