#!/bin/bash
#SBATCH --job-name=myarray
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --array=0-99%20
#SBATCH --output=logs/%x_%A_%a.out
# --array=START-END%N runs at most N tasks at once. Check the site's array limits.
# One task per line of inputs.txt (0-based index = $SLURM_ARRAY_TASK_ID).

set -euo pipefail

module purge
# module load <site python module>  OR  activate your conda/venv here

export OMP_NUM_THREADS=1
export PYTHONUNBUFFERED=1

INPUT=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" inputs.txt)
echo "array=$SLURM_ARRAY_JOB_ID task=$SLURM_ARRAY_TASK_ID input=$INPUT host=$(hostname) start=$(date)"

# Skip finished work so a rerun only does what is missing
OUT="results/task_${SLURM_ARRAY_TASK_ID}.done"
if [ -e "$OUT" ]; then echo "already done"; exit 0; fi

# Derive the seed from the task id for reproducible, distinct streams
python my_script.py --input "$INPUT" --seed "$SLURM_ARRAY_TASK_ID"

touch "$OUT"
echo "end=$(date)"
