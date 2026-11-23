# jw_state.R -- state files, diff and audit, the opportunities ledger, and the headless (no-model) run.
# Loaded by jobwatch.R.

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
  } else a$is_new <- rep(TRUE, nrow(a))  # data.frame$<- doesn't recycle a scalar into 0 rows
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
