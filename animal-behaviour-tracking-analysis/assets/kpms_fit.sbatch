#!/bin/bash
#SBATCH --job-name=kpms-fit
#SBATCH --time=12:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --gres=gpu:1
#SBATCH --array=0-0
#SBATCH --output=logs/%x_%A_%a.out
# SITE: add --account/--partition and the GPU syntax from the cluster profile (hpc-cluster-docs).
# One task = one model fit on one GPU. Never let two tasks share a GPU: JAX preallocates most of the
# GPU memory per process. For restarts / model selection use e.g. --array=0-19%4 (seed = task id).
# The fit script resumes from its last checkpoint, so after a time-limit kill just resubmit
# the same script; no requeue logic is needed.

set -euo pipefail

module purge
# module load <site python module>  OR  source /path/to/kpms-venv/bin/activate   (env built beforehand)

export MPLBACKEND=Agg
export PYTHONUNBUFFERED=1
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK:-1}"

PROJECT=/path/to/storage/kpms_project          # created by the --prepare-only run; must not exist before it
SEED="${SLURM_ARRAY_TASK_ID:-0}"
MODEL="run_seed${SEED}"

echo "job=${SLURM_JOB_ID:-local} task=${SLURM_ARRAY_TASK_ID:-0} host=$(hostname) start=$(date)"

# Fail fast if JAX cannot see the GPU instead of silently fitting on CPU
python - <<'PY'
import sys, jax
print("jax", jax.__version__, "backend:", jax.default_backend(), "devices:", jax.devices())
sys.exit(0 if jax.default_backend() == "gpu" else 1)
PY

# Array tasks share PROJECT. Prepare it once BEFORE submitting the array (login/interactive node, or a
# separate job): python kpms_headless_fit.py <same args> --model-name x --prepare-only. Tasks then
# add their own model folder (config and PCA are reused; cheap preprocessing is repeated per task).
python kpms_headless_fit.py \
  --project-dir "$PROJECT" \
  --keypoints-dir /path/to/dlc_output \
  --use-bodyparts nose head spine1 spine2 spine3 \
  --anterior nose --posterior spine3 \
  --fps 30 \
  --model-name "$MODEL" --seed "$SEED"

echo "end=$(date)"
