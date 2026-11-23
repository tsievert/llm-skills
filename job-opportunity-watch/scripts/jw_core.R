# jw_core.R -- shared basics for the job-opportunity-watch helpers: package guard, user agent, state paths, small
# tsv/text helpers, progress ticks. Loaded first by jobwatch.R.

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

# One-line progress message: "[i/n] 42% elapsed 1m05s, about 1m30s left | what". Goes to stderr via message(),
# so it shows in the console and in logs of headless runs. `t0` is the start time of the loop.
jw_tick <- function(i, n, t0, what = "") {
  el <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  fmt <- function(s) if (!is.finite(s)) "?" else if (s < 60) sprintf("%ds", round(s)) else sprintf("%dm%02ds", s %/% 60, round(s %% 60))
  eta <- if (i > 0) el / i * (n - i) else NA_real_
  message(sprintf("[%d/%d] %3d%% elapsed %s, about %s left | %s", i, n, round(100 * i / n), fmt(el), fmt(eta), what))
}

# Tries, in order: shorter parent paths on the same host, the site's sitemaps (robots.txt "Sitemap:"
# lines plus common names, one level of sitemap index), and job-like links on the home page and
# parent pages. Returns scored candidates that each respond with HTTP < 400. Candidates are only
# suggestions: verify them and propose them to the user (jw_add_link needs confirmation).
.job_url_re <- paste0("vacanc|career|jobs?([/_.-]|$)|position|opening|stellen|ledig|jobb|tyopaik|ty%C3%B6paik|",
  "avoimet|emploi|offre|vacature|werken|work-?(with|at)|join|rekryt|rekrut|recruit|karriere|hiring|tjanst|tj%C3%A4nst")
