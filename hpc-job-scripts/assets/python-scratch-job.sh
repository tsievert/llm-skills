#!/bin/bash
#SBATCH --job-name=scratchjob
#SBATCH --time=12:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --signal=B:USR1@300
#SBATCH --open-mode=append
#SBATCH --output=logs/%x_%j.out
# Node-local scratch with periodic sync-out. Confirm the scratch variable, purge policy
# and KillWait for your cluster (hpc-cluster-docs) and adjust the lines marked SITE.

set -euo pipefail
module purge
# module load <site python module>  OR  activate your conda/venv here

export OMP_NUM_THREADS=1
export PYTHONUNBUFFERED=1

# SITE: persistent destination and node-local scratch (variable names differ per cluster)
PERSIST="${PERSIST_DIR:-$SLURM_SUBMIT_DIR/results/$SLURM_JOB_NAME}"
LOCAL="${SLURM_SCRATCH:-${TMPDIR:-/tmp}}/${USER}_${SLURM_JOB_ID}"
SYNC_EVERY="${SYNC_EVERY:-1800}"          # seconds between periodic syncs
mkdir -p "$PERSIST" "$LOCAL/out"

sync_out() {
  echo "sync $(date +%T): $LOCAL/out -> $PERSIST"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --partial "$LOCAL/out/" "$PERSIST/"
  else
    cp -a "$LOCAL/out/." "$PERSIST/"
  fi
}

# Resume: restore earlier checkpoints/results (job was requeued or resubmitted)
if [ -n "$(ls -A "$PERSIST" 2>/dev/null)" ]; then
  echo "restoring previous state from $PERSIST"
  cp -a "$PERSIST/." "$LOCAL/out/"
fi

# Periodic sync in the background
( while sleep "$SYNC_EVERY"; do sync_out || echo "periodic sync failed"; done ) &
SYNC_PID=$!

child=""
cleanup() {
  kill "$SYNC_PID" 2>/dev/null || true
  # Delete scratch only if the final sync succeeded; otherwise keep it for a later attempt
  if sync_out; then
    rm -rf "$LOCAL"
  else
    echo "FINAL SYNC FAILED; leaving $LOCAL in place"
  fi
}
trap cleanup EXIT

on_usr1() {
  echo "USR1 at $(date +%T): asking program to checkpoint"
  [ -n "$child" ] && kill -USR1 "$child" 2>/dev/null || true
  wait "$child" 2>/dev/null || true
  exit 0                                   # EXIT trap performs the final sync
}
trap on_usr1 USR1

echo "job=$SLURM_JOB_ID host=$(hostname) start=$(date) local=$LOCAL"

# Run in the background and wait so bash can run traps while the program runs
python my_script.py --out "$LOCAL/out" &
child=$!
wait "$child"
echo "end=$(date)"
