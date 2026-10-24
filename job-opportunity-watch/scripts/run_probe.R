# Headless probe for schedulers. Usage: Rscript run_probe.R <data-folder>
# Example (Windows Task Scheduler action): Rscript C:/path/to/job-opportunity-watch/scripts/run_probe.R C:/path/to/job-watch
# Needs the web-fetching-r skill installed as a sibling skill folder (true for both this repo and
# a skills.paths install): <skills-root>/web-fetching-r/scripts/polite_fetch.R.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("Usage: Rscript run_probe.R <data-folder containing links.txt>")
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
skills_root <- dirname(dirname(here))
pf_script <- file.path(skills_root, "web-fetching-r", "scripts", "polite_fetch.R")
if (!file.exists(pf_script)) {
  stop("Cannot find the web-fetching-r skill next to job-opportunity-watch (looked for ", pf_script,
       "). Install both skills as siblings, or edit this path.")
}
source(pf_script)
source(file.path(here, "jobwatch.R"))
message("Digest written: ", jw_headless(args[1]))
