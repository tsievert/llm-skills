# Running targets on a Slurm cluster (crew.cluster)

Contents: the pattern; controller options; what to ask the user to run; untested parts;
alternatives.

The assistant is local only (see "Where this skill runs" in SKILL.md). Everything here that
touches the cluster is **untested until the user runs it**.

## The pattern

1. The main `tar_make()` process runs in a small batch job (`slurm/run_targets.sbatch`), or on
   a login node if the site allows it.
2. `crew.cluster::crew_controller_slurm()` submits worker jobs with `sbatch`; targets send
   work to them. `PIPELINE_EXECUTOR=slurm` selects it in `R/controllers.R`.
3. The `_targets/` store must sit on a filesystem every worker can read and write.

The targets manual page on HPC covers the older `tar_make_clustermq()` / `tar_make_future()`
routes and does not say where the main process should run; the crew-based pattern above is the
documented current route for distributed work (crew chapter), but how a given site wants the
main process started is a site decision.

## Controller options (crew.cluster 0.4.0 reference)

```r
crew.cluster::crew_controller_slurm(
  workers = 4, seconds_idle = 120,
  options_cluster = crew.cluster::crew_options_slurm(
    partition = "...", cpus_per_task = 1, memory_gigabytes_required = 4,
    time_minutes = 60, log_output = "logs/crew/crew_%A.out", log_error = "logs/crew/crew_%A.err",
    script_lines = "module load R", script_directory = tools::R_user_dir("crew.cluster", "cache")
  )
)
```

- `time_minutes` is the Slurm walltime. `seconds_wall` is only a soft limit inside mirai.
- `log_output` and `log_error` default to `/dev/null`: no worker logs unless set (`%A` = job ID).
- `script_directory` defaults to `tempdir()`, which the docs say may not work on some systems.
- `memory_gigabytes_required` maps to `--mem`, `memory_gigabytes_per_cpu` to `--mem-per-cpu`,
  `n_tasks` to `--ntasks` (0 omits it). The old per-argument form (`slurm_partition`, ...) is
  deprecated.
- The controller is "maturing" and `crew_options_slurm()` "experimental" in the reference:
  pin crew.cluster in renv and re-read the reference before use.
- Crashed workers are not restarted automatically, but targets retries a target
  (`crashes_max`, default 5).
- Tested: the object builds without `sbatch` present. Not tested: submission.

## Ask the user to run, then paste the output

```bash
sinfo -s                                  # partitions
sacctmgr show assoc user=$USER format=account,partition,qos    # account to use
module avail R 2>&1 | head -30            # R modules
which sbatch; Rscript --version           # on a login node
```

and, from a compute node (`srun --pty bash`), `which Rscript; R -e 'library(targets)'` to
confirm the project library loads. Ask whether workers may call `sbatch` from a compute node
and whether a long-running R process may stay on the login node; both vary by site.

## After a first cluster run

Ask for `sacct -j <jobid> --format=JobID,Elapsed,MaxRSS,State` for the worker jobs and size
`memory_gigabytes_required` and `time_minutes` from it (`hpc-resource-allocation`).

## Alternatives

`future.batchtools` and `clustermq` still work with targets but the manual recommends crew for
new work. For a Python-centred workflow use Snakemake with the Slurm executor plugin
(`python-reproducible-pipeline`).
