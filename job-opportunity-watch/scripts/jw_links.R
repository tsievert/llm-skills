# jw_links.R -- the links file (links.csv): read, key and search-link helpers, and edits (backup + explicit
# confirmation only). Loaded by jobwatch.R.

# Format: links.csv (UTF-8) with columns url, section, label, enabled, added, added_by, replaces, note.
# Only `url` is required. `enabled = FALSE` rows are kept for history and are not probed. A legacy
# links.txt (URL lines, "#" comments, plain text lines = section labels) is still read and can be
# converted once with jw_convert_links_txt().
jw_links_cols <- c("url", "section", "label", "enabled", "added", "added_by", "replaces", "note")

# The links file in use: links.csv if it exists, else the legacy links.txt.
jw_links_path <- function() {
  csv <- jw_path("links.csv"); if (file.exists(csv)) csv else jw_path("links.txt")
}

.read_links_txt <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  section <- NA_character_; note <- character(); rows <- list()
  for (i in seq_along(lines)) {
    s <- trimws(lines[i])
    if (!nzchar(s)) next
    if (startsWith(s, "#")) { note <- c(note, trimws(sub("^#+", "", s))); next }
    urls <- regmatches(s, gregexpr("https?://[^[:space:]]+", s))[[1]]
    if (length(urls) == 0) { section <- s; note <- character(); next }
    for (u in urls) {
      rows[[length(rows) + 1]] <- data.frame(url = u, section = section, note = paste(note, collapse = " "))
      note <- character()
    }
  }
  if (!length(rows)) stop("No URLs found in ", path)
  do.call(rbind, rows)
}

.read_links_table <- function(path) {
  if (grepl("\\.csv$", path, ignore.case = TRUE)) {
    d <- as.data.frame(read_csv(path, col_types = cols(.default = "c"), na = c("", "NA"), progress = FALSE))
    if (!"url" %in% names(d)) stop("links.csv needs a 'url' column")
  } else d <- .read_links_txt(path)
  for (cn in setdiff(jw_links_cols, names(d))) d[[cn]] <- NA_character_
  d$enabled <- is.na(d$enabled) | !toupper(trimws(d$enabled)) %in% c("FALSE", "F", "0", "NO")
  d$url <- trimws(d$url)
  d[!is.na(d$url) & nzchar(d$url), jw_links_cols]
}

# Exact duplicates (ignoring fragment and trailing slash) are kept but marked in dup_of.
jw_read_links <- function(path = jw_links_path()) {
  all <- .read_links_table(path)
  d <- all[all$enabled, ]
  if (!nrow(d)) stop("No enabled links in ", path)
  attr_disabled <- sum(!all$enabled)
  d$line <- NA_integer_
  d$n <- seq_len(nrow(d))
  d$key <- jw_key(d$url)
  d$host <- tolower(sub("^https?://([^/:?#]+).*$", "\\1", d$url))
  d$dup_of <- NA_integer_
  first <- match(d$key, d$key)
  d$dup_of[first != d$n] <- first[first != d$n]
  is_search <- grepl("(^|\\.)(google|bing|duckduckgo|startpage)\\.[a-z.]+$", d$host) &
    grepl("/search", d$url)
  is_sitemap <- !is_search & grepl("(\\.xml(\\.gz)?|sitemap[^/]*)([?#].*)?$", d$url, ignore.case = TRUE)
  d$type <- ifelse(is_search, "search_engine", ifelse(is_sitemap, "sitemap", "portal"))
  # "resolver": a stable link that redirects to a changing Google Sheet. Opt in with the word `resolver` in
  # the note; a portal link whose redirect ends on a sheet is also resolved by jw_probe_one without the flag.
  # Tabs are chosen by options(jobwatch.gsheet_tabs = "<regex>"), default "postdoc|faculty|permanent".
  is_res <- !is_search & !is_sitemap & grepl("(^|[;, ])resolver(:|$|[;, ])", d$note %||% "", ignore.case = TRUE)
  d$type[is_res] <- "resolver"
  # "json_eures" / "json_oracle": opt in with `json:eures` or `json:oracle` in the note (see .probe_eures, .probe_oracle).
  js <- tolower(sub(".*(^|[;, ])json:([a-z]+).*", "\\2", ifelse(grepl("(^|[;, ])json:(eures|oracle)", d$note %||% "", ignore.case = TRUE), d$note, "")))
  d$type[!is_search & js %in% c("eures", "oracle")] <- paste0("json_", js[!is_search & js %in% c("eures", "oracle")])
  d$query <- NA_character_
  for (i in which(is_search)) d$query[i] <- jw_search_note(d$url[i])
  d$id <- vapply(d$key, function(k) substr(rlang::hash(k), 1, 8), "")
  out <- d[, c("n", "id", "section", "url", "label", "key", "host", "type", "query", "dup_of")]
  attr(out, "n_disabled") <- attr_disabled
  out
}

# Normalised key for URLs (vectorised): fragment and trailing slash dropped, scheme and host lower-cased; search-engine
# URLs are keyed by query and time filter. Used to match links across the links file, state files and diffs.
jw_key <- function(url) vapply(url, .jw_key1, "", USE.NAMES = FALSE)

.jw_key1 <- function(url) {
  if (grepl("^https?://([^/]*\\.)?(google|bing|duckduckgo|startpage)\\.[a-z.]+/search", url, ignore.case = TRUE)) {
    sp <- jw_search_parts(url)
    return(paste0(tolower(sub("^(https?://[^/]+/search).*$", "\\1", url)), "?q=", sp$q_raw,
                  if (!is.na(sp$recency)) paste0("&tbs=qdr:", sp$recency)))
  }
  u <- sub("#.*$", "", url)
  u <- sub("/+$", "", u)
  sub("^(https?://[^/]+)", "\\L\\1", u, perl = TRUE)
}

# Parts of a search-engine URL that define the search: the query (decoded, operators kept), its raw form and the
# time filter (Google `tbs=qdr:<h|d|w|m|y>[n]` or `as_qdr=`). Session and tracking parameters (sxsrf, ved, gs_lp,
# sca_esv, client, fragment) are ignored, so re-pasting the "same" search gives the same key.
jw_search_parts <- function(url) {
  qs <- sub("^[^?]*\\??", "", sub("#.*$", "", url))
  pars <- strsplit(strsplit(qs, "&", fixed = TRUE)[[1]], "=", fixed = TRUE)
  get <- function(nm) {
    v <- vapply(pars, function(p) if (length(p) >= 2 && identical(p[1], nm)) paste(p[-1], collapse = "=") else NA_character_, "")
    v <- v[!is.na(v)]
    if (length(v)) v[1] else NA_character_
  }
  q_raw <- get("q")
  q <- if (is.na(q_raw)) NA_character_ else utils::URLdecode(gsub("+", " ", q_raw, fixed = TRUE))
  tbs <- get("tbs"); tbs <- if (is.na(tbs)) NA_character_ else utils::URLdecode(tbs)
  rec <- if (!is.na(tbs) && grepl("(^|,)qdr:[hdwmy][0-9]*", tbs)) sub(".*qdr:([hdwmy][0-9]*).*", "\\1", tbs) else get("as_qdr")
  list(query = q, q_raw = q_raw, recency = rec)
}

# Plain-language time filter, e.g. "m" -> "past month", "m3" -> "past 3 months".
jw_recency_label <- function(rec) {
  if (is.na(rec)) return(NA_character_)
  unit <- c(h = "hour", d = "day", w = "week", m = "month", y = "year")[[substr(rec, 1, 1)]]
  n <- suppressWarnings(as.integer(substring(rec, 2)))
  if (is.na(n) || n == 1L) paste("past", unit) else paste("past", n, paste0(unit, "s"))
}

# Note carried by a search_engine source: the full query with operators plus the time filter (read by s1, s4, s5).
jw_search_note <- function(url) {
  sp <- jw_search_parts(url)
  if (is.na(sp$query)) return(NA_character_)
  paste0(sp$query, if (!is.na(sp$recency)) paste0("  [time filter: ", jw_recency_label(sp$recency), "]"))
}

# Domains that, in tests, dominated web_search results for vacancy queries without being useful for this skill:
# US commercial job boards, patent offices and preprint/paper hosts. Extend per user via `extra`.
jw_noise_domains <- c("ziprecruiter.com", "indeed.com", "glassdoor.com", "simplyhired.com", "monster.com",
                      "uspto.gov", "patents.google.com", "biorxiv.org", "arxiv.org", "ncbi.nlm.nih.gov",
                      "researchgate.net", "sciencedirect.com", "springer.com", "nature.com")

# Self-improvement step for a search_engine source. Give the query that was run and the URLs it returned; if too
# large a share comes from noise domains, it returns `rerun = TRUE` and `query_next` with `-site:` terms added for
# the noisy domains (domains already excluded are not repeated). Stops after `max_rounds` reruns, so the loop is
# bounded and `reason` always says why. The caller must report every round to the user.
jw_search_refine <- function(query, result_urls, round = 1L, max_rounds = 2L, threshold = 0.5,
                             extra = character(), noise = c(jw_noise_domains, extra)) {
  host <- tolower(sub("^www\\.", "", sub("^https?://([^/:?#]+).*$", "\\1", result_urls)))
  is_noise <- vapply(host, function(h) any(h == noise | endsWith(h, paste0(".", noise))), NA)
  share <- if (length(host)) mean(is_noise) else NA_real_
  already <- sub("^-site:", "", regmatches(query, gregexpr("-site:[^ )]+", query))[[1]])
  new <- setdiff(unique(vapply(host[is_noise], function(h) { m <- noise[h == noise | endsWith(h, paste0(".", noise))]; m[which.max(nchar(m))] }, "")), already)
  out <- list(round = round, n_results = length(host), noise_share = share, noisy_domains = new,
              rerun = FALSE, query_next = query, reason = "")
  if (!length(host)) { out$reason <- "no results returned"; return(out) }
  if (share < threshold) { out$reason <- sprintf("noise share %.0f%% is below %.0f%%: keep results", 100 * share, 100 * threshold); return(out) }
  if (!length(new)) { out$reason <- "noisy results, but every noisy domain is already excluded: report as weak source"; return(out) }
  if (round > max_rounds) { out$reason <- "max reruns reached: report as weak source and propose a link change"; return(out) }
  out$rerun <- TRUE
  out$query_next <- paste(query, paste0("-site:", new, collapse = " "))
  out$reason <- sprintf("noise share %.0f%%: rerun with %d added exclusions", 100 * share, length(new))
  out
}

.jw_backup <- function(path) {
  bak <- paste0(path, ".bak-", format(Sys.time(), "%Y%m%d-%H%M%S"))
  file.copy(path, bak); bak
}

.write_links_csv <- function(d, path) {
  d$enabled <- ifelse(d$enabled, "TRUE", "FALSE")
  write_csv(d[, jw_links_cols], path, na = "", progress = FALSE)
}

# Add a link row (section is free text; new sections need no setup). `confirmed` must be TRUE: set it
# only after the user said yes to this exact change. Refuses if the link already exists.
jw_add_link <- function(url, section, path = jw_links_path(), confirmed = FALSE, label = NA,
                        note = NA, replaces = NA, added_by = "assistant", enabled = TRUE) {
  if (!isTRUE(confirmed)) stop("Not confirmed by the user: show the proposed change first.")
  stopifnot(grepl("^https?://", url))
  if (!grepl("\\.csv$", path)) stop("Convert links.txt to links.csv first (jw_convert_links_txt).")
  d <- .read_links_table(path)
  if (jw_key(url) %in% jw_key(d$url)) { message("Already present: ", url); return(invisible(NULL)) }
  bak <- .jw_backup(path)
  row <- data.frame(url = url, section = section, label = label, enabled = enabled,
                    added = format(Sys.Date()), added_by = added_by, replaces = replaces, note = note)
  .write_links_csv(rbind(d, row), path)
  message("Added to '", section, "'. Backup: ", bak); invisible(bak)
}

# Retire a dead link and add its replacement in one confirmed step; the old row stays (enabled = FALSE).
jw_replace_link <- function(old_url, new_url, path = jw_links_path(), confirmed = FALSE,
                            note = NA, added_by = "assistant") {
  if (!isTRUE(confirmed)) stop("Not confirmed by the user: show the proposed change first.")
  d <- .read_links_table(path)
  i <- match(jw_key(old_url), jw_key(d$url))
  if (is.na(i)) stop("Old link not found in ", path)
  if (jw_key(new_url) %in% jw_key(d$url)) stop("New link already present")
  bak <- .jw_backup(path)
  d$note[i] <- paste0(ifelse(is.na(d$note[i]), "", paste0(d$note[i], "; ")), "replaced ", format(Sys.Date()))
  d$enabled[i] <- FALSE
  row <- data.frame(url = new_url, section = d$section[i], label = d$label[i], enabled = TRUE,
                    added = format(Sys.Date()), added_by = added_by, replaces = old_url, note = note)
  .write_links_csv(rbind(d, row), path)
  message("Replaced. Backup: ", bak); invisible(bak)
}

# Re-enable or retire one existing link (e.g. undo a replacement). Same protocol as the other editors:
# `confirmed` only after the user said yes, backup first, the row stays in the file.
jw_set_link_enabled <- function(url, enabled, path = jw_links_path(), confirmed = FALSE, note = NA) {
  if (!isTRUE(confirmed)) stop("Not confirmed by the user: show the proposed change first.")
  stopifnot(is.logical(enabled), length(enabled) == 1, !is.na(enabled))
  d <- .read_links_table(path)
  i <- match(jw_key(url), jw_key(d$url))
  if (is.na(i)) stop("Link not found in ", path)
  if (d$enabled[i] == enabled) { message("Already ", if (enabled) "enabled" else "disabled", ": ", url); return(invisible(NULL)) }
  bak <- .jw_backup(path)
  d$enabled[i] <- enabled
  tag <- paste0(if (enabled) "re-enabled " else "retired ", format(Sys.Date()), if (!is.na(note)) paste0(" (", note, ")") else "")
  d$note[i] <- paste0(ifelse(is.na(d$note[i]), "", paste0(d$note[i], "; ")), tag)
  .write_links_csv(d, path)
  message(if (enabled) "Enabled." else "Disabled.", " Backup: ", bak); invisible(bak)
}

# One-time conversion of a legacy links.txt to links.csv (the .txt is left untouched). Needs a yes.
jw_convert_links_txt <- function(txt = jw_path("links.txt"), csv = jw_path("links.csv"), confirmed = FALSE) {
  if (!isTRUE(confirmed)) stop("Not confirmed by the user: show the proposed change first.")
  if (file.exists(csv)) stop(csv, " already exists")
  d <- .read_links_table(txt)
  d$added <- format(file.mtime(txt), "%Y-%m-%d"); d$added_by <- "user"
  .write_links_csv(d, csv)
  message(nrow(d), " links written to ", csv, "; the original ", txt, " is unchanged.")
  invisible(csv)
}

# Replace a whole text file (e.g. the profile) with `new_text`, keeping a timestamped backup.
jw_write_confirmed <- function(path, new_text, confirmed = FALSE) {
  if (!isTRUE(confirmed)) stop("Not confirmed by the user: show a diff first.")
  bak <- .jw_backup(path); writeLines(new_text, path, useBytes = TRUE)
  message("Written. Backup: ", bak); invisible(bak)
}
