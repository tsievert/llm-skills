#!/bin/bash
# Runs the targets main process as one small batch job; crew.cluster submits the workers.
# Fill the <PLACEHOLDER> values from the site documentation, and create logs/ before sbatch:
#   mkdir -p logs && sbatch slurm/run_targets.sbatch
#SBATCH --job-name=targets-main
#SBATCH --partition=<PARTITION>
#SBATCH --account=<ACCOUNT>
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=<WALLTIME>
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err

set -euo pipefail

# module load R/<VERSION>
# Restore packages on a login node first (compute nodes are often offline): Rscript -e 'renv::restore()'

export PIPELINE_EXECUTOR=slurm
Rscript -e 'targets::tar_make(reporter = "timestamp")'
