# Job arrays, race conditions, and node-local scratch

## Contents
- Race conditions in arrays and parallel jobs
- Node-local scratch: stage in, work, sync out
- Periodic sync so cancelled jobs keep their progress
- Checks against the cluster docs

## Race conditions in arrays and parallel jobs

Array tasks (and any concurrently running jobs) run at the same time on shared
filesystems. Anything two tasks touch together is a potential race.

**Rules**

1. **One writer per path.** Give every task its own output paths, keyed by
   `$SLURM_ARRAY_TASK_ID` (results, logs, temp files, checkpoints, caches). Merge
   afterwards in a dependent job:
   `sbatch --dependency=afterok:<array_jobid> merge.sh` (waits for all tasks).
2. **Never append to one shared file** (CSV, log, JSONL) from many tasks. Interleaved
   or lost writes result; write per-task files and merge. This also applies to `>>`
   in the script.
3. **Make writes atomic.** Write to `name.tmp.<taskid>` in the same directory, then
   rename (`mv`, `os.replace`, R `file.rename`). Readers then see either the old or
   the complete new file, never a partial one. If every task computes identical
   content, atomic replace is enough and no locking is needed ("last writer wins").
4. **Avoid check-then-create.** `if [ ! -e f ]; then create f; fi` lets two tasks both
   pass the check. Use an atomic primitive instead: `mkdir lockdir` (succeeds for
   exactly one caller), `ln -s`, or rename. Locks on network filesystems vary:
   `flock`/`fcntl` need a filesystem that supports them (e.g. Lustre, GPFS, NFSv4
   in some configurations); check the cluster docs before relying on them, and
   prefer designs that need no locks.
5. **Do not share mutable state across tasks:** SQLite files, pickles updated in
   place, shared caches (Hugging Face, pip, matplotlib config, R package library
   during `install.packages`), shared "work queue" files. Pre-populate read-only
   caches once before the array starts, or give each task its own cache dir.
6. **Shared inputs are read-only.** Hundreds of tasks reading the same large file at
   once can saturate the filesystem; stage once to node-local scratch (below) and
   throttle the array (`--array=0-999%20`).
7. **Done markers must be atomic and per-task.** `touch results/task_$ID.done` after
   the result file is fully renamed into place; check it on start so reruns skip
   finished work. Never treat the existence of a partially written result as "done".
8. **Seeds:** derive from the task ID so tasks do not duplicate random streams.
9. **Ports and names:** do not pick fixed or random ports/IDs that could collide with
   other jobs on the same node (see `hpc-gpu-jobs` for `MASTER_PORT`).
10. **Resubmits and requeues:** a requeued or resubmitted task may overlap a zombie
    of itself. Include `$SLURM_JOB_ID` in temp dirs and use atomic renames for finals.

Minimal pattern (bash):

```bash
OUT="results/task_${SLURM_ARRAY_TASK_ID}.csv"
[ -e "$OUT" ] && { echo "done already"; exit 0; }
python run.py --task "$SLURM_ARRAY_TASK_ID" --out "$OUT.tmp"
mv "$OUT.tmp" "$OUT"          # atomic within one filesystem
```

## Node-local scratch: stage in, work, sync out

Why: node-local disk (SSD/NVMe) avoids the shared filesystem for temporary and
many-small-file workloads and does not load the network. The catch: it is private to
one node and **deleted when the job ends or is cancelled**; the site cannot recover it.

Pattern: copy inputs to local scratch, run there, copy results to persistent storage
(home/project/shared scratch) before exit.

Facts to check in the cluster docs (names differ per site):

- Variable/path: `$TMPDIR`, `$SLURM_SCRATCH`, `/scratch/...`, `/local/...`, or `/tmp`
  mapped per job. Slurm does not change `$TMPDIR` by default on every site.
- Local vs shared: some sites provide both (for example a node-local `$TMPDIR` and a
  per-job shared `$SCRATCH`). Multi-node jobs need a shared path.
- Size, whether you must request local disk (e.g. `--tmp=`), and the purge policy.
- Whether RAM-backed `/tmp` or `/dev/shm` counts against the job's memory limit.

Rules:

- Create a per-job directory including `$SLURM_JOB_ID`; clean it at exit.
- Bundle many small files (`tar`) before copying; copy once rather than file by file.
- rsync writes each file to a temp name and renames it, so a copy interrupted
  mid-file does not leave a truncated destination file (unless `--inplace` is used).
- Never keep the only copy of a checkpoint on node-local disk.

## Periodic sync so cancelled jobs keep their progress

Three layers, strongest first. Use at least the first two for long jobs.

1. **Periodic background sync** (survives crashes and SIGKILL up to the last sync):
   a loop copies the local work dir to persistent storage every N minutes.
2. **Signal-triggered sync**: `--signal=B:USR1@300` plus a trap that stops/asks the
   program to checkpoint and then syncs. Gives an early warning before the time limit.
3. **EXIT trap**: `trap cleanup EXIT` runs a final sync when the script exits, which
   normally includes cancellation and timeout. The window after the time limit is
   short (SIGTERM, then SIGKILL after `KillWait`; check
   `scontrol show config | grep KillWait`), so keep the final sync small by syncing
   periodically, and test the trap (`scancel <jobid>` on a short job) on your cluster.

Template: [assets/python-scratch-job.sh](../assets/python-scratch-job.sh)

Details to get right:

- Kill the background sync loop in the exit handler and do not let two syncs overlap.
- Sync only what is needed (checkpoints, results), not the whole scratch tree.
- Pick the interval from the cost of recomputing versus the cost of copying
  (typically 10-60 minutes).
- Log every sync (time and size) so the job log shows what was preserved.
- A sync is not a checkpoint: files must be consistent when copied. Programs should
  write atomically (temp file then rename) so a sync never captures a half-written file.

## Checks against the cluster docs

Before using scratch or arrays, confirm in the cluster profile (`hpc-cluster-docs`):
scratch path and purge policy, local-vs-shared semantics, `KillWait`, array limits
(`MaxArraySize`, per-user job caps), and whether `flock` works on the shared filesystem.
