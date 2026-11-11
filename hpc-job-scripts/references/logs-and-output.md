# Logs and console output on Slurm

## Contents
- Where output goes
- Naming and layout
- Silent failures
- Inspecting jobs
- Reading a partly emptied queue
- What to log

## Where output goes

- Default: stdout and stderr both go to `slurm-%j.out` (arrays: `slurm-%A_%a.out`)
  in the directory `sbatch` was run from, created on the first allocated node.
- Set `--output` and `--error` to split streams. Without `--error`, stderr shares the output file.
- `--open-mode=append|truncate`: the default depends on the site's `JobFileAppend`
  setting. Use `append` for requeueable jobs so a restart does not wipe earlier output.
- Filename patterns: `%j` job id, `%A` array master id, `%a` array index, `%x` job
  name, `%u` user, `%N` short hostname (creates one file per node), `%t` task rank
  (one file per task), `%%` literal percent. `%4j` zero-pads. In job-array logs use `%A_%a`.

## Naming and layout

- Pattern: `logs/%x_%j.out` for single jobs, `logs/%x_%A_%a.out` for arrays.
- Prefer one directory per campaign (`logs/<experiment>/`) to keep `ls` usable.
- The job ID is preserved across requeues, so one file captures all attempts when
  `--open-mode=append` is set.
- Keep logs on a filesystem with enough quota; home directories are often small.

## Silent failures

- If the directory in `--output`/`--error` does not exist, Slurm cannot open the file
  and the job fails with no output visible to the user (SchedMD ticket 8895; the
  error appears only in the node's slurmd log). A `mkdir -p` inside the script is too
  late because Slurm opens the file before the script runs.
- Diagnose: `scontrol show job <id>` (while still known) shows `StdOut=`/`StdErr=`
  paths and a failed state; `sacct -j <id> --format=JobID,State,ExitCode,Elapsed`
  works after the job ends.
- Prevent: create directories in the submission wrapper, or run
  `bash scripts/check_sbatch.sh job.sh` which warns about missing directories.

## Inspecting jobs

```bash
squeue --me                                  # pending/running
scontrol show job <id>                       # paths, reason, nodes, requested resources
sacct -j <id> --format=JobID,JobName,State,ExitCode,Elapsed,AllocCPUS,ReqMem,MaxRSS
tail -f logs/<name>_<id>.out                 # follow live (needs unbuffered Python)
sacct -j <id> -B                             # batch script as submitted (if enabled)
```

## Reading a partly emptied queue

- Tasks that leave `squeue` before your runtime estimate are usually finished, not failed. One report: a 40-task array showed 22 tasks after about 70 min; `sacct` showed all COMPLETED, exit code 0, and the result files existed. Check first: `sacct -j <id> -X --format=JobID,State,ExitCode,Elapsed`, and count the result files.
- Use `seff <jobid>` (or a per-task `sacct` without `-X`) for memory: `sacct -X` shows empty MaxRSS and TotalCPU because the allocation row has no job steps. In the same report the memory guess was 6 GB and the real use 1.1 GB.
- `--output`/`--error` and relative result paths resolve against the submission directory. When asking the user to run follow-up commands, include `cd "$BASE"` (the submission directory) first; from the home folder the log and result folders do not exist.
- A single-thread laptop smoke run can over- or underestimate cluster runtime by 20-30% (one report: 80-100 min locally, 60-75 min on the cluster). Treat it as a range, not a request value.

## What to log

- Header: job ID, array task ID, host, date, working directory, `module list`,
  Python and package versions, git commit, the full command line and config.
- Progress at a coarse cadence (every N iterations or every few minutes), not every
  step. Flushing every line costs performance.
- Warnings and errors with context (which input, which task ID), with a stack trace
  on failure (Python `logging.exception`).
- Footer: end time, elapsed time, exit status. Makes truncated logs obvious.
- Results go to data files (parquet/npz/CSV), not stdout.
- Do not print secrets or tokens; logs are often world-readable.
