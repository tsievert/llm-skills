# jobwatch.R -- helpers for the job-opportunity-watch skill (loader; the code lives in scripts/jw_*.R).
# source("<web-fetching-r skill-dir>/scripts/polite_fetch.R") first, then
# source("<skill-dir>/scripts/jobwatch.R"); set options(jobwatch.dir = "<folder>") first.
# Model-free steps only: parse the links file, probe pages politely, diff against what was seen
# before, keep state files, audit coverage, and edit the links file with backup + confirmation.
# The actual HTTP fetch (user agent, per-host rate limiting, retry, bot-wall/JS heuristics) lives
# in the web-fetching-r skill's polite_fetch.R (pf_*); this file only adds job-portal-specific
# anchor extraction and state.
# Needs: httr2, rvest, xml2, readr, yaml (all CRAN); chromote + Chrome optional (render rung, see portal-quirks.md).
# Layout: this file only loads the concern files next to it, in this order (see scripts/jw_*.R):
# jw_core.R, jw_links.R, jw_sources.R, jw_probe.R, jw_state.R, jw_replace.R, jw_social.R.
# Add new functions to the file for their concern, not here; jw_check_script_layout() (pipeline/jw_report.R, run by the preflight) flags a
# file that is not loaded here or that has grown past its size limit.
# The concern files are found next to this file when it is loaded with source(); for sys.source() or other loaders set
# options(jobwatch.scripts = "<skill-dir>/scripts") first.

.jw_script_dir <- local({
  d <- NULL
  for (i in rev(seq_len(sys.nframe()))) {
    of <- sys.frame(i)$ofile
    if (is.character(of) && length(of) == 1L && file.exists(of)) { d <- dirname(normalizePath(of)); break }
  }
  if (is.null(d)) d <- getOption("jobwatch.scripts")
  if (is.null(d) || !file.exists(file.path(d, "jw_core.R")))
    stop("jobwatch.R cannot find its jw_*.R files: load it with source(), or set options(jobwatch.scripts = \"<skill-dir>/scripts\")")
  d
})

for (.jw_f in c("jw_core.R", "jw_links.R", "jw_sources.R", "jw_probe.R", "jw_state.R", "jw_replace.R", "jw_social.R"))
  source(file.path(.jw_script_dir, .jw_f), local = environment())
rm(.jw_f, .jw_script_dir)
