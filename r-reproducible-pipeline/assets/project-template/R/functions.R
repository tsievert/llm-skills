# Functions used by the targets in _targets.R. Keep targets thin: logic lives here.

# Read the YAML config and fail early on the YAML 1.1 trap: R's yaml package turns
# unquoted keys such as n, y, yes, no, on, off into logical values.
read_config <- function(path) {
  cfg <- yaml::read_yaml(path)
  bad <- names(cfg) %in% c("TRUE", "FALSE", "NA", "") | is.na(names(cfg))
  if (is.null(names(cfg)) || any(bad)) {
    stop("config keys were parsed as logical or empty; use descriptive keys such as n_obs: ", path)
  }
  required <- c("samples", "n_obs", "slope")
  missing_keys <- setdiff(required, names(cfg))
  if (length(missing_keys)) stop("missing config keys: ", paste(missing_keys, collapse = ", "))
  cfg
}

# Run the Python step through uv with the locked environment in py/.
# The script path is an argument (a file target), so edits to it are tracked.
run_python_sim <- function(script, sample_id, n_obs, slope, seed) {
  out <- file.path("data", paste0("sim_", sample_id, ".csv"))
  dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
  status <- system2(
    "uv",
    c("run", "--locked", "--project", "py", "python", shQuote(script),
      n_obs, slope, seed, shQuote(out))
  )
  if (!identical(status, 0L)) stop("Python step failed for sample ", sample_id)
  out
}

read_sim <- function(path) {
  d <- utils::read.csv(path)
  d$sample <- sub("^sim_(.*)\\.csv$", "\\1", basename(path))
  d
}

fit_model <- function(data) stats::lm(y ~ x + sample, data = data)

tidy_coefs <- function(fit) {
  cf <- summary(fit)$coefficients
  data.frame(term = rownames(cf), estimate = cf[, "Estimate"], std_error = cf[, "Std. Error"],
             row.names = NULL)
}
