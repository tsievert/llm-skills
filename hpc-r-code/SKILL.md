---
name: hpc-r-code
description: Writes and reviews R scripts and Slurm job scripts for running R on HPC clusters. Covers Rscript batch jobs, R modules and package libraries (R_LIBS_USER, renv, compiled packages), parallelly::availableCores instead of detectCores, mclapply/foreach/future/BiocParallel worker counts, BLAS threads, reproducible parallel RNG, job arrays with task IDs, atomic checkpoints, logging, graphics devices in batch, and submitting jobs from R with future.batchtools. Use when the user wants to run R or an R pipeline on a cluster, or reports R jobs that are slow, overloaded, out of memory, or cannot find packages on HPC.
---

# R on HPC

Run `hpc-cluster-docs` first (R module names, library policy, internet on compute
nodes are site-specific). Use `hpc-job-scripts` for general script rules, logs and
arrays, and `hpc-resource-allocation` for sizing.

## Where this skill runs

The assistant runs on the user's local machine (its R session is local), not on the
cluster. It writes and reviews scripts and can run local syntax checks or small tests,
but module names, library paths, forked parallelism (`mclapply` on Linux), core limits
and `future.batchtools` submission are untested until the user runs them on the cluster.
`parallelly::availableCores()` locally says nothing about the allocation. Ask the user
for cluster-side output.

**Requirement:** whenever information is needed that only the cluster can provide (R
module names, `.libPaths()`, installed packages, allocation, logs), stop and ask the
user to run the specific shell command(s), given in a code block, and paste back the
output. Do not guess or proceed on assumptions.

## Job script basics

- Run scripts with `Rscript script.R` (non-interactive). `R CMD BATCH script.R` also
  works and writes `script.Rout`, but Rscript is simpler and more portable. Add
  `--vanilla` only if you want to ignore `.Rprofile`/`.Renviron`; it also skips
  `R_LIBS_USER` from `~/.Renviron`.
- `module purge`, then load the R module; load the same extra modules (compilers,
  GSL, Java, ...) at run time that you loaded when installing packages.
- Pass parameters with `commandArgs(trailingOnly = TRUE)` and the task ID with
  `as.integer(Sys.getenv("SLURM_ARRAY_TASK_ID"))`.
- Templates: [assets/r-job.sh](assets/r-job.sh), [assets/r-array.sh](assets/r-array.sh),
  [assets/r_hpc_skeleton.R](assets/r_hpc_skeleton.R)

## Package libraries

- Install packages once, **before** the jobs, from a login node or an interactive
  allocation (sites differ: some forbid installs on login nodes, others require them;
  check the profile). Compute nodes often have no internet.
- Set a personal/project library with `R_LIBS_USER` in `~/.Renviron` or the job script,
  separate per R minor version (`%v`/`%V` expand to the version). Never set library paths
  in `~/.Rprofile`; it should be version-independent.
- For reproducible project libraries use `renv` (restore on the login node, then point
  jobs at the project library).
- Compiled packages are built for the CPU they were installed on. On clusters with mixed
  CPU generations, a package built on one node type may crash with "illegal instruction"
  on another; build on the oldest architecture or pin jobs with `--constraint`.
- Running package installs inside array tasks races on the shared library (see
  `hpc-job-scripts` references/arrays-and-scratch.md). Install first, run second.

## Parallelism: match the allocation

- **Do not use `parallel::detectCores()`**: it returns all CPUs on the node, not those
  allocated to the job. Use `parallelly::availableCores()` (or `future::availableCores()`),
  which honours Slurm, or read `SLURM_CPUS_PER_TASK` with a default.
- Worker counts: `mclapply(mc.cores = n)`, `makeCluster(n)`, `registerDoParallel(n)`,
  `plan(multisession, workers = n)` with `n = availableCores()`.
  `BiocParallel` is not Slurm-aware and defaults to most CPUs on the node: set
  `MulticoreParam(workers = n)` explicitly.
- Threaded BLAS multiplies with worker processes. For many independent single-thread
  calculations use `OMP_NUM_THREADS=1` (and `OPENBLAS_NUM_THREADS`/`MKL_NUM_THREADS`);
  for one vectorised job set them to `$SLURM_CPUS_PER_TASK`. Check which BLAS R uses
  with `sessionInfo()`.
- Forked workers (`mclapply`, `%dopar%` with doMC) multiply memory use; budget `--mem`
  for the parent plus workers and measure `MaxRSS`. `mclapply` does not fork on Windows.
- Parallel efficiency often drops with more cores (one published test: 12 cores gave
  3.2x). Run a short scaling test before requesting many CPUs.
- For many independent tasks prefer a job array with one task per index, or
  `targets`/`future.batchtools` below, over one huge multi-node R process.

## Reproducible parallel random numbers

- Use `RNGkind("L'Ecuyer-CMRG")` with `parallel::mclapply(mc.set.seed = TRUE)` or
  `clusterSetRNGStream`, or `future.seed = TRUE` with the future ecosystem (`%dofuture%`
  needs `.options.future = list(seed = TRUE)`). Setting different plain seeds per worker
  does not guarantee non-overlapping streams.
- In arrays, derive the base seed from the task ID and log it.

## Output, logging, checkpoints

- `message()` writes to stderr (unbuffered); `print`/`cat` go to stdout. Use `message()`
  with a timestamp for progress; log a header (host, job/task ID, `sessionInfo()`, seed)
  and a footer. Do not print large objects; save results with `saveRDS`/`arrow`/`fst`.
- Close graphics: use a file device (`pdf()`, `png(type = "cairo")`); there is no display
  in batch jobs. `options(bitmapType = "cairo")` helps when X11 is missing.
- Base R cannot trap `SIGUSR1`, so rely on frequent, small checkpoints: process work in
  chunks, write each result atomically (`saveRDS(x, tmp); file.rename(tmp, final)`), and
  skip chunks whose result already exists on restart. Pipelines built with `targets`
  skip completed targets in the same spirit.
- Never write all tasks' results into one shared file; per-task files, merge later.

## Submitting jobs from R (future.batchtools, clustermq, rslurm, slurmR)

- These packages generate many Slurm jobs on your behalf. Check the site's job-count
  and array policies first. `future.batchtools::batchtools_slurm` limits queued workers
  with `workers` (default 100) and takes per-job `resources = list(time=, mem=, ncpus=,
  modules=, ...)`; match them to measured needs.
- Run the controlling R session in a light interactive/batch job or a persistent
  session (screen/tmux) per site rules, not as a heavy process on the login node.
- Do not nest parallel layers blindly (batchtools outer, multisession inner) without
  matching `--cpus-per-task`/`ntasks` to the inner workers.

## Review checklist

- [ ] `Rscript` batch job; same modules at install and run time
- [ ] `R_LIBS_USER` set (per R version); packages installed before the job
- [ ] Workers from `availableCores()` / `SLURM_CPUS_PER_TASK`; BLAS threads set
- [ ] Parallel-safe RNG; seed derived from task ID and logged
- [ ] Per-task outputs, atomic writes, skip-if-done
- [ ] File graphics devices only; progress via `message()`
- [ ] Memory budget includes forked workers; scaling checked

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were done or not done: why this method, setting or tool was chosen, which alternative was rejected and why, which check or step was skipped, and which assumptions were made. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a package version or API differs from what it states, or it lacks guidance the task needs, record a generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
