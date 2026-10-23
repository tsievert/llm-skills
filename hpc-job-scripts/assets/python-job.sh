#!/bin/bash
#SBATCH --job-name=myjob
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=logs/%x_%j.out
# Add site-specific lines from the cluster profile, e.g.:
# #SBATCH --account=<account>
# #SBATCH --partition=<partition>
# For requeueable jobs also add: --signal=B:USR1@300, --requeue, --open-mode=append

set -euo pipefail

# Create logs/ BEFORE sbatch; Slurm opens the log file before this script runs.

module purge
# module load <site python module>  OR  activate your conda/venv here

# Match thread/process counts to the allocation (unset if --cpus-per-task omitted)
export NCORES="${SLURM_CPUS_PER_TASK:-1}"
export OMP_NUM_THREADS=1          # avoid processes x BLAS threads oversubscription
export PYTHONUNBUFFERED=1         # live log output

echo "job=$SLURM_JOB_ID host=$(hostname) start=$(date) cwd=$PWD"
echo "python=$(python --version 2>&1) cores=$NCORES"
git rev-parse --short HEAD 2>/dev/null | sed 's/^/git=/' || true

python my_script.py --n-workers "$NCORES"

echo "end=$(date)"
