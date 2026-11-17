---
name: deeplabcut-hpc
description: Sets up and runs DeepLabCut (DLC) pose estimation on HPC clusters and headless GPU machines - environment install, training and video-analysis batch scripts, pytorch_config.yaml settings, DLC failure modes and failed training logs. Use when the user mentions DeepLabCut, DLC, train_network, analyze_videos, pose_cfg.yaml, pytorch_config.yaml, or markerless pose estimation, esp. with Slurm or GPUs. Also use to retrain, resubmit, or build an orchestrator/sweep, benchmark suite or sbatch loop over DLC training or video-analysis scripts (shuffles, model variants), even if the request does not say "DeepLabCut" or "Slurm", to review or rank a benchmark JSON/export (even analysis-only), compare shuffles or net_type results, decide whether a model needs more epochs, or reproduce a DLC bug locally and draft an upstream issue. Combine with hpc-* skills. For metrics or statistics on the tracked output use animal-behaviour-tracking-analysis; for behavioural syllables use keypoint-moseq.
metadata:
  prompt_signals: 'deeplabcut|DeepLabCut|\banalyze_videos\b|\btrain_network\b|pytorch_config\.yaml|pose_cfg\.yaml|benchmark.{0,20}(json|export)|\bnet_type\b'
  file_signals: 'import deeplabcut|pytorch_config\.yaml|pose_cfg\.yaml|deeplabcut_version|test_mAP|training_state|evaluation_state|dlc_.*benchmark.*\.json|gpu_usage_.*\.csv'
---

# DeepLabCut on HPC

**Before writing or reviewing any submit command, sbatch loop or orchestrator, load `hpc-cluster-docs` and `hpc-job-scripts`** (details in Step 2). Reported once: both were skipped for an orchestrator task and the user had to ask whether all needed skills were loaded.

DeepLabCut changes quickly (3.0 made PyTorch the default and is deprecating TensorFlow; latest release 3.0.2 on 2026-09-23, checked 2026-10-29). **Do not rely on memory for function signatures or config keys.** Verify against the live docs first, then write code.

## Where this skill runs

The assistant runs only on the user's local machine, never on the cluster. It writes and reviews scripts, config and job files locally; the user copies them to the cluster, submits them and reports back. Consequences:

- Do not try to run `sbatch`, `squeue`, `nvidia-smi`, `torch.cuda.is_available()` and similar cluster-side checks. Give the user the exact command to run on the cluster and ask for the output.
- Ask the user for the cluster's DLC version (`python -c "import deeplabcut; print(deeplabcut.__version__)"`), PyTorch/CUDA versions and log excerpts instead of inspecting them. The local install, if any, may differ.
- Local tools (web fetch, `gh`, linting with `check_sbatch.sh`, syntax checks of Python) are available and should be used. Cluster-side commands in this file are instructions for the user, not for the assistant to execute.
- **Requirement:** whenever information is needed that only the cluster can provide, stop and ask the user to run the specific shell command(s), given in a code block, and paste back the output. Do not guess or proceed on assumptions.

## Step 1: Consult the official LLM entry point

Start at https://deeplabcut.github.io/DeepLabCut/llms.txt. It links to:

- `knowledge/manifest.json`: lists indexed API versions and which is current (`latest-release`).
- `knowledge/main/docs.jsonl`: one JSON object per doc page/section (`id, title, url, section, summary`). Large (~470 KB); fetch with a specific question, not whole.
- `knowledge/main/api.jsonl`: API symbols (`name, module, signature, summary`). The `latest-release` path for api.jsonl returned 404 in testing; use the version from the manifest instead (`knowledge/3.0.2/api.jsonl` worked on 2026-10-29) and fall back to `main`.
- API reference pages at `/dev/latest-release/reference/deeplabcut/`. The top-level page only indexes submodules; signatures live in `pose_estimation_pytorch/apis/training/` and `.../apis/videos/` (PyTorch) or `pose_estimation_tensorflow/...` (TF).

Useful doc pages: `docs/installation.html`, `docs/pytorch/pytorch_config.html`, `docs/pytorch/user_guide.html`, `docs/recipes/BatchProcessing.html`, `docs/docker.html`.

Match the docs to the cluster's DLC version. The docs do not cover Slurm/HPC; that part comes from this skill and the generic skills.

## Step 2: Load the generic skills

- `hpc-cluster-docs` first, for the site's modules, partitions and GPU syntax.
- `hpc-job-scripts`, `hpc-gpu-jobs`, `hpc-python-code`, `hpc-resource-allocation` for the job script, logging, checkpointing and sizing.

This skill only adds DLC specifics.

## Environment (3.0.2 docs, re-checked 2026-10-29: unchanged)

- Python 3.10-3.12.
- Headless install: plain `pip install deeplabcut` (no `[gui]` extra). Use `[gui]` only on a workstation for labeling. Extras: `[modelzoo]` for SuperAnimal models, `[tf]` for TensorFlow.
- Install PyTorch with CUDA **before** DLC, from the PyTorch index matching the cluster driver, for example `pip install torch torchvision --index-url https://download.pytorch.org/whl/cu126`. PyTorch bundles its own CUDA runtime, so a `module load cuda` is usually unnecessary; the driver must be new enough. Check on a GPU node: `python -c "import torch; print(torch.cuda.is_available())"` must print `True`.
- Install on a login node or in an interactive job, never inside the batch script. Use a venv/conda env on shared storage (see `hpc-python-code`). Many sites provide containers; Apptainer can pull the DLC Docker images (see `docs/docker.html`, terminal mode).
- TensorFlow engine: avoid for new work (deprecated). If the user must use it, pin TF to the extra matching their CUDA (`tf-cu11`/`tf-cu12`) and expect dependency conflicts with PyTorch.
- GPU: NVIDIA with >= 8 GB VRAM is the documented ideal. CPU training is roughly 10x slower, so do not run training on CPU nodes.
- When prototyping or testing locally with `uv`/a venv (not on the cluster) and the assistant's own `bash` calls can't find a `uv`/`python` that a separate terminal can see, this is usually a stale-PATH issue after install, not a missing install — see "uv/Python not found by the assistant's shell" in `python-reproducible-pipeline`'s environments-and-pinning reference.

## Workflow split: what runs where

| Step | Where |
|---|---|
| `create_new_project`, labeling (`label_frames`), `extract_frames` | Local workstation with GUI |
| `create_training_dataset`, `train_network`, `evaluate_network` | GPU node |
| `analyze_videos`, `create_labeled_video`, filtering/tracking | GPU node (analysis); labeled videos can run on CPU |

Copy the whole project folder (config.yaml, `dlc-models*`, `training-datasets`, `labeled-data`) to cluster storage. Upload videos separately.

## DLC-specific pitfalls to check in every script

Full detail for items marked (detail) is in [references/pitfall-details.md](references/pitfall-details.md).

1. **Absolute `project_path` in `config.yaml`.** A project created on another machine (e.g. Windows) has the wrong path. Fix it before running (`deeplabcut.auxiliaryfunctions.read_config` / `write_config`, as in the BatchProcessing recipe, or edit the YAML). In arrays, never let several tasks rewrite the same config.yaml; give each task its own copy or fix it once before submitting.
2. **No display on compute nodes.** Set `MPLBACKEND=Agg` in the job script, prefer `plotting=False` in `evaluate_network`, never launch the GUI.
3. **Engine selection.** `engine: pytorch` (or `tensorflow`) in `config.yaml` decides the engine of new training datasets. Confirm it before `create_training_dataset`.
4. **Training length is in epochs (PyTorch)**: `train_network(..., epochs=...)` or `train_settings.epochs`. Verify key names and defaults for the installed version; 3.0.2 code defaults differed from the docs in one report (detail).
5. **Dataloader workers.** Default 0 starves the GPU. Raise `dataloader_workers` to at most `--cpus-per-task` minus one, but more is not always faster; profile the main process before adding workers (detail).
6. **Batch size.** Raise `batch_size` to use GPU memory, confirmed by monitoring. GPU out-of-memory is fixed by smaller batch or image size, not more host memory.
7. **Checkpoint and resume.** Set `save_epochs` low enough that a time-limit kill loses little; resume with `resume_training_from` or `snapshot_path`. A resumed run treats `epochs` as additional epochs, so pass the remaining number in a requeue script (detail; see `hpc-job-scripts` for requeue and `--signal`).
8. **Shuffles, projects, GPUs.** One GPU per run by default; multi-GPU is single-node `DataParallel` and untested for scaling. Use job arrays with isolated output per task. Start shuffle numbering at 1, not 0 (detail).
9. **`analyze_videos` caching.** Already-analyzed videos are skipped, so reruns are cheap. Use `destfolder` for scratch/project storage; parallelise per video or folder as an array.
10. **Video I/O.** Decoding is CPU-bound; request enough CPUs. Stage large videos to node-local scratch when the shared filesystem is slow (see `hpc-job-scripts/references/arrays-and-scratch.md`).
11. **Model downloads.** Backbones and SuperAnimal weights download on first use, which fails on compute nodes without internet. Run one short model-creation step on a login node (or pre-download) and point the cache to shared storage if the home quota is small.
12. **Re-split and evaluation (2 sessions, not confirmed on a cluster).** After `create_training_dataset` or a re-split, `metadata.yaml` can record another engine and `evaluate_network` falls back to TensorFlow. Pass `engine=Engine.PYTORCH` and `shuffles=[n]` explicitly, treat old evaluation results as stale, and sync outputs per job path, since some files are written outside the shuffle folder (detail).

## Tuning `pytorch_config.yaml` and designing sweeps

Optimizer, scheduler, augmentation keys with their documented defaults, and what DLC does not expose (training mixed precision, gradient clipping, EMA, an open PR for arbitrary `albumentations` transforms) are in [references/pytorch-config-tuning.md](references/pytorch-config-tuning.md). Re-verify against the docs for the installed version before editing; keys drift. Training-script overrides go through `train_network(...)` arguments or `pytorch_cfg_updates`.

For a multi-candidate sweep, **exhaust the `net_type` axis before secondary knobs** (reported once, the user corrected this twice). The current architecture list, how to print it with `available_models()`, and orchestrator checks are in [references/training-sweeps.md](references/training-sweeps.md).

## Job script skeleton (training, one GPU)

Adapt to the site (partition, GPU syntax, env activation) after loading `hpc-cluster-docs` and `hpc-gpu-jobs`, and lint with `hpc-job-scripts/scripts/check_sbatch.sh`.

```bash
#!/bin/bash
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
```

```python
# train_dlc.py (sketch; check signatures in the live docs first)
import argparse, deeplabcut

ap = argparse.ArgumentParser()
ap.add_argument("--config", required=True)
ap.add_argument("--shuffle", type=int, default=1)
a = ap.parse_args()

deeplabcut.train_network(a.config, shuffle=a.shuffle)  # add epochs/batch_size etc. per docs
deeplabcut.evaluate_network(a.config, shuffles=[a.shuffle], plotting=False)
```

## When something fails: search upstream before improvising

DLC moves fast, so an unexpected error is often a known bug, a regression, or already fixed on `main`. Get the DLC version, engine, PyTorch/CUDA versions and the exact traceback from the user, then search issues, PRs, commits, releases and the forum before inventing a workaround. Report plainly whether a match is confirmed, only similar, or not found. A `False` from a feature-support check can also mean the fix merged to a non-default branch. Commands, option list and details: [references/upstream-search.md](references/upstream-search.md).

## Not verified

Written from the official docs only (re-checked against 3.0.2 docs and release notes on 2026-10-29; see `research/deeplabcut-hpc-ledger.md` in the llm-skills repo, which also holds the real-use evidence). Two local sessions reviewed scripts with `bash -n`, the sbatch linter and dry runs; nothing has run on a real cluster. If a command or key fails there, trust the live docs and the cluster version's `help()` output (ask the user to paste it) over this file, and say which part was wrong.

## Related skills

- `animal-behaviour-tracking-analysis`: what to do with the DLC output (likelihood masking, distance, speed, ROI time).
- `keypoint-moseq`: unsupervised behavioural syllables from the DLC keypoints.

## Explain the reasoning (teaching rule)

Teach, don't replace the user's thinking: say briefly (a sentence or two) why things were or were not done, name the trade-off and which decision is the user's, and point to a reference for depth.

## Capture lessons (self-improvement rule)

Load the `skill-lessons` skill and append a generic, anonymised entry (no project data, IDs or paths) as soon as something unanticipated happens: an error or warning, advice or code that failed, a user correction, a version or API mismatch, missing guidance, or a recommendation that held up (`worked-well`). Also write one `use-case` entry per session. When unsure, record it with `generality: unsure`. Entries are hypotheses for `skill-feedback-triage`.
