---
name: hpc-job-scripts
description: Writes, reviews, and debugs HPC batch submission scripts (primarily Slurm sbatch; translates to PBS/LSF/SGE using site docs). Covers #SBATCH directives, log file and console output setup, job arrays, dependencies, requeue and signal handling, and a bundled linter that catches silent failures such as CRLF line endings or a missing output directory. Use when the user asks for a submission script, job script, sbatch file, array job, or asks why a cluster job failed, produced no output, or was killed.
---

# HPC job submission scripts

Assumes the cluster is known. If not, run `hpc-cluster-docs` first. Slurm is used
below; for PBS/LSF/SGE keep the same structure and translate directives from the
site's docs.

## Workflow

1. Confirm cluster profile (`hpc-cluster-docs`) and size the request (`hpc-resource-allocation`).
2. Start from [assets/python-job.sh](assets/python-job.sh) (single job) or
   [assets/python-array.sh](assets/python-array.sh) (many similar tasks).
3. Lint: `bash scripts/check_sbatch.sh my_job.sh` (path relative to this skill's directory).
   Fix every ERROR; read WARN/INFO.
4. Tell the user to create the log directory **before** submitting, then test with
   `sbatch --test-only my_job.sh` (validates and estimates start; does not submit).
5. For first runs use a short time limit and small input, ideally in an interactive session.

## Script rules

- **Directives must come before the first executable line.** `#SBATCH` lines after
  the first command are ignored.
- Always set `--time` explicitly. Use `--mem` (per node) or `--mem-per-cpu`, never
  both (mutually exclusive). Check whether the site forbids `--mem` or requires `--account`/`--partition`.
- Start with `set -euo pipefail`, then `module purge` before `module load` so the
  environment is the same on every node.
- Request CPUs only if the code is parallel: `--cpus-per-task` for threads or
  processes, `--ntasks` only for MPI. Pass the count to the program via
  `$SLURM_CPUS_PER_TASK` (set only when `--cpus-per-task` was given; use a default).
- Never run compute on the login node; debug in an interactive allocation.
- Do not hardcode user paths, job IDs, or partition names that may change.
- Keep the script mostly directives + environment + one launch line; put logic in
  the program.
- Use job arrays instead of looping `sbatch`; cap concurrency with `--array=0-999%20`.
  Many sub-5-minute jobs should be batched into fewer, longer ones (scheduler
  overhead), and some sites cap or discourage arrays: check the profile.
- Chain stages with `sbatch --parsable` + `--dependency=afterok:<id>`; use
  `--kill-on-invalid-dep=yes` so failed upstream jobs do not leave pending jobs forever.
- Record provenance at start: job ID, host, date, `module list`, Python version,
  git commit, and the exact command/config.

## Logs and console output (summary)

- `--output`/`--error` default to `slurm-%j.out` in the submit directory
  (`slurm-%A_%a.out` for arrays). Stderr merges into the output file if `--error` is unset.
- **Slurm does not create missing log directories; the job then fails with no
  visible output.** `mkdir -p logs` before `sbatch`, never inside the script.
- Use patterns that make files unique and traceable: `logs/%x_%j.out`, arrays
  `logs/%x_%A_%a.out`. Patterns: `%j` job, `%A` array job, `%a` index, `%x` name, `%N` node.
- Keep stdout small. Large per-job stdout multiplied across arrays fills quotas;
  write results to data files and keep logs for progress, warnings, and errors.
- For requeueable jobs add `--open-mode=append` so restarts do not truncate the log.
- Details, `sacct`/`scontrol` inspection, and silent-failure diagnosis:
  [references/logs-and-output.md](references/logs-and-output.md)

## Arrays, race conditions, node-local scratch

- Concurrent tasks must never share a mutable file: one writer per path, per-task
  output names (`$SLURM_ARRAY_TASK_ID`), atomic writes (temp file + rename), no
  appends to a shared CSV/log, no check-then-create, merge in a dependent job
  (`--dependency=afterok:<arrayid>`).
- Node-local scratch (`$TMPDIR`, `$SLURM_SCRATCH`, ...) is fast but private to the node
  and deleted when the job ends or is cancelled. Stage in, work locally, and sync out
  **periodically** (background loop), on `USR1`, and in an `EXIT` trap, so a cancelled
  job keeps its progress. Look up the site's scratch variable, size, purge policy and
  `KillWait` first (`hpc-cluster-docs`).
- Details and template: [references/arrays-and-scratch.md](references/arrays-and-scratch.md),
  [assets/python-scratch-job.sh](assets/python-scratch-job.sh)

## Time limits, signals, requeue

- At the time limit tasks get SIGTERM, then SIGKILL after `KillWait`. Jobs that can
  lose work should checkpoint (see `hpc-python-code`) and use
  `--signal=B:USR1@300` (signal the batch shell 5 min early; delivery may be up to
  60 s early) with a `trap`, and `--requeue` where policy allows.
- A requeue restarts the script from line 1 with the same job ID
  (`$SLURM_RESTART_COUNT` counts restarts), so the script must detect and resume
  from existing checkpoints.
- Full wrapper pattern: [references/checkpoint-requeue.md](references/checkpoint-requeue.md)

## Gotchas

| Symptom | Likely cause |
|---|---|
| `bad interpreter: /bin/bash^M` or odd syntax errors | CRLF line endings from Windows; convert and set `*.sh text eol=lf` in `.gitattributes` |
| Job fails instantly, no log | Output directory missing; check `scontrol show job <id>` (`StdOut=`) |
| Job pending forever | Request exceeds partition limit, or wrong account/partition |
| Python output only appears at the end | Buffered stdout; see `hpc-python-code` |
| Job slower with more CPUs | Code is not parallel, or threads x processes oversubscribe |
| `$SLURM_CPUS_PER_TASK` empty | `--cpus-per-task` not set |
| Requeued job lost its progress | Script restarts from the top; no checkpoint resume logic |
| Results corrupted or missing rows in an array | Tasks append to / overwrite a shared file; use per-task files |
| Work on node-local disk vanished | Scratch is deleted at job end/cancel; sync out periodically |
| GPU job: see `hpc-gpu-jobs`; R job: see `hpc-r-code` | Dedicated skills |
