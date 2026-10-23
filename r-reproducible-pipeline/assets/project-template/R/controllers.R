# Choose how targets are executed without editing _targets.R:
#   PIPELINE_EXECUTOR unset or "sequential": one target after another (default; laptop)
#   PIPELINE_EXECUTOR=local: two local crew workers
#   PIPELINE_EXECUTOR=slurm: crew.cluster Slurm workers (fill the placeholders from the
#                            site documentation; untested until run on the cluster)
make_controller <- function() {
  mode <- Sys.getenv("PIPELINE_EXECUTOR", "sequential")
  switch(
    mode,
    sequential = NULL,
    local = crew::crew_controller_local(workers = 2, seconds_idle = 30),
    slurm = {
      dir.create("logs/crew", showWarnings = FALSE, recursive = TRUE)
      crew.cluster::crew_controller_slurm(
        workers = 4,
        seconds_idle = 120,
        options_cluster = crew.cluster::crew_options_slurm(
          partition = "<PARTITION>",
          cpus_per_task = 1,
          memory_gigabytes_required = 4,
          # Slurm walltime in minutes; seconds_wall is NOT the Slurm limit
          time_minutes = 60,
          # Worker logs go to /dev/null unless set; %A is the job ID
          log_output = "logs/crew/crew_%A.out",
          log_error = "logs/crew/crew_%A.err",
          script_lines = "# module load R/<VERSION>",
          # tempdir() may not work on some systems; keep scripts in a cache dir
          script_directory = tools::R_user_dir("crew.cluster", "cache")
        )
      )
    },
    stop("unknown PIPELINE_EXECUTOR: ", mode)
  )
}
