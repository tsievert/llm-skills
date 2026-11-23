# jw_probe.R -- probing a link: title classification, robots.txt check, page parsing, the fetch ladder with a render
# rung, route suggestions, and the whole-links probe. Loaded by jobwatch.R.

.nav_re <- paste0("^(home|about( us)?|contact|login|log in|sign in|register|cookies?|privacy|",
  "read more|more|next|previous|search|menu|skip to|english|svenska|deutsch|suomi|norsk|dansk|",
  "fran[cç]ais|accessibility|sitemap|imprint|impressum|terms|share|print|back|top)\\b")

.role_re <- paste0("post-?doc|postdoctoral|researcher|research (fellow|scientist|associate|group)|",
  "scientist|professor|lecturer|fellow|group leader|investigator|curator|adviser|advisor|",
  "wissenschaftlich|forsker|forskare|tutkija|teadur|vetenskaplig|forscher|chercheu|onderzoeker|",
  "universitair|docent|lektor|dosentti|stelle|vacanc|position|job|stilling|tjänst|toimi|ametikoht")

.topic_re <- paste0("behavio|ethol|ecolog|mammal|rodent|vole|mice|mouse|small mammal|carnivor|",
  "olfact|odou?r|scent|pheromon|chemical (ecology|communication|signal)|chemosens|sensory|",
  "zoolog|animal|wildlife|evolution|organismal|predat|predator|ungulate|verhalten|s[äa]ugetier|",
  "nager|k[äa]ttyr|fauna|jyrsij|nisäkäs|g[ _]?nagare|pattedyr|zoo")

.excl_re <- paste0("ph\\.?d\\.? (student|candidate|position|researcher|fellowship)|doctoral|",
  "doktorand|doktorrand|promovend|phd-stud|technician|techniker|laborant|lab(oratory)? staff|",
  "full professor|ordentliche[rn]? professor|teknisk|tekniker|laboratorio? tecnic|stagiaire|intern(ship)?\\b|",
  "master'?s? (student|thesis)|bachelor")

jw_classify_titles <- function(text, profile = NULL) {
  tl <- tolower(text)
  excl <- .excl_re
  if (!is.null(profile)) {
    ex <- profile$career_search_profile$target_search$excluded_job_titles
    ex <- tolower(unlist(ex)); ex <- ex[nzchar(ex) & !grepl("unpaid", ex)]
    if (length(ex)) excl <- paste0(excl, "|", paste(gsub("([.()+*?^$|\\\\])", "\\\\\\1", ex), collapse = "|"))
  }
  data.frame(
    role_hit = grepl(.role_re, tl), topic_hit = grepl(.topic_re, tl),
    excluded = grepl(excl, tl)
  )
}

# Some JavaScript-only portals fill the page from a JSON endpoint that needs no login. Two are supported, each
# opt-in per link with `json:eures` or `json:oracle` in the note column (the user decides after reading the
# site's terms; see references/portal-quirks.md). The portal URL stays the key in links.csv: the API call is
# built from its query parameters, so a filter change in the portal URL is a filter change here.
# jw_robots_allowed() is checked before every JSON call; a disallowed host is reported, not fetched.
.robots_cache <- new.env()

jw_robots_allowed <- function(url, timeout = 15) {
  root <- sub("^(https?://[^/]+).*$", "\\1", url)
  path <- sub("^https?://[^/]+", "", url); if (!nzchar(path)) path <- "/"
  txt <- .robots_cache[[root]]
  if (is.null(txt)) {
    r <- tryCatch(request(paste0(root, "/robots.txt")) |> req_user_agent(jw_ua) |> req_timeout(timeout) |>
                    req_error(is_error = \(r) FALSE) |> req_perform(), error = function(e) NULL)
    txt <- if (is.null(r)) NA_character_ else if (resp_status(r) >= 400) "" else
      tryCatch(.clean(resp_body_string(r)), error = function(e) "")
    assign(root, txt, envir = .robots_cache)
  }
  if (is.na(txt)) return(NA)
  ln <- trimws(sub("#.*$", "", strsplit(txt, "\r?\n")[[1]])); ln <- ln[nzchar(ln)]
  me <- tolower(jw_ua); cur <- character(); rules <- list(); last_ua <- FALSE
  for (l in ln) {
    k <- tolower(sub(":.*$", "", l)); v <- trimws(sub("^[^:]*:", "", l))
    if (k == "user-agent") { if (!last_ua) cur <- character(); cur <- c(cur, tolower(v)); last_ua <- TRUE
    } else if (k %in% c("allow", "disallow")) {
      last_ua <- FALSE
      for (a in cur) rules[[length(rules) + 1]] <- list(agent = a, allow = k == "allow", pat = v)
    } else last_ua <- FALSE
  }
  named <- Filter(function(r) r$agent != "*" && nzchar(r$agent) && grepl(r$agent, me, fixed = TRUE), rules)
  use <- if (length(named)) named else Filter(function(r) r$agent == "*", rules)
  best <- NULL
  for (r in use) {
    if (!nzchar(r$pat)) next
    esc <- gsub("([.+?^${}()|\\[\\]\\\\])", "\\\\\\1", sub("\\$$", "", r$pat), perl = TRUE)
    rx <- paste0("^", gsub("\\*", ".*", esc), if (grepl("\\$$", r$pat)) "$" else "")
    if (grepl(rx, path)) {
      len <- nchar(r$pat)
      if (is.null(best) || len > best$len || (len == best$len && r$allow)) best <- list(len = len, allow = r$allow)
    }
  }
  is.null(best) || best$allow
}

jw_probe_one <- function(url, timeout = 25, type = "portal") {
  t0 <- Sys.time()
  if (type == "resolver") return(.probe_gsheet(url, timeout, t0))
  if (type == "json_eures") return(.probe_eures(url, timeout, t0))
  if (type == "json_oracle") return(.probe_oracle(url, timeout, t0))
  # Generic recovery ladder (web-fetching-r): direct -> compatible user agent on 403 -> language-neutral/www/https
  # URL variants; a bot challenge stops it. Routes depend on the failure class, never on the site.
  r <- pf_fetch_ladder(url, jw_ua, timeout = timeout)
  out <- list(status = "error", http = NA_integer_, final_url = NA_character_, bytes = NA_integer_,
              text_chars = NA_integer_, n_scripts = NA_integer_, text_hash = NA_character_,
              note = NA_character_, anchors = NULL)
  route_note <- .jw_route_note(r)
  if (!r$ok && is.null(r$response)) { out$note <- paste(c(substr(conditionMessage(r$error), 1, 150), route_note), collapse = "; "); return(out) }
  resp <- r$response
  out$http <- resp_status(resp); out$final_url <- resp$url
  if (out$http < 400 && grepl("^https://docs\\.google\\.com/spreadsheets/d/", resp$url)) return(.probe_gsheet(url, timeout, t0))
  body <- resp_body_raw(resp); out$bytes <- length(body)
  ctype <- tolower(resp_content_type(resp) %||% "")
  if (!r$ok) {
    out$status <- if (r$failure_class %in% c("challenge", "forbidden") || out$http %in% c(401, 403, 429)) "blocked" else "http_error"
    out$note <- paste(c(.jw_failure_hint(r$failure_class), route_note), collapse = "; ")
    return(out)
  }
  out$route <- route_note
  if (!grepl("html|xml|gzip|octet-stream", ctype) && type != "sitemap") { out$status <- "non_html"; out$note <- ctype; return(out) }
  head_txt <- if (grepl("xml|gzip|octet-stream", ctype) || type == "sitemap") .sitemap_text(body) else ""
  if (grepl("<(urlset|sitemapindex)\\b", substr(head_txt, 1, 2000))) {
    doc <- tryCatch(read_xml(head_txt), error = function(e) NULL)
    if (is.null(doc)) { out$note <- "unparseable sitemap"; return(out) }
    locs <- xml_text(xml_find_all(doc, "//*[local-name()='loc']"))
    if (xml_name(doc) == "sitemapindex") {
      ord <- locs[order(!grepl("job|career|vacanc|stell", tolower(locs)))]
      locs <- unlist(lapply(ord, .sitemap_locs, depth = 1, budget = new.env()))
    }
    sm <- .sitemap_anchors(locs)
    out$anchors <- sm$anchors; out$status <- "ok"
    out$note <- sprintf("sitemap: %d URLs, %d vacancy-like%s", sm$n_urls, nrow(sm$anchors),
                        if (nrow(sm$anchors) >= 2000) " (capped at 2000: first listed kept)" else "")
    out$elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    return(out)
  }
  if (nzchar(head_txt) && grepl("<(rss|feed|rdf:RDF)\\b", substr(head_txt, 1, 2000))) {
    doc <- tryCatch(read_xml(head_txt), error = function(e) NULL)
    fd <- if (is.null(doc)) NULL else .feed_anchors(doc)
    if (is.null(fd)) { out$note <- "unparseable feed"; return(out) }
    out$anchors <- fd$anchors; out$status <- "ok"
    out$note <- sprintf("feed: %d items, %d with title and link", fd$n_items, nrow(fd$anchors))
    out$elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    return(out)
  }
  if (type == "sitemap") { out$note <- "type sitemap but the body is not sitemap XML"; return(out) }
  doc <- tryCatch(resp_body_html(resp), error = function(e) NULL)
  if (is.null(doc)) { out$note <- "unparseable html"; return(out) }
  pg <- .jw_parse_page(doc, out$final_url)
  if (pf_blocked_text(pg$vis) && pg$text_chars < 3000) {
    out$text_chars <- pg$text_chars; out$text_hash <- pg$text_hash; out$n_scripts <- pg$n_scripts
    out$status <- "blocked"; out$note <- "bot wall or JS required"; return(out)
  }
  thin <- pf_js_suspect(pg$text_chars, pg$n_scripts, nrow(pg$anchors))
  # Render rung: a page that is thin, or has fewer than `jobwatch.render_min_hits` (default 10) vacancy-like links, may be a JavaScript listing.
  # Headless Chrome (chromote, optional) loads it as a user would; robots.txt is checked for the page and for every
  # page/XHR request it makes. Opt out with options(jobwatch.render = FALSE). The rendered result replaces the static
  # one only if it has more vacancy-like links; a page that stays thin keeps its ok_js_suspect status.
  if ((thin || .jw_n_jobhits(pg$anchors) < getOption("jobwatch.render_min_hits", 10)) && isTRUE(getOption("jobwatch.render", TRUE)) &&
      isTRUE(jw_robots_allowed(out$final_url, timeout))) {
    rr <- pf_render_html(out$final_url, jw_ua, allow = function(u) jw_robots_allowed(u, timeout))
    if (rr$ok) {
      pg2 <- .jw_parse_page(read_html(rr$html), out$final_url)
      better <- .jw_n_jobhits(pg2$anchors) > .jw_n_jobhits(pg$anchors)
      if (better) { pg <- pg2; thin <- pf_js_suspect(pg$text_chars, pg$n_scripts, nrow(pg$anchors)) }
      out$route <- .jw_join_note(out$route, if (better) "render (headless Chrome)" else "render tried, no more vacancy-like links")
      if (better && length(rr$blocked)) out$route <- .jw_join_note(out$route, sprintf("robots.txt blocked %d request(s) of the page", length(rr$blocked)))
    } else out$route <- .jw_join_note(out$route, paste("render skipped:", rr$note))
  }
  out$text_chars <- pg$text_chars; out$text_hash <- pg$text_hash; out$n_scripts <- pg$n_scripts
  out$anchors <- pg$anchors
  out$status <- if (thin) "ok_js_suspect" else "ok"
  if (thin) out$note <- "few usable links or little text: listing probably rendered by JS, use webfetch or search instead"
  out$elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  out
}

# Anchors and visible-text measures of one parsed page (static or rendered).
.jw_parse_page <- function(doc, final_url) {
  n_scripts <- length(xml_find_all(doc, "//script"))
  ld <- .jsonld_anchors(doc, final_url)  # before the scripts are removed below
  anchors <- xml_find_all(doc, "//a[@href]")
  txt <- .clean(xml_text(anchors)); href <- .clean(xml_attr(anchors, "href"))
  xml_remove(xml_find_all(doc, "//script|//style|//noscript"))
  vis <- gsub("\\s+", " ", .clean(xml_text(doc)))
  txt <- trimws(gsub("\\s+", " ", txt))
  abs <- tryCatch(url_absolute(href, final_url), error = function(e) href)
  ok <- !is.na(txt) & nchar(txt) >= 12 & nchar(txt) <= 250 & !grepl(.nav_re, tolower(txt)) &
    grepl("^https?://", abs) & !grepl("^(mailto|javascript|tel):", href)
  a <- unique(data.frame(text = txt[ok], href = sub("#.*$", "", abs[ok])))
  if (nrow(ld)) a <- unique(rbind(a, ld))
  list(anchors = a, vis = vis, n_scripts = n_scripts, text_chars = nchar(vis), text_hash = substr(rlang::hash(vis), 1, 12))
}

# One-line summary of the ladder's attempts when a route other than the plain request was needed or all failed,
# for example "route: ua_compat (direct: forbidden 403)" or "tried direct 503, variant:drop-language-subdomain 200".
.jw_route_note <- function(r) {
  at <- r$attempts
  if (r$ok && identical(r$route, "direct")) return(NA_character_)
  tried <- paste0(at$route, " ", ifelse(is.na(at$http), at$class, at$http), collapse = ", ")
  if (r$ok) sprintf("route: %s (first try %s; tried %s)", r$route, r$failure_class, tried) else sprintf("tried %s", tried)
}

# What a failure class means for the next step; the wording is the same for every site.
.jw_failure_hint <- function(cls) switch(cls,
  challenge = "bot challenge (not bypassed): use a mirror or aggregator that lists the same posts, or the browser",
  forbidden = "forbidden even with a compatible user agent: check in a browser; do not work around a deliberate block",
  not_found = "not found: link moved, try jw_find_replacement()",
  transient = "server error persisted: retry next run; consec_fail counts it",
  client_error = "client error", network = "no response (DNS, TLS or timeout): test from another network", NA_character_)

# Number of vacancy-like anchors (needs jw_checks.R from scripts/pipeline; falls back to the anchor count)
.jw_n_jobhits <- function(a) {
  if (!nrow(a)) return(0L)
  if (!exists("jw_anchor_job_like", mode = "function")) return(nrow(a))
  cl <- jw_classify_titles(a$text)
  sum(jw_anchor_job_like(a$text, a$href, cl$role_hit, cl$topic_hit))
}

.jw_join_note <- function(note, route) {
  x <- c(note, route); x <- x[!is.na(x) & nzchar(x)]
  if (length(x)) paste(x, collapse = "; ") else NA_character_
}

# Candidate routes for a source that stayed thin, blocked or failed, found by the same generic checks for every
# link (feeds and sitemaps announced by the page or robots.txt, JSON-LD, API URLs, known portal platforms with their
# opt-in word). Returns one short string for the note column, or NA. Costs a few extra requests per thin source.
jw_suggest_routes <- function(url, timeout = 25) {
  d <- tryCatch(jw_discover_endpoints(url, timeout = timeout), error = function(e) NULL)
  if (is.null(d) || !nrow(d)) return(NA_character_)
  key <- d[d$kind %in% c("feed", "json-ld", "sitemap") | grepl("^known:", d$kind) | grepl("^platform:", d$kind) |
             (d$kind == "api in script" & d$robots_allowed %in% TRUE & d$status %in% 200L), ]
  if (!nrow(key)) return(NA_character_)
  paste("try:", paste(unique(sprintf("%s %s", key$kind, ifelse(grepl("^known:", key$kind), sub(".*use ([a-z:]+) in.*", "\\1", key$evidence),
                                                               substr(key$url, 1, 70)))), collapse = " | "))
}

# Probe every unique link once (search-engine URLs are not fetched: their query is returned for the
# web_search tool). Polite: one request at a time, >= `delay` s between requests to the same host.
jw_probe <- function(links, delay = 1.5, timeout = 25, profile = NULL, verbose = TRUE) {
  # A reduced data frame (url/section only) used to give zero rows without a message
  miss <- setdiff(c("n", "id", "url", "host", "type", "dup_of", "query"), names(links))
  if (length(miss)) stop("jw_probe() needs the data frame from jw_read_links(); missing columns: ",
                         paste(miss, collapse = ", "), call. = FALSE)
  if (!nrow(links)) stop("jw_probe(): `links` has no rows", call. = FALSE)
  uniq <- links[is.na(links$dup_of), ]
  jw_wait_state <- new.env()  # per-call state, isolated from other skills' pf_wait() calls
  src <- list(); anc <- list()
  t_loop <- Sys.time()
  for (i in seq_len(nrow(uniq))) {
    r <- uniq[i, ]
    # announce before the request, so a slow page is visible while it is being fetched
    if (verbose) message(sprintf("[%d/%d] fetching %s", i, nrow(uniq), substr(r$url, 1, 80)))
    if (r$type == "search_engine") {
      src[[i]] <- data.frame(id = r$id, n = r$n, status = "search_engine", http = NA, final_url = NA,
                             text_hash = NA, n_anchors = 0L, note = r$query)
      next
    }
    pf_wait(r$host, delay, state = jw_wait_state)
    p <- tryCatch(jw_probe_one(r$url, timeout, type = r$type), error = function(e)
      list(status = "error", http = NA, final_url = NA, text_hash = NA, anchors = NULL,
           note = substr(conditionMessage(e), 1, 150)))
    na <- if (is.null(p$anchors)) 0L else nrow(p$anchors)
    src[[i]] <- data.frame(id = r$id, n = r$n, status = p$status, http = p$http, final_url = p$final_url,
                           text_hash = p$text_hash, n_anchors = na, note = .jw_join_note(p$note, p$route))
    if (na) anc[[length(anc) + 1]] <- cbind(source_id = r$id, p$anchors)
    if (verbose) jw_tick(i, nrow(uniq), t_loop, sprintf("%s, %d anchors%s", p$status, na,
                         if (!is.null(p$elapsed)) sprintf(", %.0fs", p$elapsed) else ""))
  }
  sources <- do.call(rbind, src)
  anchors <- if (length(anc)) do.call(rbind, anc) else
    data.frame(source_id = character(), text = character(), href = character())
  if (nrow(anchors)) anchors <- cbind(anchors, jw_classify_titles(anchors$text, profile))
  # Vacancy-likeness after every probe (needs jw_checks.R from scripts/pipeline; skipped when not sourced):
  # a page that was read but yields no vacancy-like link is a menu, not a listing.
  if (exists("jw_anchor_job_like", mode = "function")) {
    anchors$job_like <- if (nrow(anchors)) jw_anchor_job_like(anchors$text, anchors$href, anchors$role_hit, anchors$topic_hit) else logical()
    nj <- vapply(sources$id, function(i) sum(anchors$job_like[anchors$source_id == i]), 0)
    sources$n_job_like <- as.integer(nj); sources$flag <- jw_source_flag(sources$status, nj)
    # Generic route discovery for sources that were read but stayed thin (same checks for every link; the result
    # goes into the note column as "try: ..."). Opt out with options(jobwatch.suggest = FALSE).
    if (isTRUE(getOption("jobwatch.suggest", TRUE)))
      for (i in which(sources$flag %in% c("nav_only", "weak") & sources$status == "ok_js_suspect")) {
        u <- uniq$url[match(sources$id[i], uniq$id)]
        if (uniq$type[match(sources$id[i], uniq$id)] != "portal") next
        sg <- jw_suggest_routes(u, timeout); sources$note[i] <- .jw_join_note(sources$note[i], sg)
      }
    if (verbose) for (i in which(sources$flag %in% c("nav_only", "weak")))
      message("  ", sources$flag[i], ": ", substr(uniq$url[match(sources$id[i], uniq$id)], 1, 80))
  }
  list(sources = sources, anchors = anchors, links = links)
}
