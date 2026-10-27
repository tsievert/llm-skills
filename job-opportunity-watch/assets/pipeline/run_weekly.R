# run_weekly.R -- headless entry point for the staged weekly job-watch pipeline. Runs s0-s3
# (preflight, probe, diff/prefilter, deadline check) through targets::tar_make() and stops with
# STAGE_PENDING at s4, the assistant stage. Usage: Rscript run_weekly.R  (works from any working
# directory; intended for a scheduled task or a manual background run, not for the assistant).
#
# Path variables (set as environment variables before running; defaults below assume this file
# stays at <skill>/assets/pipeline/run_weekly.R and the data folder is a sibling of the skill repo):
#   JW_SKILL  skill folder (default: derived from this script's own location)
#   JW_ROOT   data folder, holds links.csv, job_profile.yml, runs/ (default: "job-watch" next to
#             the skill repo's parent folder; almost always wrong for a real setup -- set it)
#   JW_WEEK   ISO week to run, e.g. "2026-W44" (default: the current week)
# Derived from the script's own location, not getwd(), so a scheduled task (which may start in
# system32 on Windows) still finds the right files.

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])
if (is.na(script) || !nzchar(script)) {
  # Not launched with Rscript (e.g. sourced for a dry run): fall back to the known repo-relative path.
  script <- "job-opportunity-watch/assets/pipeline/run_weekly.R"
}
here <- normalizePath(dirname(script), winslash = "/", mustWork = FALSE)

skill_dir <- Sys.getenv("JW_SKILL", normalizePath(file.path(here, "..", ".."), winslash = "/", mustWork = FALSE))
root <- Sys.getenv("JW_ROOT", file.path(dirname(skill_dir), "job-watch"))
week <- Sys.getenv("JW_WEEK", "")
if (!nzchar(week)) week <- format(Sys.Date(), "%G-W%V")

message("job-opportunity-watch: skill=", skill_dir, " root=", root, " week=", week)

library(targets)
Sys.setenv(JW_SKILL = skill_dir, JW_ROOT = root, JW_WEEK = week)
store <- file.path(root, "runs", week, "_targets")

res <- tryCatch(
  tar_make(script = file.path(skill_dir, "assets", "pipeline", "_targets.R"), store = store, callr_function = NULL),
  error = function(e) e)

# Always print jw_status() at the end, success or failure, so a scheduled-task log is self-explanatory.
source(file.path(skill_dir, "scripts", "pipeline", "jw_report.R"))
jw_load(file.path(skill_dir, "scripts", "pipeline"))
options(jobwatch.dir = root)
jw_status(week, root)

if (inherits(res, "error")) {
  msg <- conditionMessage(res)
  if (grepl("STAGE_PENDING", msg)) {
    message("Stopped at the assistant stage as expected (s0-s3 done): ", msg)
  } else {
    message("run_weekly.R failed: ", msg)
    if (!interactive()) quit(status = 1, save = "no")
  }
}

# ---- scheduling (Windows Task Scheduler via schtasks) -----------------------------------------
# Not installed automatically: ask the user before adding a scheduled task. From Git Bash, give
# schtasks its switches with a doubled slash, or the shell rewrites "/Create" etc. as paths:
#
#   schtasks //Create //SC WEEKLY //D MON //TN "job-opportunity-watch" //TR \
#     "\"C:\\Program Files\\R\\R-4.6.0\\bin\\Rscript.exe\" \"<skill-dir>\\assets\\pipeline\\run_weekly.R\"" \
#     //ST 06:00
#
# Set JW_ROOT (and JW_SKILL if this file was copied elsewhere) as system/user environment
# variables first, since a scheduled task does not inherit the interactive session's variables.
# No "seen" state needs seeding: s2 derives what is new from earlier finished weeks' s1_anchors,
# and the first run is reported as a baseline in summary.md.
