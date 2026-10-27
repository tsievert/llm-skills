# jw_pipeline.R -- run folders, stage manifests, locking, atomic parquet writes, validation, status,
# problems log and lesson hand-off for the staged weekly job-watch pipeline.
# source() jw_contracts.R first (this file does it if the working copy is intact). Needs: arrow,
# validate, jsonlite (CRAN). No network access here; fetching lives in jobwatch.R / web-fetching-r.
#
# Layout (one folder per ISO week; everything is written and read through these functions):
#   <data>/runs/<YYYY-Www>/  _stage.json  .lock  inputs/  s1_sources.parquet ... s4_parts/  problems.parquet
#                            report.html  summary.md
#   <data>/opportunities.parquet   cross-week ledger (upserted when S4 closes)

suppressPackageStartupMessages({ library(arrow); library(jsonlite) })
if (!exists("jw_contracts", mode = "function"))
  stop("source jw_contracts.R before jw_pipeline.R (jw_load() in jw_report.R does both)", call. = FALSE)

# mmap = FALSE: on Windows a memory-mapped parquet file cannot be overwritten or renamed while mapped
.read_pq <- function(f, as_data_frame = TRUE) arrow::read_parquet(f, as_data_frame = as_data_frame, mmap = FALSE)
jw_root <- function() getOption("jobwatch.dir", Sys.getenv("JOBWATCH_DIR", "job-watch"))
jw_week_id <- function(date = Sys.Date()) format(as.Date(date), "%G-W%V")
jw_week_start <- function(week) { # Monday of an ISO week id
  y <- as.integer(substr(week, 1, 4)); w <- as.integer(substr(week, 7, 8))
  jan4 <- as.Date(sprintf("%d-01-04", y))
  monday1 <- jan4 - ((as.integer(format(jan4, "%u")) - 1L))
  monday1 + 7L * (w - 1L)
}
jw_run_dir <- function(week = jw_week_id(), root = jw_root()) file.path(root, "runs", week)

# ---- stage table: the single source of truth for order and responsibility ------------------------
jw_stages <- data.frame(
  stage = c("s0", "s1", "s2", "s3", "s4", "s5", "s6"),
  name = c("preflight", "probe sources", "diff and prefilter", "deadline check", "shortlist and classify",
           "social and web discovery", "report"),
  who = c("headless", "headless", "headless", "headless", "assistant", "assistant", "headless"),
  needs = c("", "s0", "s1", "s2", "s3", "s4", "s4"),
  output = c("", "s1_sources.parquet", "s2_queue.parquet", "s3_deadlines.parquet", "s4_classified.parquet",
             "s5_discovery.parquet", "summary.md"),
  optional = c(FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE),
  reference = c("references/pipeline.md", "references/pipeline.md", "references/pipeline.md",
                "references/pipeline.md", "references/stage-s4-classify.md", "references/stage-s5-discover.md",
                "references/pipeline.md"),
  stringsAsFactors = FALSE)

# ---- small utilities ---------------------------------------------------------------------------
.now <- function() format(Sys.time(), "%Y-%m-%dT%H:%M:%S")
.md5 <- function(path) if (file.exists(path)) unname(tools::md5sum(path)) else NA_character_
jw_scrub <- function(x) { # keep problem text generic: no URLs, paths or e-mail addresses
  x <- gsub("https?://[^[:space:]\"'<>]+", "<url>", x)
  x <- gsub("[A-Za-z]:[\\\\/][^[:space:]\"'<>]*", "<path>", x)
  x <- gsub("/(home|Users|scratch|work)/[^[:space:]\"'<>]*", "<path>", x)
  gsub("[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}", "<email>", x)
}

# Atomic parquet write: schema-coerced, written to a temp name, read back, then renamed.
jw_write_parquet <- function(df, path, sch) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  tab <- arrow_table(jw_coerce(df, sch), schema = sch)
  tmp <- paste0(path, ".tmp-", Sys.getpid())
  on.exit(unlink(tmp), add = TRUE)
  write_parquet(tab, tmp)
  chk <- .read_pq(tmp, as_data_frame = FALSE)
  if (!chk$schema$Equals(sch) || nrow(chk) != nrow(df)) stop("written file did not read back as written", call. = FALSE)
  if (!file.rename(tmp, path)) { file.copy(tmp, path, overwrite = TRUE); }
  invisible(path)
}

# ---- manifest ------------------------------------------------------------------------------------
jw_manifest_path <- function(run_dir) file.path(run_dir, "_stage.json")
jw_manifest_read <- function(run_dir) {
  p <- jw_manifest_path(run_dir)
  if (!file.exists(p)) return(list(week = basename(run_dir), created = .now(), stages = list()))
  fromJSON(p, simplifyVector = FALSE)
}
jw_manifest_write <- function(run_dir, m) {
  dir.create(run_dir, showWarnings = FALSE, recursive = TRUE)
  tmp <- paste0(jw_manifest_path(run_dir), ".tmp-", Sys.getpid())
  writeLines(toJSON(m, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null"), tmp, useBytes = TRUE)
  file.rename(tmp, jw_manifest_path(run_dir)) || file.copy(tmp, jw_manifest_path(run_dir), overwrite = TRUE)
  unlink(tmp); invisible(m)
}
jw_manifest_update <- function(run_dir, stage, ...) {
  m <- jw_manifest_read(run_dir)
  cur <- m$stages[[stage]]; if (is.null(cur)) cur <- list()
  new <- list(...)
  for (k in names(new)) cur[[k]] <- new[[k]]
  m$stages[[stage]] <- cur
  jw_manifest_write(run_dir, m)
}
.stage_status <- function(m, stage) { s <- m$stages[[stage]]$status; if (is.null(s)) "pending" else s }

# ---- lock (stops a scheduled run and a conversation from writing the same week at once) -----------
jw_lock_path <- function(run_dir) file.path(run_dir, ".lock")
jw_lock_acquire <- function(run_dir, stage, stale_hours = 6) {
  p <- jw_lock_path(run_dir); dir.create(run_dir, showWarnings = FALSE, recursive = TRUE)
  if (file.exists(p)) {
    l <- tryCatch(fromJSON(p), error = function(e) NULL)
    age <- if (is.null(l)) Inf else as.numeric(difftime(Sys.time(), as.POSIXct(l$time, format = "%Y-%m-%dT%H:%M:%S"), units = "hours"))
    if (is.finite(age) && age < stale_hours)
      stop(sprintf("week is locked by stage %s since %s (%.1f h ago). If that run is dead, wait for the %d h timeout or call jw_lock_break(confirmed = TRUE).",
                   l$stage, l$time, age, stale_hours), call. = FALSE)
  }
  writeLines(toJSON(list(stage = stage, time = .now(), pid = Sys.getpid(), host = Sys.info()[["nodename"]]), auto_unbox = TRUE), p)
  invisible(TRUE)
}
jw_lock_release <- function(run_dir) { unlink(jw_lock_path(run_dir)); invisible(TRUE) }
jw_lock_break <- function(week = jw_week_id(), root = jw_root(), confirmed = FALSE) {
  if (!confirmed) stop("confirm with the user, then call again with confirmed = TRUE", call. = FALSE)
  jw_lock_release(jw_run_dir(week, root))
}

# ---- problems log (generic wording only; read by the assistant stages for lessons) -----------------
jw_problem_cols <- schema(ts = string(), week = string(), stage = string(), code = string(),
                          severity = string(), message = string(), n = int32(), reported = boolean())
jw_problem <- function(stage, code, message, severity = c("warn", "error", "info"), n = 1L,
                       week = jw_week_id(), root = jw_root()) {
  severity <- match.arg(severity)
  add <- data.frame(ts = .now(), week = week, stage = stage, code = code, severity = severity,
                    message = jw_scrub(message), n = as.integer(n), reported = FALSE)
  jw_problems_append(add, week, root)
}
jw_problems_append <- function(add, week, root) {
  p <- file.path(jw_run_dir(week, root), "problems.parquet")
  cur <- if (file.exists(p)) as.data.frame(.read_pq(p)) else NULL
  jw_write_parquet(rbind(cur, add), p, jw_problem_cols)
}
jw_problems_read <- function(week = jw_week_id(), root = jw_root()) {
  p <- file.path(jw_run_dir(week, root), "problems.parquet")
  if (file.exists(p)) as.data.frame(.read_pq(p)) else as.data.frame(jw_coerce(data.frame()[0, ], jw_problem_cols))
}

# ---- stage files ---------------------------------------------------------------------------------
jw_stage_file <- function(stage, week = jw_week_id(), root = jw_root()) {
  f <- jw_contracts()[[stage]]$file
  if (is.null(f)) stop("stage '", stage, "' has no parquet output", call. = FALSE)
  file.path(jw_run_dir(week, root), f)
}
jw_read_stage <- function(stage, week = jw_week_id(), root = jw_root()) as.data.frame(.read_pq(jw_stage_file(stage, week, root)))
jw_write_stage <- function(df, stage, week = jw_week_id(), root = jw_root()) {
  jw_write_parquet(df, jw_stage_file(stage, week, root), jw_contracts()[[stage]]$schema)
}

# Validate one stage output: file exists, schema equals the contract, row rules (validate), completeness
# gate against the previous stage. Returns a data frame of problems; zero rows = valid.
jw_validate_stage <- function(stage, week = jw_week_id(), root = jw_root(), today = Sys.Date()) {
  ct <- jw_contracts(today)[[stage]]; f <- jw_stage_file(stage, week, root)
  out <- .none()
  if (!file.exists(f)) return(.gp(paste0(stage, "_missing"), "output file does not exist", 1L))
  tab <- .read_pq(f, as_data_frame = FALSE)
  if (!tab$schema$Equals(ct$schema))
    return(.gp(paste0(stage, "_schema"), "file schema differs from the contract", 1L))
  df <- as.data.frame(tab)
  if (nrow(df) == 0 && !stage %in% c("s2", "s4", "s5"))
    out <- rbind(out, .gp(paste0(stage, "_empty"), "output has no rows", 1L, "warn"))
  if (nrow(df) > 0) {
    cf <- validate::confront(df, jw_make_validator(ct$rules))
    sm <- validate::summary(cf)
    bad <- sm$fails + sm$nNA
    for (i in which(bad > 0))
      out <- rbind(out, .gp(sm$name[i], sprintf("rule %s failed for %d row(s)", sm$name[i], bad[i]), bad[i]))
  }
  m <- jw_manifest_read(jw_run_dir(week, root))
  gate <- switch(stage,
    s1 = jw_gate_s1(df, m$stages$s1$expected_n),
    s3 = jw_gate_s3(df, jw_read_stage("s2", week, root)),
    s4 = jw_gate_s4(df, jw_read_stage("s3", week, root)),
    .none())
  rbind(out, gate)
}

# ---- stage life cycle ----------------------------------------------------------------------------
.deps_ok <- function(stage, m) {
  need <- strsplit(jw_stages$needs[jw_stages$stage == stage], ",")[[1]]
  need <- need[nzchar(need)]
  all(vapply(need, function(n) .stage_status(m, n) %in% c("done", "skipped"), logical(1)))
}

# Start a stage: refuse when dependencies are not done, take the lock, mark running.
jw_stage_begin <- function(stage, week = jw_week_id(), root = jw_root(), expected_n = NULL, stale_hours = 6) {
  rd <- jw_run_dir(week, root); m <- jw_manifest_read(rd)
  if (!.deps_ok(stage, m))
    stop("stage ", stage, " needs ", jw_stages$needs[jw_stages$stage == stage], " to be done first (see jw_status())", call. = FALSE)
  jw_lock_acquire(rd, stage, stale_hours)
  args <- list(rd, stage, status = "running", started = .now())
  if (!is.null(expected_n)) args$expected_n <- as.integer(expected_n)
  do.call(jw_manifest_update, args)
  invisible(rd)
}

# Close a stage: validate, then mark done (and update the ledger after s4) or failed. Always releases the lock.
jw_stage_close <- function(stage, week = jw_week_id(), root = jw_root(), today = Sys.Date(), note = NULL) {
  rd <- jw_run_dir(week, root); on.exit(jw_lock_release(rd), add = TRUE)
  if (stage == "s4") jw_parts_merge("s4", week, root)
  v <- jw_validate_stage(stage, week, root, today)
  for (i in seq_len(nrow(v))) jw_problem(stage, v$code[i], v$message[i], if (v$severity[i] == "error") "error" else "warn", v$n[i], week, root)
  failed <- any(v$severity == "error")
  n <- if (file.exists(jw_stage_file(stage, week, root))) nrow(jw_read_stage(stage, week, root)) else NA_integer_
  jw_manifest_update(rd, stage, status = if (failed) "failed" else "done", finished = .now(), n_rows = n,
                     md5 = .md5(jw_stage_file(stage, week, root)), n_problems = nrow(v), note = note)
  if (!failed && stage == "s4") jw_ledger_upsert(week, root)
  invisible(v)
}

# Headless wrapper: begin, run fn() (returns the stage data frame), write, close; failures are recorded.
jw_stage_run <- function(stage, fn, week = jw_week_id(), root = jw_root(), expected_n = NULL) {
  jw_stage_begin(stage, week, root, expected_n)
  rd <- jw_run_dir(week, root)
  res <- tryCatch({ jw_write_stage(fn(), stage, week, root); NULL }, error = function(e) e)
  if (!is.null(res)) {
    jw_problem(stage, paste0(stage, "_error"), conditionMessage(res), "error", 1L, week, root)
    jw_manifest_update(rd, stage, status = "failed", finished = .now())
    jw_lock_release(rd); stop(res)
  }
  invisible(jw_stage_close(stage, week, root))
}

jw_stage_skip <- function(stage, reason, week = jw_week_id(), root = jw_root()) {
  if (!jw_stages$optional[jw_stages$stage == stage]) stop("stage ", stage, " is not optional", call. = FALSE)
  jw_manifest_update(jw_run_dir(week, root), stage, status = "skipped", finished = .now(), note = jw_scrub(reason))
}

# ---- resumable assistant stages: parts, pending ids, merge -----------------------------------------
# The assistant writes batches (jw_part_write) and can stop at any time; jw_pending() says what is left.
jw_part_dir <- function(stage, week, root) file.path(jw_run_dir(week, root), paste0(stage, "_parts"))
jw_part_write <- function(df, stage, week = jw_week_id(), root = jw_root()) {
  d <- jw_part_dir(stage, week, root)
  n <- length(list.files(d, pattern = "\\.parquet$")) + 1L
  jw_write_parquet(df, file.path(d, sprintf("part-%03d.parquet", n)), jw_contracts()[[stage]]$schema)
}
jw_parts_read <- function(stage, week = jw_week_id(), root = jw_root()) {
  fs <- list.files(jw_part_dir(stage, week, root), pattern = "\\.parquet$", full.names = TRUE)
  if (!length(fs)) return(as.data.frame(jw_coerce(data.frame()[0, ], jw_contracts()[[stage]]$schema)))
  do.call(rbind, lapply(fs, function(f) as.data.frame(.read_pq(f))))
}
jw_parts_merge <- function(stage, week = jw_week_id(), root = jw_root()) {
  d <- jw_parts_read(stage, week, root)
  if (nrow(d)) jw_write_stage(d, stage, week, root)
  invisible(nrow(d))
}
# Ids still to decide in S4 (candidates = S3 rows that are not expired, minus ids already in parts).
jw_pending <- function(stage = "s4", week = jw_week_id(), root = jw_root(), n = Inf) {
  stopifnot(stage == "s4")
  cand <- jw_read_stage("s3", week, root); s2 <- jw_read_stage("s2", week, root)
  cand <- merge(cand[cand$verdict != "expired", c("item_id", "verdict", "deadline")], s2[, c("item_id", "text", "href", "tier")], by = "item_id")
  cand <- cand[!cand$item_id %in% jw_parts_read(stage, week, root)$item_id, ]
  cand <- cand[order(cand$tier, cand$item_id), ]
  head(cand, n)
}

# ---- cross-week ledger -----------------------------------------------------------------------------
jw_ledger_path <- function(root = jw_root()) file.path(root, "opportunities.parquet")
jw_ledger_read <- function(root = jw_root()) {
  p <- jw_ledger_path(root)
  if (file.exists(p)) as.data.frame(.read_pq(p)) else as.data.frame(jw_coerce(data.frame()[0, ], jw_contracts()$ledger$schema))
}
jw_ledger_upsert <- function(week = jw_week_id(), root = jw_root()) {
  s4 <- jw_read_stage("s4", week, root); s4 <- s4[s4$decision == "classified", ]
  cur <- jw_ledger_read(root); keep <- c("opp_id", "employer", "title", "country", "track", "contract", "deadline", "class", "status", "notes")
  for (i in seq_len(nrow(s4))) {
    new <- s4[i, keep]; new$url <- s4$evidence_url[i]; new$last_week <- week
    m <- match(new$opp_id, cur$opp_id)
    if (is.na(m)) { new$first_week <- week; cur <- rbind(cur, new[, names(cur)]) }
    else for (cn in setdiff(names(new), "opp_id")) if (!is.na(new[[cn]])) cur[[cn]][m] <- new[[cn]]
  }
  jw_write_parquet(cur, jw_ledger_path(root), jw_contracts()$ledger$schema)
  invisible(cur)
}

# ---- status: what runs next ------------------------------------------------------------------------
jw_status <- function(week = jw_week_id(), root = jw_root(), quiet = FALSE) {
  rd <- jw_run_dir(week, root); m <- jw_manifest_read(rd)
  st <- vapply(jw_stages$stage, function(s) .stage_status(m, s), "")
  ready <- vapply(jw_stages$stage, function(s) st[[s]] %in% c("pending", "failed") && .deps_ok(s, m), logical(1))
  tab <- data.frame(stage = jw_stages$stage, name = jw_stages$name, who = jw_stages$who, status = unname(st),
                    ready = ready, rows = vapply(jw_stages$stage, function(s) { r <- m$stages[[s]]$n_rows; if (is.null(r)) NA_integer_ else as.integer(r) }, 1L),
                    stringsAsFactors = FALSE, row.names = NULL)
  nxt <- jw_stages$stage[ready & !jw_stages$optional]
  nxt <- if (length(nxt)) nxt[1] else NA_character_
  locked <- file.exists(jw_lock_path(rd))
  if (!quiet) {
    cat("Week", week, if (locked) "(LOCKED)" else "", "\n"); print(tab, row.names = FALSE)
    if (is.na(nxt)) cat("Next: nothing required.\n") else {
      w <- jw_stages$who[jw_stages$stage == nxt]
      cat("Next:", nxt, "-", jw_stages$name[jw_stages$stage == nxt], if (w == "assistant") "(assistant stage: start a NEW conversation, read" else "(headless; read",
          jw_stages$reference[jw_stages$stage == nxt], ")\n")
    }
    if (any(ready & jw_stages$optional)) cat("Optional and ready:", paste(jw_stages$stage[ready & jw_stages$optional], collapse = ", "), "\n")
  }
  invisible(list(table = tab, next_stage = nxt, locked = locked))
}

# ---- lessons hand-off (skill-lessons) --------------------------------------------------------------
# Headless stages cannot write lessons (no assistant). Assistant stages call these at start and end.
jw_lessons_candidates <- function(week = jw_week_id(), root = jw_root()) {
  p <- jw_problems_read(week, root); p <- p[!p$reported & p$severity %in% c("warn", "error"), ]
  if (!nrow(p)) return(invisible(p))
  g <- aggregate(cbind(n = n) ~ code + stage + severity + message, data = p, FUN = sum)
  for (i in seq_len(nrow(g))) cat(sprintf(
    'lesson_add(skill = "job-opportunity-watch", type = "%s", title = "%s (stage %s)",\n  symptom = "%s", context = "weekly staged pipeline, stage %s", resolution = "<what you did>",\n  evidence = "code %s, %d occurrence(s)", suggested_change = "<one sentence>", generality = "unsure")\n',
    if (g$severity[i] == "error") "bug" else "missing-guidance", g$code[i], g$stage[i], g$message[i], g$stage[i], g$code[i], g$n[i]))
  invisible(g)
}
jw_lessons_mark_reported <- function(week = jw_week_id(), root = jw_root(), codes = NULL) {
  p <- jw_problems_read(week, root)
  p$reported[is.null(codes) | p$code %in% codes] <- TRUE
  jw_write_parquet(p, file.path(jw_run_dir(week, root), "problems.parquet"), jw_problem_cols)
}
# Pre-filled arguments for usecase_add() at the end of an assistant stage conversation.
jw_usecase_args <- function(stage, week = jw_week_id(), root = jw_root()) {
  m <- jw_manifest_read(jw_run_dir(week, root)); s <- m$stages[[stage]]; p <- jw_problems_read(week, root); p <- p[p$stage == stage, ]
  list(skills = c("job-opportunity-watch", if (stage == "s5") "social-research-search"),
       summary = sprintf("Weekly staged job-watch pipeline, stage %s (%s): %s rows produced.", stage, jw_stages$name[jw_stages$stage == stage], if (is.null(s$n_rows)) "?" else s$n_rows),
       outcome = switch(if (is.null(s$status)) "pending" else s$status, done = if (nrow(p)) "worked-with-workaround" else "worked", failed = "failed", "partly-worked"),
       friction = if (nrow(p)) paste(sprintf("%s x%d", p$code, p$n), collapse = "; ") else "none")
}

# ---- inputs frozen per week ------------------------------------------------------------------------
jw_freeze_inputs <- function(week = jw_week_id(), root = jw_root()) {
  rd <- jw_run_dir(week, root); id <- file.path(rd, "inputs"); dir.create(id, showWarnings = FALSE, recursive = TRUE)
  m <- jw_manifest_read(rd)
  for (f in c("links.csv", "job_profile.yml")) {
    src <- file.path(root, f); dst <- file.path(id, f)
    if (!file.exists(src)) { jw_problem("s0", paste0("missing_", sub("\\..*", "", f)), paste(f, "not found in the data folder"), "error", 1L, week, root); next }
    if (!file.exists(dst)) { file.copy(src, dst); m$inputs[[f]] <- .md5(dst) }
    else if (!identical(.md5(src), .md5(dst)))
      jw_problem("s0", paste0("changed_mid_week_", sub("\\..*", "", f)), paste(f, "changed after the week was started; this week keeps using the frozen copy"), "warn", 1L, week, root)
  }
  jw_manifest_write(rd, m); invisible(m$inputs)
}
