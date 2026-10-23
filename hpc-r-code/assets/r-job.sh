#!/bin/bash
#SBATCH --job-name=rjob
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=logs/%x_%j.out
# SITE: add --account/--partition from the cluster profile. Create logs/ before sbatch.

set -euo pipefail

module purge
# module load R/<version>   # plus any modules that were loaded when installing packages

# Personal library per R version, set before R starts (or put it in ~/.Renviron)
# export R_LIBS_USER="$HOME/R/%v"

# Multithreaded BLAS: one vectorised job -> all CPUs; many forked workers -> set to 1 here
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK:-1}"
export OPENBLAS_NUM_THREADS="$OMP_NUM_THREADS"

echo "job=$SLURM_JOB_ID host=$(hostname) start=$(date) cpus=${SLURM_CPUS_PER_TASK:-1}"

Rscript my_script.R --n-items 200

echo "end=$(date)"
