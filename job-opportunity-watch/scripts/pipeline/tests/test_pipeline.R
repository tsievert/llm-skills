# Unit tests for the staged pipeline skeleton (contracts, validation, gates, life cycle, ledger, lessons).
# Run: testthat::test_dir("<skill-dir>/scripts/pipeline/tests"). Uses a throw-away data folder.
library(testthat)
here <- normalizePath(file.path(dirname(sys.frame(1)$ofile %||% "."), ".."), mustWork = FALSE)
if (!file.exists(file.path(here, "jw_contracts.R"))) here <- normalizePath(file.path(getwd(), ".."))
for (f in c("jw_contracts.R", "jw_pipeline.R", "jw_checks.R", "jw_stage_fns.R", "jw_report.R")) source(file.path(here, f))

TODAY <- as.Date("2026-10-27"); WK <- "2026-W44"
new_root <- function() { r <- tempfile("jwroot"); dir.create(r); r }
done <- function(root, ...) for (s in c(...)) jw_manifest_update(jw_run_dir(WK, root), s, status = "done")

s1_ok <- function(n = 3) data.frame(source_id = paste0("src", seq_len(n)), url = paste0("https://x", seq_len(n), ".example"),
  section = "a", type = "html", status = "ok", http = 200L, n_anchors = 10L, n_job_like = 5L, flag = "fine", note = NA, checked = TODAY)
s2_ok <- function() data.frame(item_id = c("i1", "i2", "i3", "i4"), source_id = "src1", text = paste("title", 1:4),
  href = paste0("https://x.example/", 1:4), tier = c(1L, 1L, 2L, 2L), reason = "kept", first_seen = TODAY)
s3_ok <- function() data.frame(item_id = c("i1", "i2", "i3", "i4"), deadline = as.Date(c("2026-11-10", "2026-09-01", NA, NA)),
  verdict = c("open", "expired", "no_deadline_found", "not_checked"), flag = NA, dates = NA)
s4_ok <- function() data.frame(item_id = c("i1", "i3", "i4"), decision = c("classified", "classified", "rejected_title"),
  opp_id = c("uni-a-123", "inst-b-9", NA), class = c("D", "B", NA), status = c("Verified open", "Unresolved", NA),
  track = c("primary", "primary", NA), employer = c("Uni A", "Inst B", NA), title = c("Postdoc x", "Researcher y", NA),
  country = c("FI", "SE", NA), contract = c("2 y", NA, NA), deadline = as.Date(c("2026-11-10", NA, NA)),
  evidence_url = c("https://uni-a.example/123", NA, NA), why = c("fits", "unclear", NA), weakest_dimension = c("method", "contract", NA),
  near_miss = c(FALSE, TRUE, NA), near_miss_rule = c(NA, "fte", NA), notes = NA)

build_to_s3 <- function(root) {
  done(root, "s0")
  jw_stage_begin("s1", WK, root, expected_n = 3); jw_write_stage(s1_ok(), "s1", WK, root); jw_stage_close("s1", WK, root, TODAY)
  jw_stage_begin("s2", WK, root); jw_write_stage(s2_ok(), "s2", WK, root); jw_stage_close("s2", WK, root, TODAY)
  jw_stage_begin("s3", WK, root); jw_write_stage(s3_ok(), "s3", WK, root); jw_stage_close("s3", WK, root, TODAY)
}
codes <- function(v) v$code

test_that("every contract compiles with no rule dropped, and unsupported syntax is refused", {
  for (s in names(jw_contracts())) expect_silent(jw_make_validator(jw_contracts()[[s]]$rules))
  expect_warning(expect_error(jw_make_validator(c(bad = 'inherits(x, "Date")')), "dropped"), "Invalid syntax")
})

test_that("ISO week helpers", {
  expect_equal(jw_week_id(as.Date("2026-10-27")), "2026-W44")
  expect_equal(format(jw_week_start("2026-W44")), "2026-10-26")
  expect_equal(jw_week_id(as.Date("2027-01-01")), "2026-W53")
})

test_that("write coerces to the schema, adds missing columns, rejects strangers, reads back identical schema", {
  r <- new_root(); f <- file.path(r, "t.parquet"); sch <- jw_contracts()$s1$schema
  jw_write_parquet(s1_ok()[, c("source_id", "url", "status")], f, sch)
  expect_true(arrow::read_parquet(f, as_data_frame = FALSE)$schema$Equals(sch))
  expect_error(jw_write_parquet(cbind(s1_ok(), zzz = 1), f, sch), "unexpected column")
  jw_write_parquet(data.frame()[0, ], f, sch); expect_equal(nrow(arrow::read_parquet(f)), 0L)
  expect_length(list.files(r, pattern = "tmp-"), 0)
})

test_that("a valid week passes every stage and a faulty s4 fails with the expected rules", {
  r <- new_root(); build_to_s3(r)
  expect_equal(jw_status(WK, r, quiet = TRUE)$next_stage, "s4")
  # NA class on a rejected_title row must NOT count as a failure
  jw_stage_begin("s4", WK, r); jw_write_stage(s4_ok(), "s4", WK, r)
  expect_equal(nrow(jw_validate_stage("s4", WK, r, TODAY)), 0)
  bad <- s4_ok(); bad$class[1] <- "F"; bad$evidence_url[1] <- NA; bad$item_id[2] <- "i1"; bad$near_miss_rule[2] <- NA
  jw_write_stage(bad, "s4", WK, r); v <- jw_validate_stage("s4", WK, r, TODAY)
  expect_true(all(c("s4_key_unique", "s4_class_enum", "s4_verified_open", "s4_near_miss", "s4_coverage") %in% codes(v)))
  jw_lock_release(jw_run_dir(WK, r))
})

test_that("completeness gates: missing, extra and duplicate ids; s1 coverage", {
  r <- new_root(); build_to_s3(r)
  v <- jw_gate_s4(s4_ok()[1:2, ], s3_ok()); expect_match(v$message[1], "1 candidate")
  v <- jw_gate_s4(rbind(s4_ok(), transform(s4_ok()[1, ], item_id = "zzz")), s3_ok()); expect_match(v$message[1], "match no")
  expect_true(any(grepl("more than once", jw_gate_s4(rbind(s4_ok(), s4_ok()[1, ]), s3_ok())$message)))
  expect_equal(nrow(jw_gate_s4(s4_ok(), s3_ok())), 0)               # expired i2 is not a candidate
  expect_equal(jw_gate_s1(s1_ok(3), 4)$code, "s1_coverage")
  expect_equal(jw_gate_s1(s1_ok(3), NULL)$code, "s1_expected_n_missing")
  expect_equal(jw_gate_s3(s3_ok()[1:3, ], s2_ok())$code, "s3_coverage")
})

test_that("schema drift in a file is caught", {
  r <- new_root(); build_to_s3(r)
  f <- jw_stage_file("s2", WK, r)
  df <- as.data.frame(arrow::read_parquet(f, mmap = FALSE)); df$tier <- as.character(df$tier)
  arrow::write_parquet(df, f)
  expect_equal(jw_validate_stage("s2", WK, r, TODAY)$code, "s2_schema")
})

test_that("life cycle: dependency refusal, lock, stale lock, failed stage recorded and lock released", {
  r <- new_root(); done(r, "s0")
  expect_error(jw_stage_begin("s3", WK, r), "needs s2")
  jw_stage_begin("s1", WK, r, expected_n = 1)
  expect_error(jw_stage_begin("s1", WK, r), "locked")
  expect_true(jw_status(WK, r, quiet = TRUE)$locked)
  jw_lock_release(jw_run_dir(WK, r))
  writeLines(jsonlite::toJSON(list(stage = "s1", time = format(Sys.time() - 7 * 3600, "%Y-%m-%dT%H:%M:%S")), auto_unbox = TRUE), jw_lock_path(jw_run_dir(WK, r)))
  expect_silent(jw_stage_begin("s1", WK, r, expected_n = 1))            # stale lock is replaced
  jw_lock_release(jw_run_dir(WK, r))
  expect_error(jw_stage_run("s1", function() stop("boom at https://secret.example/x"), WK, r, expected_n = 1), "boom")
  expect_false(file.exists(jw_lock_path(jw_run_dir(WK, r))))
  m <- jw_manifest_read(jw_run_dir(WK, r)); expect_equal(m$stages$s1$status, "failed")
  p <- jw_problems_read(WK, r); expect_equal(p$code, "s1_error"); expect_false(grepl("secret", p$message))
  expect_error(jw_lock_break(WK, r), "confirm")
})

test_that("s4 parts are resumable: pending shrinks, close merges, validates and updates the ledger", {
  r <- new_root(); build_to_s3(r)
  jw_stage_begin("s4", WK, r)
  pend <- jw_pending("s4", WK, r); expect_setequal(pend$item_id, c("i1", "i3", "i4"))   # i2 expired
  expect_equal(pend$item_id[1:2], c("i1", "i3"))                                          # tier 1 first
  jw_part_write(s4_ok()[1, ], "s4", WK, r)
  expect_setequal(jw_pending("s4", WK, r)$item_id, c("i3", "i4"))
  expect_equal(nrow(jw_stage_close("s4", WK, r, TODAY)), 1)                               # incomplete: gate fails
  expect_equal(jw_manifest_read(jw_run_dir(WK, r))$stages$s4$status, "failed")
  jw_stage_begin("s4", WK, r); jw_part_write(s4_ok()[2:3, ], "s4", WK, r)
  expect_equal(nrow(jw_stage_close("s4", WK, r, TODAY)), 0)
  expect_equal(jw_manifest_read(jw_run_dir(WK, r))$stages$s4$status, "done")
  led <- jw_ledger_read(r); expect_setequal(led$opp_id, c("uni-a-123", "inst-b-9")); expect_true(all(led$first_week == WK))
})

test_that("ledger keeps first_week and updates changed fields in a later week", {
  r <- new_root(); build_to_s3(r)
  jw_stage_begin("s4", WK, r); jw_part_write(s4_ok(), "s4", WK, r); jw_stage_close("s4", WK, r, TODAY)
  wk2 <- "2026-W45"; rd2 <- jw_run_dir(wk2, r)
  for (s in c("s0", "s1", "s2", "s3")) jw_manifest_update(rd2, s, status = "done")
  jw_write_stage(s2_ok(), "s2", wk2, r); jw_write_stage(s3_ok(), "s3", wk2, r)
  x <- s4_ok(); x$status[1] <- "Expired"
  jw_write_stage(x, "s4", wk2, r); jw_ledger_upsert(wk2, r)
  led <- jw_ledger_read(r); a <- led[led$opp_id == "uni-a-123", ]
  expect_equal(a$status, "Expired"); expect_equal(a$first_week, WK); expect_equal(a$last_week, wk2); expect_equal(nrow(led), 2)
})

test_that("problems become lesson candidates with generic text, and can be marked reported", {
  r <- new_root(); dir.create(jw_run_dir(WK, r), recursive = TRUE)
  jw_problem("s2", "feed_ignored_filter", "feed at https://a.example/rss ignored C:/Users/me/x filters", "warn", 2L, WK, r)
  out <- capture.output(g <- jw_lessons_candidates(WK, r))
  expect_true(any(grepl('lesson_add\\(skill = "job-opportunity-watch"', out))); expect_false(any(grepl("a.example|Users", out)))
  jw_lessons_mark_reported(WK, r); expect_equal(nrow(jw_lessons_candidates(WK, r)), 0)
})

test_that("inputs are frozen per week and a mid-week change is flagged", {
  r <- new_root(); dir.create(jw_run_dir(WK, r), recursive = TRUE)
  writeLines("url\nhttps://a.example", file.path(r, "links.csv")); writeLines("career_search_profile: {}", file.path(r, "job_profile.yml"))
  jw_freeze_inputs(WK, r); expect_equal(nrow(jw_problems_read(WK, r)), 0)
  writeLines("url\nhttps://b.example", file.path(r, "links.csv")); jw_freeze_inputs(WK, r)
  expect_equal(jw_problems_read(WK, r)$code, "changed_mid_week_links")
})

test_that("preflight passes on a good folder and reports a truncated profile", {
  r <- new_root(); writeLines("url\nhttps://a.example", file.path(r, "links.csv"))
  writeLines("career_search_profile:\n  a: 1", file.path(r, "job_profile.yml"))
  p <- jw_preflight(WK, r, run_tests = FALSE); expect_false(any(p$severity == "error"))
  expect_equal(jw_manifest_read(jw_run_dir(WK, r))$stages$s0$status, "done")
  r2 <- new_root(); writeLines("url\nhttps://a.example", file.path(r2, "links.csv"))
  cat("career_search_profile:\n  a: 1", file = file.path(r2, "job_profile.yml"))
  p2 <- jw_preflight(WK, r2, run_tests = FALSE); expect_true("profile_no_final_newline" %in% p2$code)
})

test_that("summary says INCOMPLETE until discovery is run or skipped", {
  r <- new_root(); build_to_s3(r); jw_stage_begin("s4", WK, r); jw_part_write(s4_ok(), "s4", WK, r); jw_stage_close("s4", WK, r, TODAY)
  jw_write_summary(WK, r, TODAY); s <- readLines(file.path(jw_run_dir(WK, r), "summary.md"))
  expect_true(any(grepl("INCOMPLETE", s))); expect_true(any(grepl("Postdoc x", s)))
  expect_error(jw_stage_skip("s4", "no"), "not optional")
  jw_stage_skip("s5", "not requested this week", WK, r); done(r, "s0")
  jw_write_summary(WK, r, TODAY)
  s <- readLines(file.path(jw_run_dir(WK, r), "summary.md")); expect_false(any(grepl("INCOMPLETE", s)))
})

test_that("dashboard renders from a finished synthetic week", {
  skip_if(identical(Sys.getenv("JW_PREFLIGHT"), "1"), "slow; skipped inside the weekly preflight")
  skip_if_not(requireNamespace("quarto", quietly = TRUE) && !is.na(tryCatch(quarto::quarto_version(), error = function(e) NA)))
  r <- new_root(); build_to_s3(r); jw_stage_begin("s4", WK, r); jw_part_write(s4_ok(), "s4", WK, r); jw_stage_close("s4", WK, r, TODAY)
  jw_stage_skip("s5", "n/a", WK, r)
  options(jobwatch.script_dir = here)
  out <- jw_render_report(WK, r, TODAY, template = file.path(here, "..", "..", "assets", "pipeline", "report.qmd"))
  expect_true(file.exists(out)); expect_equal(jw_manifest_read(jw_run_dir(WK, r))$stages$s6$status, "done")
  expect_match(paste(readLines(out, warn = FALSE), collapse = " "), "Postdoc x")
})

test_that("jw_s4_amend corrects one row in place, refuses unknown ids, and parts read keeps the last row per item", {
  r <- new_root(); build_to_s3(r); jw_stage_begin("s4", WK, r); jw_part_write(s4_ok(), "s4", WK, r); jw_stage_close("s4", WK, r, TODAY)
  expect_error(jw_s4_amend("nope", class = "C", week = WK, root = r), "not found")
  expect_error(jw_s4_amend("i3", colour = "x", week = WK, root = r), "unknown s4 column")
  v <- jw_s4_amend("i3", class = "C", notes = "open call", week = WK, root = r)
  expect_equal(nrow(v), 0)
  d <- jw_read_stage("s4", WK, r); expect_equal(nrow(d), 3); expect_equal(d$class[d$item_id == "i3"], "C")
  expect_equal(jw_manifest_read(jw_run_dir(WK, r))$stages$s4$status, "done")
  # a re-written batch for the same id must not duplicate it
  jw_part_write(transform(s4_ok()[2, ], class = "D"), "s4", WK, r)
  p <- jw_parts_read("s4", WK, r); expect_equal(sum(p$item_id == "i3"), 1); expect_equal(p$class[p$item_id == "i3"], "D")
})

test_that("jw_status lists unreported errors; jw_load records the script dir; render with a bad script dir stops", {
  r <- new_root(); dir.create(jw_run_dir(WK, r), recursive = TRUE)
  jw_problem("s6", "report_render_failed", "boom", "error", 1L, WK, r)
  out <- capture.output(st <- jw_status(WK, r)); expect_true(any(grepl("Unreported error", out)))
  expect_equal(nrow(st$unreported_errors), 1)
  jw_lessons_mark_reported(WK, r); expect_equal(nrow(jw_status(WK, r, quiet = TRUE)$unreported_errors), 0)
  old <- options(jobwatch.script_dir = NULL); on.exit(options(old))
  jw_load(here); expect_equal(getOption("jobwatch.script_dir"), normalizePath(here))
  options(jobwatch.script_dir = file.path(tempdir(), "nope"))
  expect_error(jw_render_report(WK, r, TODAY), "script_dir")
})

test_that("summary shows the s4 note next to Expired when the listed deadline is still in the future", {
  r <- new_root(); build_to_s3(r); x <- s4_ok(); x$status[1] <- "Expired"; x$notes[1] <- "page marked expired"
  jw_stage_begin("s4", WK, r); jw_part_write(x, "s4", WK, r); jw_stage_close("s4", WK, r, TODAY); jw_stage_skip("s5", "n/a", WK, r)
  jw_write_summary(WK, r, TODAY)
  expect_true(any(grepl("Expired [(]page marked expired[)]", readLines(file.path(jw_run_dir(WK, r), "summary.md")))))
})
