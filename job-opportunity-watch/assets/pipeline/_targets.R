# Weekly staged pipeline for job-opportunity-watch (headless part). Run with:
#   targets::tar_make(script = "<skill-dir>/assets/pipeline/_targets.R", store = "<data>/runs/<week>/_targets")
# Environment: JW_ROOT (data folder), JW_WEEK (default: current ISO week), JW_SKILL (skill folder).
# The assistant stages are NOT run here: s4 (and optional s5) appear as file targets that wait for the
# parquet file the conversation writes. Until it exists, tar_make() stops at that target and everything
# upstream stays cached; after the file appears (or changes) only the targets below it rerun.
library(targets)
skill <- Sys.getenv("JW_SKILL", file.path("job-opportunity-watch"))
options(jobwatch.dir = Sys.getenv("JW_ROOT", "job-watch"), jobwatch.script_dir = file.path(skill, "scripts", "pipeline"))
for (f in c("jw_contracts.R", "jw_pipeline.R", "jw_checks.R", "jw_stage_fns.R", "jw_report.R")) source(file.path(skill, "scripts", "pipeline", f))
week <- Sys.getenv("JW_WEEK", jw_week_id())
# Network helpers: polite_fetch.R (web-fetching-r skill, a sibling folder unless JW_FETCH points elsewhere), then jobwatch.R.
# The fixture tests inject fake fetchers, so a missing file only matters when s1-s3 really run.
fetch_r <- Sys.getenv("JW_FETCH", file.path(dirname(normalizePath(skill)), "web-fetching-r", "scripts", "polite_fetch.R"))
if (file.exists(fetch_r)) { source(fetch_r); source(file.path(skill, "scripts", "jobwatch.R")) }

# Reads the stage file the assistant wrote, or stops with a clear message (not a mystery failure).
await_stage <- function(stage) {
  f <- jw_stage_file(stage, week)
  if (!identical(jw_manifest_read(jw_run_dir(week))$stages[[stage]]$status, "done"))
    stop(sprintf("STAGE_PENDING: %s is an assistant stage that is not closed yet; start a new conversation and run it (jw_status() says how).", stage), call. = FALSE)
  if (!file.exists(f)) stop(sprintf("STAGE_PENDING: %s is an assistant stage; start a new conversation and run it (jw_status() says how).", stage), call. = FALSE)
  v <- jw_validate_stage(stage, week)
  if (any(v$severity == "error")) stop(sprintf("STAGE_INVALID: %s output fails its contract: %s", stage, paste(v$code, collapse = ", ")), call. = FALSE)
  f
}

list(
  tar_target(preflight, { jw_preflight(week, tests_dir = file.path(skill, "scripts", "pipeline", "tests")); jw_status(week, quiet = TRUE)$table$status[1] },
             cue = tar_cue(mode = "always")),
  # s1-s3: mechanical stages (scripts/pipeline/jw_stage_fns.R); each writes, validates and records itself
  tar_target(s1, { preflight; jw_stage_run("s1", function() jw_s1_probe(week), week, expected_n = jw_s1_expected_n(week)); jw_stage_file("s1", week) }, format = "file"),
  tar_target(s2, { s1; jw_stage_run("s2", function() jw_s2_queue(week), week); jw_stage_file("s2", week) }, format = "file"),
  tar_target(s3, { s2; jw_stage_run("s3", function() jw_s3_deadlines(week), week); jw_stage_file("s3", week) }, format = "file"),
  # assistant stage: waits for the file; rerun triggers only when its content changes
  tar_target(s4_file, { s3; await_stage("s4") }, format = "file", cue = tar_cue(mode = "always")),
  tar_target(report, { s4_file; jw_render_report(week) }, format = "file", cue = tar_cue(mode = "always"))
)
