#!/bin/bash
#SBATCH --job-name=gpu4
#SBATCH --time=12:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --gres=gpu:4
#SBATCH --output=logs/%x_%j.out
# One node, several GPUs, one task, torchrun spawns one process per GPU.
# Do NOT add --gpus-per-task here (each worker would see a single GPU).
# SITE: add --account/--partition/GPU type. Multi-node: see references/multi-gpu.md.

set -euo pipefail

module purge
# module load <site CUDA/python modules>  OR  activate your conda/venv here

NGPUS="${SLURM_GPUS_ON_NODE:-4}"        # verify with: echo $SLURM_GPUS_ON_NODE
export OMP_NUM_THREADS=$(( ${SLURM_CPUS_PER_TASK:-4} / NGPUS ))
export PYTHONUNBUFFERED=1
export NCCL_DEBUG=WARN

echo "job=$SLURM_JOB_ID host=$(hostname) gpus=$NGPUS start=$(date)"
nvidia-smi -L

# --standalone picks a free local rendezvous port, avoiding collisions with other jobs
torchrun --standalone --nproc_per_node="$NGPUS" train.py \
  --num-workers "$OMP_NUM_THREADS"

echo "end=$(date)"
