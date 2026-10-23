---
name: hpc-python-code
description: Writes and reviews Python code that runs inside HPC batch jobs (Slurm and similar). Covers unbuffered output and the logging module, log and console output volume, matching multiprocessing/joblib/BLAS threads to the CPU allocation, job-array task IDs and seeds, SIGUSR1/SIGTERM handling, atomic checkpoints and resume, environments and file I/O on shared filesystems, and a tested Python skeleton. Use when the user asks for Python code, a training or analysis script, or parallelism that will run on a cluster, or reports missing/late log output, oversubscribed CPUs, or lost progress.
---

# Python on HPC

Run `hpc-cluster-docs` first if the cluster is unknown, and write the submission
script with `hpc-job-scripts`. This skill covers the Python side.

## Start from the skeleton

[assets/hpc_skeleton.py](assets/hpc_skeleton.py) is a working, stdlib-only template:
logging setup, allocation-aware worker count, signal handling, atomic checkpoint,
resume, and a completion marker. Adapt it rather than rewriting these parts.

## Console output and logging

- Python buffers stdout when it is not a terminal, so batch logs lag. Use
  `python -u`, `export PYTHONUNBUFFERED=1`, or `print(..., flush=True)`. Unbuffered I/O
  costs some performance: keep progress messages sparse in production runs.
- Use the `logging` module, not bare `print`, for anything beyond a one-off:
  timestamps, levels, and task IDs make interleaved logs readable. Log to stdout
  (Slurm captures it) and let the scheduler own the file.
- Log a header (host, job/array IDs, versions, config, git commit, seed) and a
  footer (elapsed, status). Log exceptions with `logging.exception` so the traceback
  lands in the job log.
- Keep volume low: no per-item prints in large loops, no progress bars (they emit
  carriage returns into log files; disable `tqdm` or use a large `mininterval`).
  Write results to files (parquet/npz/CSV), not stdout.
- Details and a logging snippet: [references/logging-and-console.md](references/logging-and-console.md)

## CPU parallelism: match the allocation

- The allocation is `SLURM_CPUS_PER_TASK` (set only if `--cpus-per-task` was given).
  Read it with a default: `int(os.environ.get("SLURM_CPUS_PER_TASK", 1))`.
  `os.cpu_count()` reports the whole node, not your share; using it oversubscribes.
- Pool/joblib/`concurrent.futures` workers = allocation. Threads in BLAS/OpenMP
  libraries multiply on top: with multiprocessing set `OMP_NUM_THREADS=1`
  (also `MKL_NUM_THREADS`, `OPENBLAS_NUM_THREADS`) before importing numpy, or an
  N-process pool where each process spawns N threads runs N x N threads on N cores.
- If the code is single-threaded, request 1 CPU; extra CPUs are wasted and lower
  future job priority.
- For many independent tasks, prefer a job array (one task per `SLURM_ARRAY_TASK_ID`)
  over a Python pool across nodes. Derive seeds and input selection from the task ID.

## Robustness on shared clusters

- **Signals and checkpoints.** Handle SIGUSR1 (pre-timeout/preemption warning) and
  SIGTERM: set a flag in the handler, checkpoint at the next safe point, exit.
  Keep the handler minimal. Workers in `multiprocessing`/`joblib` must ignore SIGUSR1
  so only the parent checkpoints. `signal.SIGUSR1` does not exist on Windows; guard with `hasattr`.
  Script side: `hpc-job-scripts` references/checkpoint-requeue.md.
- **Atomic writes.** Write to `path.tmp`, then `os.replace(tmp, path)`, so a kill
  mid-write cannot corrupt the previous checkpoint or result.
- **Idempotence.** Skip work whose output already exists; write a completion marker.
- **Reproducibility.** Seed explicitly (task ID or config), record package versions
  and the git commit in the log, and do not depend on the CWD (use paths from args/env).
- **Environments.** Build environments before the job on a login node or via the
  site's module/container system. Do not `pip install` inside job scripts; compute
  nodes often have no internet. Confirm the site's Python policy in the cluster profile.
- **Filesystem.** Shared/parallel filesystems handle many small files badly.
  Write fewer, larger files (shards, HDF5/zarr/parquet), keep hot data on node-local
  `$TMPDIR`/scratch where allowed, and copy final results to persistent storage before
  the job ends. Do not put checkpoints only on node-local storage.
- **Races in arrays.** One writer per path: per-task output files keyed by
  `SLURM_ARRAY_TASK_ID`, atomic rename, no appends to shared files, per-task caches;
  merge afterwards. See `hpc-job-scripts` references/arrays-and-scratch.md.
- **Node-local scratch.** Write hot/temporary data to the job's scratch dir and copy
  results and checkpoints to persistent storage periodically and at exit; scratch is
  deleted when the job ends. Template: `hpc-job-scripts` assets/python-scratch-job.sh.
- **GPUs.** See the `hpc-gpu-jobs` skill (launch patterns, DataLoader workers,
  monitoring). Check `torch.cuda.is_available()` and fail fast if no GPU is visible.

## Review checklist

- [ ] Output unbuffered or flushed; logging configured; header/footer logged
- [ ] Worker count derived from `SLURM_CPUS_PER_TASK`, threads capped
- [ ] Seeds explicit; versions and git commit logged
- [ ] SIGUSR1/SIGTERM handled; atomic checkpoint; resume path tested
- [ ] Results written to files, stdout kept small
- [ ] No `pip install`, no hardcoded absolute user paths, no work on import
