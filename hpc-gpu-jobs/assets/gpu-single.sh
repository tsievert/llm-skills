#!/bin/bash
#SBATCH --job-name=gpujob
#SBATCH --time=04:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --gres=gpu:1
#SBATCH --output=logs/%x_%j.out
# SITE: add --account/--partition and the GPU type syntax from the cluster profile.
# For long jobs add: --signal=B:USR1@300, --requeue, --open-mode=append and the trap pattern
# from hpc-job-scripts/references/checkpoint-requeue.md.

set -euo pipefail

module purge
# module load <site CUDA/python modules>  OR  activate your conda/venv here

export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK:-1}"
export PYTHONUNBUFFERED=1

echo "job=$SLURM_JOB_ID host=$(hostname) start=$(date)"
echo "CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-unset}"
nvidia-smi

# Fail fast if no GPU is visible instead of silently running on CPU
python - <<'PY'
import sys, torch
ok = torch.cuda.is_available()
print("cuda available:", ok, "| torch cuda:", torch.version.cuda)
sys.exit(0 if ok else 1)
PY

# Background GPU utilisation log, stopped at exit
nvidia-smi --query-gpu=timestamp,index,utilization.gpu,memory.used,memory.total \
  --format=csv -l 30 -f "logs/gpu_${SLURM_JOB_ID}.csv" &
GPU_MON=$!
trap 'kill $GPU_MON 2>/dev/null || true' EXIT

# num_workers in the DataLoader should be about --cpus-per-task; verify GPU utilisation
python train.py --num-workers "${SLURM_CPUS_PER_TASK:-1}"

echo "end=$(date)"
