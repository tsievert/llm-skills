# jw_report.R -- S0 preflight and S6 report (summary.md + Quarto dashboard) for the staged pipeline.
# Load everything with: source("<skill-dir>/scripts/pipeline/jw_report.R"); jw_load()
# Needs: arrow, validate, jsonlite, quarto (R package + Quarto CLI), reactable, yaml.

jw_script_dir <- function() getOption("jobwatch.script_dir", file.path("job-opportunity-watch", "scripts", "pipeline"))
jw_load <- function(dir = jw_script_dir()) {
  source(file.path(dir, "jw_contracts.R")); source(file.path(dir, "jw_pipeline.R")); invisible(TRUE)
}

# ---- S0 preflight ---------------------------------------------------------------------------------
# Cheap checks before anything touches the network. Returns the problems it recorded.
jw_preflight <- function(week = jw_week_id(), root = jw_root(), run_tests = TRUE, tests_dir = NULL) {
  stage <- "s0"; rd <- jw_run_dir(week, root); dir.create(rd, showWarnings = FALSE, recursive = TRUE)
  jw_stage_begin(stage, week, root)
  on.exit(jw_lock_release(rd), add = TRUE)
  prob <- function(code, msg, sev = "error") jw_problem(stage, code, msg, sev, 1L, week, root)

  need <- c("arrow", "validate", "jsonlite", "yaml", "httr2", "xml2", "rvest", "reactable", "quarto", "targets")
  miss <- need[!vapply(need, requireNamespace, logical(1), quietly = TRUE)]
  if (length(miss)) prob("pkg_missing", paste("missing packages:", paste(miss, collapse = ", ")))
  qv <- tryCatch(as.character(quarto::quarto_version()), error = function(e) NA_character_)
  if (is.na(qv)) prob("quarto_cli_missing", "Quarto CLI not found; the report stage cannot render")

  # contracts: every rule compiles (none silently dropped) and every schema round-trips (empty file)
  for (s in names(jw_contracts())) {
    r <- tryCatch({ jw_make_validator(jw_contracts()[[s]]$rules); NULL }, error = function(e) conditionMessage(e))
    if (!is.null(r)) prob(paste0("contract_rules_", s), r)
    f <- file.path(rd, "_selftest.parquet")
    r <- tryCatch({ jw_write_parquet(data.frame()[0, ], f, jw_contracts()[[s]]$schema); NULL }, error = function(e) conditionMessage(e))
    unlink(f)
    if (!is.null(r)) prob(paste0("contract_roundtrip_", s), r)
  }

  # data folder is writable; profile is complete YAML
  tf <- file.path(root, ".write-test"); ok <- tryCatch({ writeLines("x", tf); unlink(tf); TRUE }, error = function(e) FALSE, warning = function(w) FALSE)
  if (!ok) prob("data_dir_not_writable", "data folder is not writable from this R session")
  pf <- file.path(root, "job_profile.yml")
  if (!file.exists(pf)) prob("profile_missing", "job_profile.yml not found")
  else {
    raw <- readBin(pf, "raw", file.size(pf))
    if (length(raw) && raw[length(raw)] != as.raw(10)) prob("profile_no_final_newline", "profile does not end with a newline; it may be truncated", "warn")
    y <- tryCatch(suppressWarnings(yaml::read_yaml(pf)), error = function(e) NULL)
    if (is.null(y) || is.null(y$career_search_profile)) prob("profile_unparseable", "profile is not valid YAML or lacks career_search_profile")
  }
  if (!file.exists(file.path(root, "links.csv"))) prob("links_missing", "links.csv not found (convert links.txt first)")

  if (run_tests && !is.null(tests_dir) && dir.exists(tests_dir) && requireNamespace("testthat", quietly = TRUE)) {
    Sys.setenv(JW_PREFLIGHT = "1"); on.exit(Sys.unsetenv("JW_PREFLIGHT"), add = TRUE)  # lets slow tests skip themselves
    res <- as.data.frame(testthat::test_dir(tests_dir, reporter = "silent", stop_on_failure = FALSE))
    if (any(res$failed > 0 | res$error)) prob("unit_tests_failed", sprintf("%d unit test(s) failed", sum(res$failed > 0 | res$error)))
  }
  jw_freeze_inputs(week, root)
  p <- jw_problems_read(week, root); p <- p[p$stage == stage, ]
  bad <- any(p$severity == "error")
  jw_manifest_update(rd, stage, status = if (bad) "failed" else "done", finished = .now(), n_problems = nrow(p),
                     versions = list(R = as.character(getRversion()), quarto = qv,
                                     arrow = as.character(utils::packageVersion("arrow")),
                                     validate = as.character(utils::packageVersion("validate"))))
  invisible(p)
}

# ---- S6 summary (small markdown the next conversation reads instead of the HTML) -------------------
jw_summary_data <- function(week = jw_week_id(), root = jw_root(), today = Sys.Date()) {
  rd <- jw_run_dir(week, root); m <- jw_manifest_read(rd)
  stt <- vapply(jw_stages$stage, function(s) .stage_status(m, s), "")
  led <- jw_ledger_read(root); rd_exists <- function(s) file.exists(jw_stage_file(s, week, root))
  new <- led[led$first_week == week, ]; new <- new[order(new$class, decreasing = TRUE), ]
  openlike <- led$status %in% c("Verified open", "Probably open", "Deadline conflict")
  soon <- led[openlike & !is.na(led$deadline) & led$deadline >= today & led$deadline <= today + 14, ]
  s4 <- if (rd_exists("s4")) jw_read_stage("s4", week, root) else NULL
  s1 <- if (rd_exists("s1")) jw_read_stage("s1", week, root) else NULL
  s5 <- if (rd_exists("s5")) jw_read_stage("s5", week, root) else NULL
  incomplete <- character()
  for (s in c("s0", "s1", "s2", "s3", "s4")) if (stt[[s]] != "done") incomplete <- c(incomplete, sprintf("stage %s is %s", s, stt[[s]]))
  if (!stt[["s5"]] %in% c("done", "skipped")) incomplete <- c(incomplete, "discovery (s5) neither run nor skipped")
  prob <- jw_problems_read(week, root)
  list(week = week, today = today, stage_status = stt, incomplete = incomplete, new = new, soon = soon,
       near_miss = if (!is.null(s4)) s4[!is.na(s4$near_miss) & s4$near_miss, ] else NULL,
       sources = s1, s4 = s4, s5 = s5, problems = prob, ledger = led, baseline = !any(led$first_week < week, na.rm = TRUE) && nrow(led) > 0,
       lessons_pending = sum(!prob$reported & prob$severity %in% c("warn", "error")))
}

jw_write_summary <- function(week = jw_week_id(), root = jw_root(), today = Sys.Date(), max_lines = 15) {
  d <- jw_summary_data(week, root, today)
  fmt <- function(x) sprintf("- [%s] %s | %s | %s | deadline %s | %s", x$class, x$status, x$employer, x$title,
                             ifelse(is.na(x$deadline), "n/a", format(x$deadline)), x$url)
  lines <- c(sprintf("# Job watch %s", d$week), "",
    if (length(d$incomplete)) c(sprintf("**INCOMPLETE:** %s.", paste(d$incomplete, collapse = "; ")), "") else "Complete: all required stages done.",
    if (isTRUE(d$baseline)) "This is the first run with a ledger: treat everything as a baseline, not as news." else NULL, "",
    sprintf("New opportunities: %d. Closing within 14 days: %d. Near-misses: %d.", nrow(d$new), nrow(d$soon), if (is.null(d$near_miss)) 0L else nrow(d$near_miss)), "",
    "## New (best class first)", if (nrow(d$new)) head(fmt(d$new), max_lines) else "none",
    "", "## Closing within 14 days", if (nrow(d$soon)) head(fmt(d$soon), max_lines) else "none",
    "", "## Near-misses (fail exactly one hard rule)",
    if (!is.null(d$near_miss) && nrow(d$near_miss)) head(sprintf("- %s | %s | rule: %s", d$near_miss$employer, d$near_miss$title, d$near_miss$near_miss_rule), max_lines) else "none",
    "", "## Sources",
    if (!is.null(d$sources)) sprintf("%d sources; flags: %s; statuses: %s.", nrow(d$sources),
      paste(sprintf("%s %d", names(table(d$sources$flag)), table(d$sources$flag)), collapse = ", "),
      paste(sprintf("%s %d", names(table(d$sources$status)), table(d$sources$status)), collapse = ", ")) else "no probe data",
    "", "## Discovery", if (!is.null(d$s5)) sprintf("%d leads, %d verified.", nrow(d$s5), sum(d$s5$lead_status == "verified")) else paste("stage s5:", d$stage_status[["s5"]]),
    "", "## Run log", sprintf("%d problem(s) recorded; %d not yet turned into lessons.", nrow(d$problems), d$lessons_pending))
  writeLines(lines, file.path(jw_run_dir(week, root), "summary.md"), useBytes = TRUE)
  invisible(d)
}

# ---- S6 report: summary.md first (independent of Quarto), then the dashboard -----------------------
jw_render_report <- function(week = jw_week_id(), root = jw_root(), today = Sys.Date(),
                             template = file.path(dirname(jw_script_dir()), "..", "assets", "pipeline", "report.qmd")) {
  jw_stage_begin("s6", week, root); rd <- jw_run_dir(week, root); on.exit(jw_lock_release(rd), add = TRUE)
  jw_write_summary(week, root, today)
  qmd <- file.path(rd, "report.qmd"); file.copy(template, qmd, overwrite = TRUE)
  err <- tryCatch({
    quarto::quarto_render(qmd, quiet = TRUE, execute_params = list(root = normalizePath(root), week = week,
      script_dir = normalizePath(jw_script_dir()), today = format(today)))
    NULL }, error = function(e) conditionMessage(e))
  if (!is.null(err)) jw_problem("s6", "report_render_failed", err, "error", 1L, week, root)
  jw_manifest_update(rd, "s6", status = if (is.null(err)) "done" else "failed", finished = .now(), n_rows = NA_integer_,
                     md5 = .md5(file.path(rd, "summary.md")))
  invisible(file.path(rd, "report.html"))
}
