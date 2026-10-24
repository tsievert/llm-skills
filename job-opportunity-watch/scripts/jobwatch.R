# jobwatch.R -- helpers for the job-opportunity-watch skill.
# source("<web-fetching-r skill-dir>/scripts/polite_fetch.R") first, then
# source("<skill-dir>/scripts/jobwatch.R"); set options(jobwatch.dir = "<folder>") first.
# Model-free steps only: parse the links file, probe pages politely, diff against what was seen
# before, keep state files, audit coverage, and edit the links file with backup + confirmation.
# The actual HTTP fetch (user agent, per-host rate limiting, retry, bot-wall/JS heuristics) lives
# in the web-fetching-r skill's polite_fetch.R (pf_*); this file only adds job-portal-specific
# anchor extraction and state.
# Needs: httr2, rvest, xml2, readr, yaml (all CRAN).

suppressPackageStartupMessages({
  library(httr2); library(xml2); library(rvest); library(readr)
})

if (!exists("pf_fetch_html", mode = "function")) {
  stop("jobwatch.R needs the web-fetching-r skill's polite_fetch.R sourced first: ",
       'source("<web-fetching-r skill-dir>/scripts/polite_fetch.R")')
}

jw_ua <- pf_user_agent("job-opportunity-watch", "personal research use; low rate")
jw_dir <- function() getOption("jobwatch.dir", Sys.getenv("JOBWATCH_DIR", "job-watch"))
jw_path <- function(...) file.path(jw_dir(), ...)
jw_state <- function(...) file.path(jw_dir(), "state", ...)
jw_now <- function() format(Sys.time(), "%Y-%m-%dT%H:%M:%S")

# Drop invalid bytes that some pages produce when the declared charset is wrong
.clean <- function(x) iconv(x, "UTF-8", "UTF-8", sub = "")
.cnt <- function(tab, nm) if (nm %in% names(tab)) as.integer(tab[[nm]]) else 0L
.na0 <- function(x, y) ifelse(is.na(x), y, x)
.tsv_read <- function(path) {
  if (!file.exists(path)) return(NULL)
  as.data.frame(read_tsv(path, col_types = cols(.default = "c"), na = "NA", quote = "", progress = FALSE))
}
.tsv_write <- function(df, path) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  df[] <- lapply(df, function(x) if (is.character(x)) gsub('[\t\r\n"]', ' ', x) else x)
  write_tsv(df, path, na = "NA", quote = "none", progress = FALSE)
  invisible(path)
}

# ---- 1. links file --------------------------------------------------------------------------
# Format: links.csv (UTF-8) with columns url, section, label, enabled, added, added_by, replaces, note.
# Only `url` is required. `enabled = FALSE` rows are kept for history and are not probed. A legacy
# links.txt (URL lines, "#" comments, plain text lines = section labels) is still read and can be
# converted once with jw_convert_links_txt().
jw_links_cols <- c("url", "section", "label", "enabled", "added", "added_by", "replaces", "note")
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
  d$type <- ifelse(is_search, "search_engine", "portal")
  d$query <- NA_character_
  for (i in which(is_search)) {
    q <- sub(".*[?&]q=([^&]*).*", "\\1", d$url[i])
    d$query[i] <- if (identical(q, d$url[i])) NA else utils::URLdecode(gsub("\\+", " ", q))
  }
  d$id <- vapply(d$key, function(k) substr(rlang::hash(k), 1, 8), "")
  out <- d[, c("n", "id", "section", "url", "label", "key", "host", "type", "query", "dup_of")]
  attr(out, "n_disabled") <- attr_disabled
  out
}

jw_key <- function(url) {
  u <- sub("#.*$", "", url)
  u <- sub("/+$", "", u)
  sub("^(https?://[^/]+)", "\\L\\1", u, perl = TRUE)
}

# ---- 2. probing -----------------------------------------------------------------------------
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

jw_probe_one <- function(url, timeout = 25) {
  t0 <- Sys.time()
  r <- pf_perform(url, jw_ua, timeout = timeout, retry_on = c(429, 502, 503, 504))
  out <- list(status = "error", http = NA_integer_, final_url = NA_character_, bytes = NA_integer_,
              text_chars = NA_integer_, n_scripts = NA_integer_, text_hash = NA_character_,
              note = NA_character_, anchors = NULL)
  if (!is.null(r$error)) { out$note <- substr(conditionMessage(r$error), 1, 150); return(out) }
  resp <- r$response
  out$http <- resp_status(resp); out$final_url <- resp$url
  body <- resp_body_raw(resp); out$bytes <- length(body)
  ctype <- tolower(resp_content_type(resp) %||% "")
  if (out$http >= 400) {
    out$status <- if (out$http %in% c(401, 403, 429)) "blocked" else "http_error"
    return(out)
  }
  if (!grepl("html|xml", ctype)) { out$status <- "non_html"; out$note <- ctype; return(out) }
  doc <- tryCatch(resp_body_html(resp), error = function(e) NULL)
  if (is.null(doc)) { out$note <- "unparseable html"; return(out) }
  out$n_scripts <- length(xml_find_all(doc, "//script"))
  anchors <- xml_find_all(doc, "//a[@href]")
  txt <- .clean(xml_text(anchors)); href <- .clean(xml_attr(anchors, "href"))
  xml_remove(xml_find_all(doc, "//script|//style|//noscript"))
  vis <- gsub("\\s+", " ", .clean(xml_text(doc)))
  out$text_chars <- nchar(vis); out$text_hash <- substr(rlang::hash(vis), 1, 12)
  if (pf_blocked_text(vis) && out$text_chars < 3000) {
    out$status <- "blocked"; out$note <- "bot wall or JS required"; return(out)
  }
  txt <- trimws(gsub("\\s+", " ", txt))
  abs <- tryCatch(url_absolute(href, out$final_url), error = function(e) href)
  ok <- !is.na(txt) & nchar(txt) >= 12 & nchar(txt) <= 250 & !grepl(.nav_re, tolower(txt)) &
    grepl("^https?://", abs) & !grepl("^(mailto|javascript|tel):", href)
  a <- unique(data.frame(text = txt[ok], href = sub("#.*$", "", abs[ok])))
  out$anchors <- a
  thin <- pf_js_suspect(out$text_chars, out$n_scripts, nrow(a))
  out$status <- if (thin) "ok_js_suspect" else "ok"
  if (thin) out$note <- "few usable links or little text: listing probably rendered by JS, use webfetch or search instead"
  out$elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  out
}

# Probe every unique link once (search-engine URLs are not fetched: their query is returned for the
# web_search tool). Polite: one request at a time, >= `delay` s between requests to the same host.
jw_probe <- function(links, delay = 1.5, timeout = 25, profile = NULL, verbose = TRUE) {
  uniq <- links[is.na(links$dup_of), ]
  jw_wait_state <- new.env()  # per-call state, isolated from other skills' pf_wait() calls
  src <- list(); anc <- list()
  for (i in seq_len(nrow(uniq))) {
    r <- uniq[i, ]
    if (r$type == "search_engine") {
      src[[i]] <- data.frame(id = r$id, n = r$n, status = "search_engine", http = NA, final_url = NA,
                             text_hash = NA, n_anchors = 0L, note = r$query)
      next
    }
    pf_wait(r$host, delay, state = jw_wait_state)
    p <- tryCatch(jw_probe_one(r$url, timeout), error = function(e)
      list(status = "error", http = NA, final_url = NA, text_hash = NA, anchors = NULL,
           note = substr(conditionMessage(e), 1, 150)))
    na <- if (is.null(p$anchors)) 0L else nrow(p$anchors)
    src[[i]] <- data.frame(id = r$id, n = r$n, status = p$status, http = p$http, final_url = p$final_url,
                           text_hash = p$text_hash, n_anchors = na, note = p$note)
    if (na) anc[[length(anc) + 1]] <- cbind(source_id = r$id, p$anchors)
    if (verbose) message(sprintf("[%d/%d] %-14s %s", i, nrow(uniq), p$status, substr(r$url, 1, 80)))
  }
  sources <- do.call(rbind, src)
  anchors <- if (length(anc)) do.call(rbind, anc) else
    data.frame(source_id = character(), text = character(), href = character())
  if (nrow(anchors)) anchors <- cbind(anchors, jw_classify_titles(anchors$text, profile))
  list(sources = sources, anchors = anchors, links = links)
}

# ---- 3. state, diff, audit ------------------------------------------------------------------
# Merges a probe into state/: sources.tsv, anchors_seen.tsv, runs.tsv. Returns the review queue
# (anchors not seen before, not excluded, with a role or topic hit; topic hits first).
jw_save_run <- function(run) {
  now <- jw_now()
  # sources
  old <- .tsv_read(jw_state("sources.tsv"))
  s <- merge(run$links[is.na(run$links$dup_of), c("id", "n", "section", "url", "type")],
             run$sources[, c("id", "status", "http", "final_url", "text_hash", "n_anchors", "note")], by = "id")
  s$last_checked <- now
  s$consec_fail <- ifelse(s$status %in% c("ok", "ok_js_suspect", "search_engine", "non_html"), 0L, 1L)
  s$first_seen <- now
  if (!is.null(old)) {
    m <- match(s$id, old$id)
    s$first_seen <- ifelse(is.na(m), now, old$first_seen[m])
    prev_fail <- suppressWarnings(as.integer(old$consec_fail[m])); prev_fail[is.na(prev_fail)] <- 0L
    s$consec_fail <- ifelse(s$consec_fail > 0, prev_fail + 1L, 0L)
    s$changed <- ifelse(is.na(m), NA, !is.na(s$text_hash) & s$text_hash != old$text_hash[m])
  } else s$changed <- NA
  s <- s[order(s$n), ]
  .tsv_write(s, jw_state("sources.tsv"))
  # anchors
  seen <- .tsv_read(jw_state("anchors_seen.tsv"))
  a <- run$anchors
  a$k <- paste(a$source_id, a$href)
  if (!is.null(seen)) {
    seen$k <- paste(seen$source_id, seen$href)
    a$is_new <- !(a$k %in% seen$k)
  } else a$is_new <- TRUE
  new_rows <- a[a$is_new, c("source_id", "text", "href", "role_hit", "topic_hit", "excluded")]
  if (nrow(new_rows)) new_rows$first_seen <- now
  merged <- if (is.null(seen)) new_rows else rbind(seen[, names(new_rows)], new_rows)
  if (nrow(merged)) .tsv_write(merged, jw_state("anchors_seen.tsv"))
  queue <- a[a$is_new & !a$excluded & (a$role_hit | a$topic_hit), ]
  queue$tier <- ifelse(queue$topic_hit, 1L, 2L)  # 1 = topic words in title, 2 = job-like title only
  queue <- queue[order(queue$tier, queue$source_id), c("tier", "source_id", "text", "href")]
  # run log
  au <- jw_audit(run)
  runs <- .tsv_read(jw_state("runs.tsv"))
  row <- data.frame(finished = now, raw_links = au$raw, unique_links = au$unique, duplicates = au$duplicates,
                    checked = au$checked, ok = .cnt(au$by_status, "ok"), js_suspect = .cnt(au$by_status, "ok_js_suspect"),
                    blocked = .cnt(au$by_status, "blocked"), failed = .cnt(au$by_status, "error") + .cnt(au$by_status, "http_error"),
                    search_engine = .cnt(au$by_status, "search_engine"),
                    new_anchors = sum(a$is_new), review_queue = nrow(queue))
  .tsv_write(if (is.null(runs)) row else rbind(runs, row), jw_state("runs.tsv"))
  list(queue = queue, sources = s, audit = au)
}

# Coverage audit: every unique link must have exactly one final status.
jw_audit <- function(run) {
  l <- run$links; u <- l[is.na(l$dup_of), ]
  st <- run$sources
  missing <- setdiff(u$n, st$n)
  multi <- st$n[duplicated(st$n)]
  list(raw = nrow(l), unique = nrow(u), duplicates = nrow(l) - nrow(u), checked = length(unique(st$n)),
       by_status = table(st$status), missing_ledger_numbers = missing, checked_more_than_once = multi,
       complete = length(missing) == 0 && length(multi) == 0 && !anyNA(st$status))
}

# Is a run due? (days since the last finished run in state/runs.tsv)
jw_due <- function(every_days = 7) {
  r <- .tsv_read(jw_state("runs.tsv"))
  if (is.null(r) || !nrow(r)) return(list(due = TRUE, last = NA, days = Inf))
  last <- as.POSIXct(utils::tail(r$finished, 1), format = "%Y-%m-%dT%H:%M:%S")
  d <- as.numeric(difftime(Sys.time(), last, units = "days"))
  list(due = d >= every_days, last = last, days = round(d, 1))
}

# Sources that deserve a human decision: repeated failures, or JS-only pages the probe cannot read.
jw_source_health <- function(min_fail = 3) {
  s <- .tsv_read(jw_state("sources.tsv")); if (is.null(s)) return(NULL)
  s$consec_fail <- as.integer(s$consec_fail)
  s[which(s$consec_fail >= min_fail | s$status %in% c("ok_js_suspect", "blocked")),
    c("n", "url", "status", "consec_fail", "note")]
}

# ---- 4. opportunities ledger (written by the assistant after verification) ------------------
jw_opp_cols <- c("opp_id", "url", "source_ids", "employer", "title", "country", "ref_no", "track",
  "contract", "deadline", "class", "status", "evidence", "first_seen", "last_seen", "notes")
# Upsert rows; match on opp_id. `rows` is a data.frame with any subset of jw_opp_cols.
jw_opp_upsert <- function(rows) {
  now <- jw_now()
  cur <- .tsv_read(jw_state("opportunities.tsv"))
  for (cn in setdiff(jw_opp_cols, names(rows))) rows[[cn]] <- NA_character_
  rows <- rows[, jw_opp_cols]; rows[] <- lapply(rows, as.character)
  rows$last_seen <- now
  if (is.null(cur)) { rows$first_seen <- .na0(rows$first_seen, now); .tsv_write(rows, jw_state("opportunities.tsv")); return(invisible(rows)) }
  for (cn in setdiff(jw_opp_cols, names(cur))) cur[[cn]] <- NA_character_
  for (i in seq_len(nrow(rows))) {
    m <- match(rows$opp_id[i], cur$opp_id)
    if (is.na(m)) { rows$first_seen[i] <- .na0(rows$first_seen[i], now); cur <- rbind(cur[, jw_opp_cols], rows[i, ]) }
    else for (cn in setdiff(jw_opp_cols, "first_seen")) if (!is.na(rows[[cn]][i])) cur[[cn]][m] <- rows[[cn]][i]
  }
  .tsv_write(cur[, jw_opp_cols], jw_state("opportunities.tsv")); invisible(cur)
}

# Mark opportunities whose deadline (ISO date) has passed and status is still open-like.
jw_opp_expire <- function(today = Sys.Date()) {
  o <- .tsv_read(jw_state("opportunities.tsv")); if (is.null(o)) return(invisible(NULL))
  d <- suppressWarnings(as.Date(o$deadline))
  open <- o$status %in% c("Verified open", "Probably open", "Deadline conflict")
  hit <- which(!is.na(d) & d < today & open)
  if (length(hit)) { o$status[hit] <- "Expired"; .tsv_write(o, jw_state("opportunities.tsv")) }
  o[hit, c("opp_id", "title", "employer", "deadline")]
}

# ---- 5. editing the user's links file / profile (only after explicit user confirmation) -------
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

# ---- 6. headless run (no model): probe, save state, write a markdown digest ----------------------
# Suitable for a scheduler (Task Scheduler / cron) via scripts/run_probe.R. Triage and verification
# still need the assistant; the digest lists tier-1 candidates and source problems since the last run.
jw_headless <- function(dir = jw_dir(), delay = 1.5) {
  options(jobwatch.dir = dir)
  links <- jw_read_links()
  prof <- if (file.exists(jw_path("job_profile.yml"))) yaml::read_yaml(jw_path("job_profile.yml")) else NULL
  res <- jw_save_run(jw_probe(links, delay = delay, profile = prof, verbose = FALSE))
  src <- res$sources; au <- res$audit
  q1 <- res$queue[res$queue$tier == 1, ]
  lab <- setNames(src$url, src$id)
  out <- c(sprintf("# Job watch digest %s", format(Sys.time(), "%Y-%m-%d %H:%M")), "",
    sprintf("Links: %d raw, %d unique, %d duplicates, %d checked; complete: %s", au$raw, au$unique,
            au$duplicates, au$checked, au$complete),
    paste("Status:", paste(names(au$by_status), au$by_status, collapse = ", ")),
    sprintf("New tier-1 candidates (topic words in title): %d; tier 2 (job-like title only): %d", nrow(q1),
            sum(res$queue$tier == 2)), "",
    "## Tier-1 candidates", "",
    if (nrow(q1)) sprintf("- %s <%s> (source: %s)", q1$text, q1$href, lab[q1$source_id]) else "None.", "",
    "## Sources needing attention", "")
  h <- jw_source_health(2)
  out <- c(out, if (!is.null(h) && nrow(h)) sprintf("- #%s %s: %s", h$n, h$status, h$url) else "None.")
  dir.create(jw_path("digests"), showWarnings = FALSE)
  f <- jw_path("digests", paste0(format(Sys.Date(), "%Y-%m-%d"), ".md"))
  writeLines(out, f, useBytes = TRUE); invisible(f)
}

# ---- 7. finding a replacement for a dead or moved link (model-free part) --------------------------
# Tries, in order: shorter parent paths on the same host, the site's sitemaps (robots.txt "Sitemap:"
# lines plus common names, one level of sitemap index), and job-like links on the home page and
# parent pages. Returns scored candidates that each respond with HTTP < 400. Candidates are only
# suggestions: verify them and propose them to the user (jw_add_link needs confirmation).
.job_url_re <- paste0("vacanc|career|jobs?([/_.-]|$)|position|opening|stellen|ledig|jobb|tyopaik|ty%C3%B6paik|",
  "avoimet|emploi|offre|vacature|werken|work-?(with|at)|join|rekryt|rekrut|recruit|karriere|hiring|tjanst|tj%C3%A4nst")
.tokens <- function(u) {
  p <- tolower(sub("^https?://[^/]+", "", utils::URLdecode(sub("[?#].*$", "", u))))
  t <- unlist(strsplit(p, "[^a-z0-9]+")); unique(t[nchar(t) >= 3 & !t %in% c("www", "html", "htm", "php", "aspx")])
}
.get_text <- function(url, timeout = 20, max_bytes = 6e6) {
  resp <- pf_perform(url, jw_ua, timeout = timeout, max_tries = 1)$response
  if (is.null(resp) || resp_status(resp) >= 400) return(NULL)
  b <- resp_body_raw(resp); if (length(b) > max_bytes) return(NULL)
  if (length(b) > 2 && b[1] == as.raw(0x1f) && b[2] == as.raw(0x8b)) b <- tryCatch(memDecompress(b, "gzip", asChar = FALSE), error = function(e) raw())
  .clean(rawToChar(b))
}
.sitemap_locs <- function(url, depth = 0, budget = new.env()) {
  if (is.null(budget$n)) budget$n <- 0
  if (budget$n >= 8) return(character())
  budget$n <- budget$n + 1
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
jw_find_replacement <- function(url, max_candidates = 8, verbose = TRUE) {
  root <- sub("^(https?://[^/]+).*$", "\\1", url)
  old <- .tokens(url); cand <- list()
  add <- function(u, via) if (length(u)) cand[[length(cand) + 1]] <<- data.frame(url = u, via = via)
  # 1. parent paths
  segs <- strsplit(sub("^https?://[^/]+/?", "", sub("[?#].*$", "", url)), "/")[[1]]
  segs <- segs[nzchar(segs)]
  if (length(segs) > 1) add(vapply(rev(seq_len(length(segs) - 1)), function(k) paste0(root, "/", paste(segs[1:k], collapse = "/"), "/"), ""), "parent")
  add(paste0(root, "/"), "home")
  # 2. sitemaps
  rb <- .get_text(paste0(root, "/robots.txt"))
  sm <- if (!is.null(rb)) trimws(sub("(?i)^sitemap:", "", grep("(?i)^sitemap:", strsplit(rb, "\r?\n")[[1]], value = TRUE, perl = TRUE), perl = TRUE)) else character()
  sm <- unique(c(sm, paste0(root, c("/sitemap.xml", "/sitemap_index.xml", "/sitemap.xml.gz"))))
  locs <- unique(unlist(lapply(sm[seq_len(min(length(sm), 4))], .sitemap_locs)))
  if (verbose) message("sitemap URLs read: ", length(locs))
  locs <- locs[grepl(.job_url_re, tolower(locs))]
  add(utils::head(locs, 400), "sitemap")
  # 3. job-like links on home page
  for (pg in unique(c(paste0(root, "/"), if (length(segs) > 1) paste0(root, "/", segs[1], "/")))) {
    p <- tryCatch(jw_probe_one(pg), error = function(e) NULL)
    if (!is.null(p$anchors) && nrow(p$anchors)) {
      a <- p$anchors[grepl(.job_url_re, tolower(paste(p$anchors$text, p$anchors$href))), ]
      add(a$href, "homepage-link")
    }
  }
  if (!length(cand)) return(data.frame())
  d <- do.call(rbind, cand); d <- d[!duplicated(jw_key(d$url)) & jw_key(d$url) != jw_key(url), ]
  d$score <- vapply(d$url, function(u) length(intersect(old, .tokens(u))) + 2 * grepl(.job_url_re, tolower(u)) +
                      (if (u == paste0(root, "/")) -3 else 0) +
                      # deep pages are usually single vacancies, not the listing
                      -0.3 * length(strsplit(sub("^https?://[^/]+/?", "", sub("[?#].*$", "", u)), "/")[[1]]), 0)
  d <- d[order(-d$score), ]
  d <- utils::head(d, max_candidates * 2)
  # keep only candidates that answer; record the final URL
  ok <- lapply(seq_len(nrow(d)), function(i) {
    r <- pf_perform(d$url[i], jw_ua, timeout = 15, max_tries = 1)$response
    if (is.null(r)) NULL else data.frame(d[i, ], http = resp_status(r), final_url = r$url)
  })
  out <- do.call(rbind, ok); if (is.null(out)) return(data.frame())
  out <- out[out$http < 400, ]; utils::head(out, max_candidates)
}

# ---- Social-search tag ledger (state/social_tags.tsv) ---------------------------------------------
# One row per (platform, tag). Columns: platform, tag, first_used, last_used, n_runs, n_hits, n_useful,
# last_useful, status (candidate / keep / retired), note. "Useful" = led to a verified opportunity or a
# new link the user accepted; the assistant counts it, the user may overrule status.
.jw_tag_cols <- c("platform", "tag", "first_used", "last_used", "n_runs", "n_hits", "n_useful",
                  "last_useful", "status", "note")
jw_tags_read <- function() {
  x <- .tsv_read(jw_state("social_tags.tsv"))
  if (is.null(x)) x <- as.data.frame(setNames(rep(list(character()), length(.jw_tag_cols)), .jw_tag_cols))
  for (cn in c("n_runs", "n_hits", "n_useful")) x[[cn]] <- as.integer(x[[cn]])
  x
}
# Record one search: hits = posts returned and screened as job-relevant; useful = how many led to
# something verified. Creates the row if the tag is new (status "candidate").
jw_tags_record <- function(platform, tag, hits = 0L, useful = 0L, note = NA_character_) {
  stopifnot(platform %in% c("bluesky", "mastodon"))
  tag <- sub("^#", "", tag)
  x <- jw_tags_read(); now <- jw_now()
  i <- which(x$platform == platform & tolower(x$tag) == tolower(tag))
  if (!length(i)) {
    x[nrow(x) + 1, ] <- list(platform, tag, now, now, 0L, 0L, 0L, NA, "candidate", note)
    i <- nrow(x)
  }
  x$last_used[i] <- now; x$n_runs[i] <- x$n_runs[i] + 1L
  x$n_hits[i] <- x$n_hits[i] + as.integer(hits); x$n_useful[i] <- x$n_useful[i] + as.integer(useful)
  if (useful > 0) x$last_useful[i] <- now
  if (!is.na(note)) x$note[i] <- note
  .tsv_write(x[, .jw_tag_cols], jw_state("social_tags.tsv")); invisible(x)
}
# Suggest status changes; never applies them. Keep: >= 1 useful hit. Retire candidates: >= min_runs runs, none useful.
jw_tags_review <- function(min_runs = 4) {
  x <- jw_tags_read()
  x$suggestion <- ifelse(x$status == "retired", NA,
    ifelse(x$n_useful >= 1 & x$status != "keep", "keep",
    ifelse(x$n_useful == 0 & x$n_runs >= min_runs, "retire", NA)))
  x[!is.na(x$suggestion), ]
}
# Change a status (keep / retire / candidate) after the user agrees; backs up first.
jw_tags_set_status <- function(platform, tag, status, confirmed = FALSE) {
  if (!confirmed) stop("Show the proposed change to the user and call again with confirmed = TRUE.")
  stopifnot(status %in% c("keep", "retired", "candidate"))
  p <- jw_state("social_tags.tsv"); .jw_backup(p)
  x <- jw_tags_read(); i <- which(x$platform == platform & tolower(x$tag) == tolower(sub("^#", "", tag)))
  if (!length(i)) stop("tag not in ledger")
  x$status[i] <- status; .tsv_write(x[, .jw_tag_cols], p); invisible(x)
}
