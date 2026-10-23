# Headless probe for schedulers. Usage: Rscript run_probe.R <data-folder>
# Example (Windows Task Scheduler action): Rscript C:/path/to/job-opportunity-watch/scripts/run_probe.R C:/path/to/job-watch
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("Usage: Rscript run_probe.R <data-folder containing links.txt>")
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "jobwatch.R"))
message("Digest written: ", jw_headless(args[1]))
