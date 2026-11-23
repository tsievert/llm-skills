# jw_sources.R -- source-type extractors: sitemap, RSS/Atom, Google Sheet, JSON endpoints (EURES, Oracle),
# JSON-LD, endpoint discovery. Network access goes through web-fetching-r (pf_*). Loaded by jobwatch.R.

# Sitemap XML as a source (type = "sitemap", or any XML body that is a urlset/sitemapindex). A sitemap lists
# every page of a site, so only vacancy-looking URLs are kept as anchors (cap `max_anchors`); the link text is
# built from the URL slug ("postdoc-vole-ecology/123" -> "postdoc vole ecology"). An index is followed one
# level (job/career-looking children first, at most 8 requests via .sitemap_locs).
.sitemap_text <- function(body) {
  if (length(body) > 2 && body[1] == as.raw(0x1f) && body[2] == as.raw(0x8b))
    body <- tryCatch(memDecompress(body, "gzip", asChar = FALSE), error = function(e) raw())
  .clean(rawToChar(body))
}

.slug_text <- function(u) {
  s <- utils::URLdecode(sub("[?#].*$", "", u)); s <- sub("/+$", "", s)
  s <- sub("^.*/", "", sub("/\\d+$", "", s))
  trimws(gsub("[-_+]+|\\.(html?|php|aspx?)$", " ", sub("\\.(html?|php|aspx?)$", "", s)))
}

# A whole-site sitemap is mostly articles, authors and menus, so the URL filter is stricter than the anchor
# check: a job word must be a whole path segment or word of the slug.
.sitemap_job_re <- paste0("(^|[/_.-])(vacanc[a-z]*|jobs?|careers?|positions?|openings?|stellen[a-z]*|ausschreibung[a-z]*|",
  "vacatures?|ledig[a-z]*|rekry[a-z]*|tyopaik[a-z]*|avoimet|emploi|offres?|postdocs?|postdoctoral|lecturer|",
  "fellowships?|hiring|recruit[a-z]*|tjanst[a-z]*)($|[/_.-])")

.sitemap_anchors <- function(locs, max_anchors = 2000) {
  locs <- locs[!is.na(locs)]
  locs <- ifelse(grepl("^https?://", locs), locs, ifelse(grepl("^[a-z0-9.-]+\\.[a-z]{2,}(/|$)", locs, ignore.case = TRUE), paste0("https://", locs), locs))
  locs <- unique(locs[grepl("^https?://", locs)])
  locs <- locs[!duplicated(sub("/\\d+/?$", "", locs))]          # same posting under several numeric ids
  txt <- vapply(locs, .slug_text, "", USE.NAMES = FALSE)
  keep <- grepl(.sitemap_job_re, tolower(sub("^https?://[^/]+", "", utils::URLdecode(locs))), perl = TRUE) & nchar(txt) >= 12
  a <- data.frame(text = txt[keep], href = locs[keep])
  list(anchors = utils::head(a, max_anchors), n_urls = length(locs))
}

# RSS 2.0, Atom and RDF feeds as a source: one anchor per item (title + link). Items are not filtered
# here; the job-like flag and the profile prefilter downstream do that. Returns NULL if `doc` is no feed.
.feed_anchors <- function(doc) {
  root <- xml_name(doc)
  if (!root %in% c("rss", "feed", "RDF")) return(NULL)
  items <- xml_find_all(doc, "//*[local-name()='item' or local-name()='entry']")
  one <- function(it) {
    ttl <- xml_text(xml_find_first(it, "./*[local-name()='title']"))
    lnk <- xml_find_first(it, "./*[local-name()='link']")
    href <- if (inherits(lnk, "xml_missing")) NA_character_ else {
      h <- xml_attr(lnk, "href"); if (is.na(h)) xml_text(lnk) else h   # Atom: href attribute; RSS: text
    }
    if (is.na(href) || !nzchar(trimws(href))) {
      g <- xml_text(xml_find_first(it, "./*[local-name()='guid']")); if (grepl("^https?://", g %||% "")) href <- g
    }
    c(text = trimws(gsub("\\s+", " ", ttl %||% "")), href = trimws(href))
  }
  m <- if (length(items)) do.call(rbind, lapply(items, one)) else matrix(character(), 0, 2, dimnames = list(NULL, c("text", "href")))
  a <- unique(as.data.frame(m, stringsAsFactors = FALSE))
  a <- a[!is.na(a$href) & grepl("^https?://", a$href) & nchar(a$text) >= 8, , drop = FALSE]
  list(anchors = a, n_items = length(items))
}

# A stable link that redirects to a Google Sheet which changes every year (community job boards). Never pin the
# resolved sheet id or tab gids in links.csv: keep the stable URL and resolve at run time. Steps: read the
# redirect target without fetching it, read tab names and gids from the public /htmlview page, pick tabs by
# name (case-insensitive regex), download each as CSV. Returns a named list of data frames (one per tab).
# Tab banners and duplicate header names are common: `header_row` says which row holds the headers (the
# default 2 fits a banner row above them); names are made unique. Filter the rows locally (location, dates).
jw_resolve_gsheet <- function(url, tabs = "postdoc|faculty|permanent", header_row = 2, timeout = 40) {
  get <- function(u, ...) request(u) |> req_user_agent(jw_ua) |> req_timeout(timeout) |>
    req_error(is_error = \(r) FALSE) |> req_options(...) |> req_perform()
  target <- url
  if (!grepl("docs\\.google\\.com/spreadsheets/d/", url)) {
    r <- get(url, followlocation = FALSE)
    target <- resp_header(r, "location")
    if (is.null(target) || !grepl("docs\\.google\\.com/spreadsheets/d/", target)) stop("no Google Sheet redirect from ", url)
  }
  id <- sub("^.*/spreadsheets/d/([^/?#]+).*$", "\\1", target)
  h <- get(paste0("https://docs.google.com/spreadsheets/d/", id, "/htmlview"))
  if (resp_status(h) >= 400) stop("sheet is not public or not found (HTTP ", resp_status(h), ")")
  m <- regmatches(resp_body_string(h), gregexpr("items\\.push\\(\\{name: \"[^\"]*\"[^}]*?gid: \"[0-9]+\"", resp_body_string(h)))[[1]]
  if (!length(m)) stop("no tab list found on the htmlview page (layout changed?)")
  nm <- gsub("\\\\/", "/", sub("^items\\.push\\(\\{name: \"([^\"]*)\".*$", "\\1", m))
  gid <- sub("^.*gid: \"([0-9]+)\"$", "\\1", m)
  pick <- grepl(tabs, nm, ignore.case = TRUE)
  out <- list()
  for (i in which(pick)) {
    r <- get(sprintf("https://docs.google.com/spreadsheets/d/%s/export?format=csv&gid=%s", id, gid[i]))
    if (resp_status(r) >= 400) { warning("tab '", nm[i], "': HTTP ", resp_status(r)); next }
    d <- utils::read.csv(text = resp_body_string(r), header = FALSE, stringsAsFactors = FALSE, na.strings = "", check.names = FALSE)
    if (nrow(d) < header_row) next
    hd <- trimws(as.character(unlist(d[header_row, ]))); hd[is.na(hd) | !nzchar(hd)] <- paste0("col", which(is.na(hd) | !nzchar(hd)))
    names(d) <- make.unique(hd, sep = "_"); d <- d[-seq_len(header_row), , drop = FALSE]; rownames(d) <- NULL
    out[[nm[i]]] <- d
  }
  attr(out, "sheet_id") <- id; attr(out, "all_tabs") <- nm
  out
}

# Sheet rows -> anchors (text from institution, subject, rank/PI, location; href from the URL column).
.gsheet_anchors <- function(tabs, max_anchors = 2000) {
  one <- function(d) {
    cn <- tolower(names(d)); col <- function(p) { i <- grep(p, cn)[1]; if (is.na(i)) rep(NA_character_, nrow(d)) else as.character(d[[i]]) }
    href <- trimws(col("^(url|link)")); href <- ifelse(grepl("^[a-z0-9.-]+\\.[a-z]{2,}/", href, ignore.case = TRUE), paste0("https://", href), href)
    txt <- apply(cbind(col("^institution"), col("^subject"), col("^(rank|pi)$"), col("^location")), 1,
                 function(x) trimws(gsub("\\s+", " ", paste(x[!is.na(x)], collapse = " - "))))
    data.frame(text = txt, href = href)
  }
  a <- unique(do.call(rbind, c(list(data.frame(text = character(), href = character())), lapply(tabs, one))))
  a <- a[grepl("^https?://", a$href) & nchar(a$text) >= 12, , drop = FALSE]
  utils::head(a, max_anchors)
}

.probe_gsheet <- function(url, timeout, t0) {
  out <- list(status = "error", http = NA_integer_, final_url = NA_character_, bytes = NA_integer_, text_chars = NA_integer_,
              n_scripts = NA_integer_, text_hash = NA_character_, note = NA_character_, anchors = NULL)
  tabs <- tryCatch(jw_resolve_gsheet(url, tabs = getOption("jobwatch.gsheet_tabs", "postdoc|faculty|permanent"), timeout = timeout),
                   error = function(e) conditionMessage(e))
  if (is.character(tabs)) { out$note <- substr(paste("resolver:", tabs), 1, 150); return(out) }
  out$anchors <- .gsheet_anchors(tabs); out$status <- "ok"; out$http <- 200L
  out$final_url <- paste0("https://docs.google.com/spreadsheets/d/", attr(tabs, "sheet_id"))
  out$note <- sprintf("resolver: %d tabs (%s), %d rows, %d with a link", length(tabs), paste(names(tabs), collapse = ", "),
                      sum(vapply(tabs, nrow, 1L)), nrow(out$anchors))
  out$elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  out
}

.json_out <- function() list(status = "error", http = NA_integer_, final_url = NA_character_, bytes = NA_integer_,
                             text_chars = NA_integer_, n_scripts = NA_integer_, text_hash = NA_character_,
                             note = NA_character_, anchors = NULL)

# accept_encoding identity: the EURES server answers a compressed request with a body libcurl cannot read
# (R curl error "Failure when receiving data"; verified 2026-11-03, plain curl works).
.json_post <- function(url, body, timeout) request(url) |> req_user_agent(jw_ua) |> req_timeout(timeout) |>
  req_options(accept_encoding = "identity") |> req_error(is_error = \(r) FALSE) |> req_body_json(body, auto_unbox = TRUE, null = "null") |> req_perform()

.q1 <- function(q, nm) { v <- q[[nm]]; if (is.null(v) || !nzchar(v[1])) character() else strsplit(utils::URLdecode(v[1]), ",", fixed = TRUE)[[1]] }

# EURES job-vacancy search. Portal URL parameters map to the public search API; unknown parameters are listed in
# the note. A keyword with a leading "-" is an exclusion in the portal: it is applied locally to the title.
.probe_eures <- function(url, timeout, t0, max_rows = 250) {
  out <- .json_out(); api <- "https://europa.eu/eures/api/jv-searchengine/public/jv-search/search"
  if (isFALSE(jw_robots_allowed(api, timeout))) { out$note <- "robots.txt disallows the API path; not fetched"; return(out) }
  q <- httr2::url_parse(url)$query %||% list()
  known <- c("page", "resultsPerPage", "orderBy", "locationCodes", "keywordsEverywhere", "positionScheduleCodes",
             "educationLevel", "publicationPeriod", "escoOccupation", "minNumberPost", "lang")
  kw <- .q1(q, "keywordsEverywhere"); esco <- .q1(q, "escoOccupation")
  body <- list(resultsPerPage = 50L, page = 1L, sortSearch = if (identical(q$orderBy, "BEST_MATCH")) "BEST_MATCH" else "MOST_RECENT",
               keywords = lapply(kw[!startsWith(kw, "-")], function(k) list(keyword = k, specificSearchCode = "EVERYWHERE")),
               publicationPeriod = if (length(q$publicationPeriod)) q$publicationPeriod else NULL,
               occupationUris = as.list(if (length(esco)) paste0("http://data.europa.eu/esco/occupation/", esco) else character()),
               skillUris = list(), requiredExperienceCodes = list(), sectorCodes = list(), positionOfferingCodes = list(),
               positionScheduleCodes = as.list(.q1(q, "positionScheduleCodes")),
               educationAndQualificationLevelCodes = as.list(.q1(q, "educationLevel")),
               locationCodes = as.list(.q1(q, "locationCodes")), euresFlagCodes = list(), otherBenefitsCodes = list(),
               requiredLanguages = list(), minNumberPost = if (length(q$minNumberPost)) as.integer(q$minNumberPost) else NULL,
               sessionId = "jobwatch")
  excl <- tolower(sub("^-", "", kw[startsWith(kw, "-")]))
  rows <- list(); total <- NA_integer_; page <- 1L
  repeat {
    body$page <- page
    r <- tryCatch(.json_post(api, body, timeout), error = function(e) e)
    if (inherits(r, "error")) { out$note <- paste("eures:", substr(conditionMessage(r), 1, 120)); return(out) }
    out$http <- resp_status(r)
    if (out$http >= 400) { out$status <- "http_error"; out$note <- "eures API refused the request (portal filter codes may not map)"; return(out) }
    x <- resp_body_json(r); total <- x$numberRecords %||% total
    for (j in x$jvs) {
      ctry <- paste(toupper(names(j$locationMap %||% list())), collapse = "/")
      dt <- if (is.numeric(j$creationDate)) format(as.Date(as.POSIXct(j$creationDate / 1000, origin = "1970-01-01", tz = "UTC")), "%Y-%m-%d") else ""
      rows[[length(rows) + 1]] <- data.frame(
        text = trimws(sprintf("%s - %s (%s) posted %s", j$title %||% "", j$employer$name %||% "", ctry, dt)),
        href = paste0("https://europa.eu/eures/portal/jv-se/jv-details/", j$id, "?lang=en"))
    }
    if (length(rows) >= min(total %||% 0L, max_rows) || !length(x$jvs)) break
    page <- page + 1L; Sys.sleep(1.5)
  }
  a <- unique(do.call(rbind, c(list(data.frame(text = character(), href = character())), rows)))
  if (length(excl)) a <- a[!Reduce(`|`, lapply(excl, function(e) grepl(e, tolower(a$text), fixed = TRUE))), , drop = FALSE]
  unk <- setdiff(names(q), known)
  out$anchors <- utils::head(a, max_rows); out$status <- "ok"; out$final_url <- url
  out$note <- sprintf("json:eures %d of %d records read%s%s", nrow(out$anchors), total %||% NA_integer_,
                      if (length(excl)) paste0("; excluded locally: ", paste(excl, collapse = ",")) else "",
                      if (length(unk)) paste0("; ignored parameters: ", paste(unk, collapse = ",")) else "")
  out$elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  out
}

# Oracle Candidate Experience (portals at <tenant>.fa.<region>.oraclecloud.com/hcmUI/CandidateExperience/...).
# The site number comes from the portal URL path; facet parameters of the portal URL are passed to the finder.
.probe_oracle <- function(url, timeout, t0, max_rows = 500) {
  out <- .json_out()
  base <- sub("^(https?://[^/]+).*$", "\\1", url)
  site <- sub("^.*/sites/([^/?#]+).*$", "\\1", url); lang <- sub("^.*/CandidateExperience/([a-zA-Z_-]+)/.*$", "\\1", url)
  if (identical(site, url) || identical(lang, url)) { out$note <- "json:oracle needs a .../hcmUI/CandidateExperience/<lang>/sites/<site>/... URL"; return(out) }
  api <- paste0(base, "/hcmRestApi/resources/latest/recruitingCEJobRequisitions")
  if (isFALSE(jw_robots_allowed(api, timeout))) { out$note <- "robots.txt disallows the API path; not fetched"; return(out) }
  q <- httr2::url_parse(url)$query %||% list()
  facets <- c("selectedCategoriesFacet", "selectedOrganizationsFacet", "selectedLocationsFacet", "selectedTitlesFacet",
              "selectedPostingDatesFacet", "selectedWorkplaceTypesFacet")
  use <- intersect(facets, names(q)); unk <- setdiff(names(q), c(facets, "lastSelectedFacet", "keyword", "location", "mode"))
  fparts <- vapply(use, function(f) paste0(f, "=", utils::URLdecode(q[[f]][1])), "")
  if (length(q$keyword)) fparts <- c(fparts, paste0("keyword=", utils::URLdecode(q$keyword[1])))
  rows <- list(); total <- NA_integer_; off <- 0L; lim <- 100L
  repeat {
    fin <- paste0("findReqs;siteNumber=", site, ",limit=", lim, ",offset=", off, ",sortBy=POSTING_DATES_DESC",
                  if (length(fparts)) paste0(",", paste(fparts, collapse = ",")) else "")
    r <- tryCatch(request(api) |> req_user_agent(jw_ua) |> req_timeout(timeout) |> req_error(is_error = \(r) FALSE) |>
                    req_url_query(onlyData = "true", expand = "requisitionList", finder = fin) |> req_perform(), error = function(e) e)
    if (inherits(r, "error")) { out$note <- paste("oracle:", substr(conditionMessage(r), 1, 120)); return(out) }
    out$http <- resp_status(r)
    if (out$http >= 400) { out$status <- "http_error"; out$note <- "oracle REST API refused the request"; return(out) }
    it <- resp_body_json(r)$items[[1]]; total <- it$TotalJobsCount %||% total
    rl <- it$requisitionList
    for (j in rl) rows[[length(rows) + 1]] <- data.frame(
      text = trimws(paste0(j$Title %||% "", " - ", j$PrimaryLocation %||% "",
                           if (!is.null(j$PostingEndDate)) paste0(" - deadline ", j$PostingEndDate) else "")),
      href = sprintf("%s/hcmUI/CandidateExperience/%s/sites/%s/job/%s", base, lang, site, j$Id))
    off <- off + lim
    if (!length(rl) || length(rows) >= min(total %||% 0L, max_rows)) break
    Sys.sleep(1.5)
  }
  out$anchors <- utils::head(unique(do.call(rbind, c(list(data.frame(text = character(), href = character())), rows))), max_rows)
  out$status <- "ok"; out$final_url <- url
  out$note <- sprintf("json:oracle %d of %s postings read%s", nrow(out$anchors), total %||% "?",
                      if (length(unk)) paste0("; ignored parameters: ", paste(unk, collapse = ",")) else "")
  out$elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  out
}

# schema.org JobPosting objects in <script type="application/ld+json"> (also inside @graph or ItemList): a standard
# way for a page to expose vacancies even when the visible list is rendered by JavaScript.
.jsonld_anchors <- function(doc, base_url) {
  empty <- data.frame(text = character(), href = character())
  sc <- tryCatch(xml_text(xml_find_all(doc, "//script[@type='application/ld+json']")), error = function(e) character())
  found <- list()
  walk <- function(x) {
    if (!is.list(x)) return(invisible())
    ty <- unlist(x[["@type"]])
    if (!is.null(ty) && any(ty == "JobPosting")) {
      org <- x$hiringOrganization; org <- if (is.list(org)) org$name else org
      href <- x$url %||% x[["@id"]] %||% base_url
      txt <- paste(c(x$title %||% x$name, org, if (!is.null(x$validThrough)) paste("deadline", x$validThrough)), collapse = " - ")
      found[[length(found) + 1]] <<- data.frame(text = trimws(gsub("\\s+", " ", txt)), href = as.character(href))
    }
    for (el in x) walk(el)
  }
  for (s in sc) walk(tryCatch(jsonlite::fromJSON(s, simplifyVector = FALSE), error = function(e) NULL))
  if (!length(found)) return(empty)
  a <- unique(do.call(rbind, found)); a[nchar(a$text) >= 8 & grepl("^https?://", a$href), , drop = FALSE]
}

# Find what a stubborn page could be read from instead. One page request plus at most three same-site scripts
# (2 MB cap). Returns candidates with a robots.txt verdict and, for URLs found in scripts, the HTTP status and
# content type of one GET. Nothing is added to links.csv: propose a candidate to the user with this evidence.
jw_discover_endpoints <- function(url, timeout = 25, max_scripts = 3) {
  cand <- list(); add <- function(kind, u, ev) cand[[length(cand) + 1]] <<- data.frame(kind = kind, url = u, evidence = ev)
  base <- sub("^(https?://[^/]+).*$", "\\1", url)
  r <- pf_fetch_ladder(url, jw_ua, timeout = timeout)
  if (is.null(r$response)) stop("page not fetched: ", conditionMessage(r$error))
  resp <- r$response; html <- .clean(tryCatch(resp_body_string(resp), error = function(e) ""))
  doc <- tryCatch(read_html(html), error = function(e) NULL)
  if (grepl("oraclecloud\\.com/hcmUI/CandidateExperience", url)) add("known: oracle", url, "Oracle Candidate Experience URL; use json:oracle in the link note")
  if (grepl("europa\\.eu/eures/portal/.*/search", url)) add("known: eures", url, "EURES search URL; use json:eures in the link note")
  if (!is.null(doc)) {
    al <- xml_attr(xml_find_all(doc, "//link[@rel='alternate'][contains(@type,'rss') or contains(@type,'atom') or contains(@type,'xml')]"), "href")
    for (u in al[!is.na(al)]) add("feed", as.character(url_absolute(u, resp$url)), "link rel=alternate")
    nj <- nrow(.jsonld_anchors(doc, url)); if (nj) add("json-ld", url, sprintf("%d JobPosting objects on the page (the probe reads them)", nj))
    src <- xml_attr(xml_find_all(doc, "//script[@src]"), "src"); src <- as.character(url_absolute(src[!is.na(src)], resp$url))
    src <- utils::head(src[startsWith(src, base)], max_scripts)
    pats <- c(apiUrl = "apiUrl:\"(https?://[^\"]+)\"", api = "\"(https?://[^\"' ]+/(?:api|rest|wp-json)/[^\"' ]{0,60})\"")
    for (s in src) {
      rs <- pf_perform(s, jw_ua, timeout = timeout)
      if (is.null(rs$response) || resp_status(rs$response) >= 400) next
      b <- resp_body_raw(rs$response); if (length(b) > 2e6) next
      js <- .clean(rawToChar(b))
      for (nm in names(pats)) {
        m <- regmatches(js, gregexpr(pats[[nm]], js, perl = TRUE))[[1]]
        for (u in unique(sub(pats[[nm]], "\\1", m, perl = TRUE))) add("api in script", u, paste("found in", basename(s)))
      }
    }
  }
  # Sitemaps announced in robots.txt (already fetched and cached by the robots check)
  if (!is.na(jw_robots_allowed(url, timeout))) {
    rtxt <- .robots_cache[[sub("^(https?://[^/]+).*$", "\\1", url)]]
    sm <- if (is.character(rtxt) && !is.na(rtxt)) regmatches(rtxt, gregexpr("(?im)^\\s*sitemap:\\s*\\S+", rtxt, perl = TRUE))[[1]] else character()
    for (u in utils::head(trimws(sub("(?im)^\\s*sitemap:\\s*", "", sm, perl = TRUE)), 3)) add("sitemap", u, "listed in robots.txt")
  }
  fp <- c(greenhouse = "boards\\.greenhouse\\.io/([^/\"' ]+)", lever = "jobs\\.lever\\.co/([^/\"' ]+)",
          personio = "([a-z0-9-]+)\\.jobs\\.personio\\.(?:de|com)", recruitee = "([a-z0-9-]+)\\.recruitee\\.com",
          smartrecruiters = "(?:careers|jobs)\\.smartrecruiters\\.com/([^/\"' ]+)")
  for (nm in names(fp)) { m <- regmatches(html, regexpr(fp[[nm]], html, perl = TRUE))
    if (length(m)) { tok <- sub(fp[[nm]], "\\1", m, perl = TRUE)
      add(paste0("platform: ", nm), tok, "fingerprint in page; public job API patterns exist but were not tested by this helper") } }
  if (!length(cand)) return(data.frame(kind = character(), url = character(), evidence = character(),
                                       robots_allowed = logical(), status = integer(), content_type = character()))
  d <- unique(do.call(rbind, cand)); d$robots_allowed <- NA; d$status <- NA_integer_; d$content_type <- NA_character_
  for (i in which(grepl("^https?://", d$url) & d$kind %in% c("api in script", "feed"))) {
    d$robots_allowed[i] <- jw_robots_allowed(d$url[i], timeout)
    if (isTRUE(d$robots_allowed[i])) {
      g <- pf_perform(d$url[i], jw_ua, timeout = timeout)
      if (!is.null(g$response)) { d$status[i] <- resp_status(g$response); d$content_type[i] <- resp_content_type(g$response) %||% NA }
      Sys.sleep(1.5)
    }
  }
  rownames(d) <- NULL; d
}

.sitemap_locs <- function(url, depth = 0, budget = new.env()) {
  if (is.null(budget$n)) budget$n <- 0
  if (budget$n >= 8) return(character())
  budget$n <- budget$n + 1
  message(sprintf("  sitemap request %d/8: %s", budget$n, substr(url, 1, 80)))
  txt <- .get_text(url); if (is.null(txt)) return(character())
  doc <- tryCatch(read_xml(txt), error = function(e) NULL); if (is.null(doc)) return(character())
  locs <- xml_text(xml_find_all(doc, "//*[local-name()='loc']"))
  if (xml_name(doc) == "sitemapindex" && depth < 1) {
    # follow job/career-looking child sitemaps first, then the rest, within the budget
    ord <- locs[order(!grepl("job|career|vacanc|page|stell", tolower(locs)))]
    return(unlist(lapply(ord, .sitemap_locs, depth = depth + 1, budget = budget)))
  }
  locs
}
