#!/bin/bash
#SBATCH --job-name=rarray
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --array=1-100%20
#SBATCH --output=logs/%x_%A_%a.out
# One task per index; each writes its own result file (no shared files, no races).
# SITE: add --account/--partition; check the site's array limits.

set -euo pipefail

module purge
# module load R/<version>

export OMP_NUM_THREADS=1             # single-threaded R per task
export OPENBLAS_NUM_THREADS=1

echo "array=$SLURM_ARRAY_JOB_ID task=$SLURM_ARRAY_TASK_ID host=$(hostname) start=$(date)"

# The R script reads SLURM_ARRAY_TASK_ID itself, skips finished tasks, and writes atomically
Rscript my_task.R --task "$SLURM_ARRAY_TASK_ID"

echo "end=$(date)"
