#!/bin/bash
# DLC training, one GPU. Adapt partition, GPU syntax and env activation to the site,
# create logs/ before submitting, and lint with hpc-job-scripts/scripts/check_sbatch.sh.
#SBATCH --job-name=dlc-train
#SBATCH --gres=gpu:1            # site-specific
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --output=logs/%x-%j.out

set -euo pipefail
source /path/to/venv/bin/activate   # env created beforehand
export MPLBACKEND=Agg
python train_dlc.py --config /path/to/project/config.yaml --shuffle 1
