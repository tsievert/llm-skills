---
name: deeplabcut-hpc
description: Sets up and runs DeepLabCut (DLC) pose estimation on HPC clusters and headless GPU machines - environment install, training and video-analysis batch scripts, pytorch_config.yaml settings, DLC failure modes and failed training logs. Use when the user mentions DeepLabCut, DLC, train_network, analyze_videos, pose_cfg.yaml, pytorch_config.yaml, or markerless pose estimation, esp. with Slurm or GPUs. Also use to retrain, resubmit, or build an orchestrator/sweep, benchmark suite or sbatch loop over DLC training or video-analysis scripts (shuffles, model variants), even if the request does not say "DeepLabCut" or "Slurm", to review or rank a benchmark JSON/export (even analysis-only), compare shuffles or net_type results, decide whether a model needs more epochs, or reproduce a DLC bug locally and draft an upstream issue. Combine with hpc-* skills. For metrics or statistics on the tracked output use animal-behaviour-tracking-analysis; for behavioural syllables use keypoint-moseq.
metadata:
  prompt_signals: 'deeplabcut|DeepLabCut|\banalyze_videos\b|\btrain_network\b|pytorch_config\.yaml|pose_cfg\.yaml|benchmark.{0,20}(json|export)|\bnet_type\b'
  file_signals: 'import deeplabcut|pytorch_config\.yaml|pose_cfg\.yaml|deeplabcut_version|test_mAP|training_state|evaluation_state|dlc_.*benchmark.*\.json|gpu_usage_.*\.csv'
---

# DeepLabCut on HPC

**Before writing or reviewing any submit command, sbatch loop or orchestrator, load `hpc-cluster-docs` first (site modules, partitions, GPU syntax), then `hpc-job-scripts`**, and `hpc-gpu-jobs`, `hpc-python-code`, `hpc-resource-allocation` as needed. This skill only adds DLC specifics.

DLC changes quickly (3.0 made PyTorch the default and is deprecating TensorFlow). **Do not rely on memory for function signatures or config keys**: verify against the live docs for the cluster's DLC version first, then write code. The docs entry point, doc pages and install facts (Python, headless install, PyTorch before DLC, GPU needs) are in [references/docs-and-environment.md](references/docs-and-environment.md). The docs do not cover Slurm; that part comes from the generic HPC skills.

## Where this skill runs

The assistant runs only on the user's local machine, never on the cluster. It writes and reviews scripts, config and job files locally; the user copies them to the cluster, submits them and reports back. Never run `sbatch`, `squeue`, `nvidia-smi` or `torch.cuda.is_available()`; local tools (web fetch, `gh`, `check_sbatch.sh`, syntax checks) are fine. Ask for the cluster's DLC version (`python -c "import deeplabcut; print(deeplabcut.__version__)"`), PyTorch/CUDA versions and log excerpts; a local install may differ.

**Requirement:** whenever information is needed that only the cluster can provide, stop and ask the user to run the specific shell command(s), given in a code block, and paste back the output. Do not guess or proceed on assumptions.

## Workflow split: what runs where

| Step | Where |
|---|---|
| `create_new_project`, labeling (`label_frames`), `extract_frames` | Local workstation with GUI |
| `create_training_dataset`, `train_network`, `evaluate_network` | GPU node |
| `analyze_videos`, `create_labeled_video`, filtering/tracking | GPU node (analysis); labeled videos can run on CPU |

Copy the whole project folder (config.yaml, `dlc-models*`, `training-datasets`, `labeled-data`) to cluster storage. Upload videos separately.

## DLC-specific pitfalls to check in every script

Rows marked (detail) have more in [references/pitfall-details.md](references/pitfall-details.md).

| # | Pitfall | Rule |
|---|---|---|
| 1 | Absolute `project_path` in `config.yaml` | A project made on another machine (e.g. Windows) has the wrong path. Fix it before running (`deeplabcut.auxiliaryfunctions.read_config` / `write_config`, as in the BatchProcessing recipe, or edit the YAML). In arrays give each task its own config copy, or fix it once before submitting. |
| 2 | No display on compute nodes | `MPLBACKEND=Agg` in the job script, `plotting=False` in `evaluate_network`, never launch the GUI. |
| 3 | Engine selection | `engine: pytorch` (or `tensorflow`) in `config.yaml` decides the engine of new training datasets. Confirm it before `create_training_dataset`. |
| 4 | Training length (PyTorch) | In epochs: `train_network(..., epochs=...)` or `train_settings.epochs`. Verify key names and defaults for the installed version; code defaults can differ from the docs (detail). |
| 5 | Dataloader workers | Default 0 starves the GPU. Raise `dataloader_workers` to at most `--cpus-per-task` minus one; more is not always faster, so profile first (detail). |
| 6 | Batch size | Raise `batch_size` to use GPU memory, confirmed by monitoring. GPU out-of-memory is fixed by a smaller batch or image size, not more host memory. |
| 7 | Checkpoint and resume | Set `save_epochs` low enough that a time-limit kill loses little; resume with `resume_training_from` or `snapshot_path`. A resumed run treats `epochs` as additional, so pass the remaining number in a requeue script (detail; `hpc-job-scripts` for requeue and `--signal`). |
| 8 | Shuffles, projects, GPUs | One GPU per run; multi-GPU is single-node `DataParallel`, scaling untested. Job arrays with isolated output per task. Shuffle numbering starts at 1, not 0 (detail). |
| 9 | `analyze_videos` caching | Already-analyzed videos are skipped, so reruns are cheap. Use `destfolder` for scratch/project storage; parallelise per video or folder as an array. |
| 10 | Video I/O | Decoding is CPU-bound; request enough CPUs. Stage large videos to node-local scratch when the shared filesystem is slow (`hpc-job-scripts` arrays-and-scratch reference). |
| 11 | Model downloads | Backbones and SuperAnimal weights download on first use, which fails on compute nodes without internet. Run one short model-creation step on a login node (or pre-download); point the cache to shared storage if the home quota is small. |
| 12 | Re-split and evaluation | After `create_training_dataset` or a re-split, `evaluate_network` can fall back to TensorFlow. Pass `engine=Engine.PYTORCH` and `shuffles=[n]` explicitly and treat old evaluation results as stale (detail). |

## Tuning `pytorch_config.yaml` and designing sweeps

Optimizer, scheduler, augmentation keys with documented defaults, and what DLC does not expose are in [references/pytorch-config-tuning.md](references/pytorch-config-tuning.md). Re-verify against the docs for the installed version; keys drift. Training-script overrides go through `train_network(...)` arguments or `pytorch_cfg_updates`.

For a multi-candidate sweep, exhaust the `net_type` axis before secondary knobs. The architecture list (print it with `available_models()`), benchmark interpretation and orchestrator checks are in [references/training-sweeps.md](references/training-sweeps.md).

## Job script skeleton (training, one GPU)

Start from [assets/train-job.sh](assets/train-job.sh) and [assets/train_dlc.py](assets/train_dlc.py); adapt to the site and lint with `hpc-job-scripts/scripts/check_sbatch.sh`. Check signatures in the live docs first.

## When something fails: search upstream before improvising

An unexpected error is often a known bug, a regression, or fixed on `main`. Get the DLC version, engine, PyTorch/CUDA versions and the exact traceback from the user, then search issues, PRs, commits, releases and the forum before inventing a workaround. Report plainly whether a match is confirmed, only similar, or not found. Details: [references/upstream-search.md](references/upstream-search.md).

## Not verified

Written from the official docs (3.0.2 docs and release notes; research and real-use evidence in `research/deeplabcut-hpc-ledger.md` in the llm-skills repo). Scripts were reviewed with `bash -n`, the sbatch linter and dry runs; nothing has run on a real cluster. If a command or key fails there, trust the live docs and the cluster version's `help()` output (ask the user to paste it) over this file, and say which part was wrong.

## Related skills

- `animal-behaviour-tracking-analysis`: what to do with the DLC output (likelihood masking, distance, speed, ROI time).
- `keypoint-moseq`: unsupervised behavioural syllables from the DLC keypoints.

## Explain the reasoning (teaching rule)

Teach, don't replace the user's thinking: say briefly (a sentence or two) why things were or were not done, name the trade-off and which decision is the user's, and point to a reference for depth.

## Capture lessons (self-improvement rule)

Load the `skill-lessons` skill and append a generic, anonymised entry (no project data, IDs or paths) as soon as something unanticipated happens: an error or warning, advice or code that failed, a user correction, a version or API mismatch, missing guidance, or a recommendation that held up (`worked-well`). Also write one `use-case` entry per session. When unsure, record it with `generality: unsure`. Entries are hypotheses for `skill-feedback-triage`.
