# Checkpoint, signal, and requeue pattern (Slurm)

## Contents
- How the pieces fit
- Wrapper script
- Rules
- Testing

## How the pieces fit

1. `--signal=B:USR1@300` makes Slurm send SIGUSR1 to the **batch shell** about 5 minutes
   before the time limit (the `B:` prefix; without it job steps are signalled instead
   of the shell). Slurm may send it up to 60 s earlier than requested.
2. A `trap` in the script forwards the signal to the Python process.
3. Python (see `hpc-python-code`) writes an atomic checkpoint and exits with a
   dedicated code.
4. The script requeues itself (`scontrol requeue $SLURM_JOB_ID`) or exits with the
   code the site uses for requeue. On the next start, the script finds the latest
   checkpoint and resumes.

A preempted job is normally requeued by Slurm automatically when requeue is allowed,
but a job that hit its time limit is not requeued automatically, so the script must
request it. Whether preemption sends a signal depends on the site's configuration
(`PreemptParameters`); check the cluster profile. Some sites also require a specific
exit code for requeue.

## Wrapper script

```bash
#!/bin/bash
#SBATCH --job-name=train
#SBATCH --time=12:00:00
#SBATCH --signal=B:USR1@300
#SBATCH --requeue
#SBATCH --open-mode=append
#SBATCH --output=logs/%x_%j.out

set -euo pipefail
module purge
module load python   # replace with the site's module / env activation

CKPT_DIR="${SCRATCH:-$PWD}/checkpoints/${SLURM_JOB_NAME}_${SLURM_JOB_ID}"
mkdir -p "$CKPT_DIR"
echo "start $(date) host=$(hostname) restart=${SLURM_RESTART_COUNT:-0}"

child=""
on_usr1() {
  echo "USR1 at $(date): asking Python to checkpoint"
  [ -n "$child" ] && kill -USR1 "$child" 2>/dev/null || true
  wait "$child" || true
  echo "requeueing job $SLURM_JOB_ID"
  scontrol requeue "$SLURM_JOB_ID"
  exit 0
}
trap on_usr1 USR1

# Run in background + wait: bash only runs traps between foreground commands.
python -u train.py --ckpt-dir "$CKPT_DIR" --resume auto &
child=$!
wait "$child"
echo "done $(date)"
```

Why `&` + `wait`: a trap does not run while a foreground command executes; with
`wait`, the signal interrupts the wait immediately.

If Python uses `multiprocessing`/`joblib`, launch it in its own process group
(`setsid`) and signal the group, and make workers ignore SIGUSR1 so only the parent
coordinates the checkpoint (see `hpc-python-code`).

## Rules

- Store checkpoints on persistent shared storage, not node-local temp paths.
- Include `$SLURM_JOB_ID` in the checkpoint path so same-named jobs do not resume
  each other's state; the ID is preserved across requeues.
- Checkpoint often enough that the work between checkpoints fits inside the grace
  window (5 minutes above). If one step takes longer, checkpoint per step.
- Write atomically (temp file, then rename).
- Make "already finished" a no-op: write a completion marker so resubmitting does not redo work.
- Do not rely on `--requeue` alone; it restarts the script from line 1.

## Testing (do this in the daytime, with a short job)

```bash
sbatch short_test.sh
scancel --signal=USR1 --batch <jobid>   # simulate the warning without killing the job
```

Confirm a checkpoint appears, the job requeues, and the second run resumes from it
(`SLURM_RESTART_COUNT` increments).
