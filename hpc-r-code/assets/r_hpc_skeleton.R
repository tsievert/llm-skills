#!/usr/bin/env Rscript
# HPC-ready R skeleton: allocation-aware workers, parallel-safe RNG, chunked work with
# atomic per-chunk checkpoints, skip-if-done, and message() logging.
# Base R only; `parallelly` is used if installed.
#
#   Rscript r_hpc_skeleton.R --out results --n-items 200 --chunk 50
#   (run again: finished chunks are skipped; delete the DONE file and a chunk to redo it)

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(name, default) {
  i <- match(paste0("--", name), args)
  if (is.na(i) || i == length(args)) default else args[i + 1L]
}
out_dir  <- get_arg("out", "results")
n_items  <- as.integer(get_arg("n-items", "100"))
chunk_sz <- as.integer(get_arg("chunk", "25"))
task_id  <- as.integer(Sys.getenv("SLURM_ARRAY_TASK_ID", unset = "0"))

log_msg <- function(...) {
  message(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " job=",
          Sys.getenv("SLURM_JOB_ID", "local"), " task=", task_id, " ", ...)
}

# Use the Slurm allocation, not parallel::detectCores() (which reports the whole node)
n_workers <- function() {
  if (requireNamespace("parallelly", quietly = TRUE)) {
    return(as.integer(parallelly::availableCores()))
  }
  as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", unset = "1"))
}

# Atomic write: temp file in the same directory, then rename
save_atomic <- function(x, path) {
  tmp <- paste0(path, ".tmp.", Sys.getpid())
  saveRDS(x, tmp)
  if (!file.rename(tmp, path)) stop("rename failed for ", path)
}

work <- function(i) {
  Sys.sleep(0.01)                      # replace with the real computation
  c(item = i, value = i^2, draw = rnorm(1))
}

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
done_marker <- file.path(out_dir, "DONE")
log_msg("host=", Sys.info()[["nodename"]], " R=", getRversion(),
        " workers=", n_workers())

if (file.exists(done_marker)) {
  log_msg("already complete; nothing to do")
  quit(status = 0L)
}

# Parallel-safe RNG: L'Ecuyer streams, base seed derived from the task ID and logged
RNGkind("L'Ecuyer-CMRG")
base_seed <- 1000L + task_id
set.seed(base_seed)
log_msg("seed=", base_seed)

chunks <- split(seq_len(n_items), ceiling(seq_len(n_items) / chunk_sz))
use_fork <- .Platform$OS.type == "unix"   # mclapply does not fork on Windows
t0 <- Sys.time()

for (k in seq_along(chunks)) {
  path <- file.path(out_dir, sprintf("chunk_%03d_task%03d.rds", k, task_id))
  if (file.exists(path)) { log_msg("chunk ", k, " exists; skipping"); next }
  res <- if (use_fork) {
    parallel::mclapply(chunks[[k]], work, mc.cores = n_workers(), mc.set.seed = TRUE)
  } else {
    lapply(chunks[[k]], work)
  }
  save_atomic(do.call(rbind, res), path)
  log_msg("chunk ", k, "/", length(chunks), " saved")
}

file.create(done_marker)
log_msg("finished in ", round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1), "s")
