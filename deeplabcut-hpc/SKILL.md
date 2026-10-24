---
name: deeplabcut-hpc
description: Sets up and runs DeepLabCut (DLC) pose estimation on HPC clusters and headless GPU machines - environment install (PyTorch/CUDA, no GUI), training and video-analysis batch scripts, pytorch_config.yaml settings, and DLC-specific failure modes. Use when the user mentions DeepLabCut, DLC, deeplabcut.train_network, analyze_videos, pose_cfg.yaml, pytorch_config.yaml, or markerless pose estimation, especially together with Slurm, a cluster, or GPUs. Also use when asked to retrain, resubmit, or build an orchestrator/sweep over existing DLC training or video-analysis submission scripts (shuffles, iterations, model variants, training-set fractions), even if the request itself does not say "DeepLabCut" or "Slurm" - check whether the scripts or project files import deeplabcut or call pytorch_config.yaml/pose_cfg.yaml before ruling this out. Combine with the generic hpc-* skills. For metrics or statistics on the tracked output use animal-behaviour-tracking-analysis.
metadata:
  file_signals: 'import deeplabcut|pytorch_config\.yaml|pose_cfg\.yaml'
---

# DeepLabCut on HPC

DeepLabCut changes quickly (3.0 made PyTorch the default and is deprecating TensorFlow). **Do not rely on memory for function signatures or config keys.** Verify against the live docs first, then write code.

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
- `knowledge/main/api.jsonl`: API symbols (`name, module, signature, summary`). The `latest-release` path for api.jsonl returned 404 in testing; check the manifest for the real version path (for example `knowledge/3.0.2/api.jsonl`) and fall back to `main`.
- API reference pages at `/dev/latest-release/reference/deeplabcut/`. The top-level page only indexes submodules; signatures live in `pose_estimation_pytorch/apis/training/` and `.../apis/videos/` (PyTorch) or `pose_estimation_tensorflow/...` (TF).

Useful doc pages: `docs/installation.html`, `docs/pytorch/pytorch_config.html`, `docs/pytorch/user_guide.html`, `docs/recipes/BatchProcessing.html`, `docs/docker.html`.

Match the docs to the cluster's DLC version. The docs do not cover Slurm/HPC; that part comes from this skill and the generic skills.

## Step 2: Load the generic skills

- `hpc-cluster-docs` first, for the site's modules, partitions and GPU syntax.
- `hpc-job-scripts`, `hpc-gpu-jobs`, `hpc-python-code`, `hpc-resource-allocation` for the job script, logging, checkpointing and sizing.

This skill only adds DLC specifics.

## Environment (as of the 3.0 docs; re-check)

- Python 3.10-3.12.
- Headless install: plain `pip install deeplabcut` (no `[gui]` extra). Use `[gui]` only on a workstation for labeling. Extras: `[modelzoo]` for SuperAnimal models, `[tf]` for TensorFlow.
- Install PyTorch with CUDA **before** DLC, from the PyTorch index matching the cluster driver, for example `pip install torch torchvision --index-url https://download.pytorch.org/whl/cu126`. PyTorch bundles its own CUDA runtime, so a `module load cuda` is usually unnecessary; the driver must be new enough. Check on a GPU node: `python -c "import torch; print(torch.cuda.is_available())"` must print `True`.
- Install on a login node or in an interactive job, never inside the batch script. Use a venv/conda env on shared storage (see `hpc-python-code`). Many sites provide containers; Apptainer can pull the DLC Docker images (see `docs/docker.html`, terminal mode).
- TensorFlow engine: avoid for new work (deprecated). If the user must use it, pin TF to the extra matching their CUDA (`tf-cu11`/`tf-cu12`) and expect dependency conflicts with PyTorch.
- GPU: NVIDIA with >= 8 GB VRAM is the documented ideal. CPU training is roughly 10x slower, so do not run training on CPU nodes.

## Workflow split: what runs where

| Step | Where |
|---|---|
| `create_new_project`, labeling (`label_frames`), `extract_frames` | Local workstation with GUI |
| `create_training_dataset`, `train_network`, `evaluate_network` | GPU node |
| `analyze_videos`, `create_labeled_video`, filtering/tracking | GPU node (analysis); labeled videos can run on CPU |

Copy the whole project folder (config.yaml, `dlc-models*`, `training-datasets`, `labeled-data`) to cluster storage. Upload videos separately.

## DLC-specific pitfalls to check in every script

1. **Absolute `project_path` in `config.yaml`.** A project created on another machine (e.g. Windows) has the wrong path. Update it before running, for example with `deeplabcut.auxiliaryfunctions.read_config` / `write_config` (pattern in the BatchProcessing recipe), or edit the YAML. In arrays, never have several tasks rewrite the same config.yaml concurrently; give each task its own copy or fix the path once before submitting.
2. **No display on compute nodes.** Set `MPLBACKEND=Agg` in the job script. Prefer `plotting=False` in `evaluate_network` for unattended runs. Never import or launch the GUI.
3. **Engine selection.** `engine: pytorch` (or `tensorflow`) in `config.yaml` decides which engine new training datasets use. Confirm it before `create_training_dataset`.
4. **Training length is in epochs for PyTorch.** Control it via `train_network(..., epochs=...)` or `train_settings.epochs` in `pytorch_config.yaml`. Other keys documented in `pytorch_config.yaml`: `train_settings.batch_size` (default 1), `train_settings.dataloader_workers` (default 0), `runner.snapshots.save_epochs` (25), `runner.snapshots.max_snapshots` (5), `runner.gpus` (list), top-level `device` (`auto`), top-level `resume_training_from` (path to a `snapshot-NNN.pt`). Verify against the docs for the installed version.
5. **Dataloader workers.** The default is 0, which starves the GPU. Raise `dataloader_workers` to at most `--cpus-per-task` (leave one core free). Use `parallelly`-style logic from `hpc-python-code` to read the Slurm allocation, not `os.cpu_count()`.
6. **Batch size.** Raise `batch_size` to use the GPU's memory; confirm with `nvidia-smi`/job monitoring rather than guessing. Out-of-memory errors on the GPU are fixed by reducing batch size or image size, not by requesting more host memory.
7. **Checkpoint and resume.** Snapshots are saved every `save_epochs`. Set `save_epochs` low enough that a time-limit kill loses little, and resume with `resume_training_from` pointing to the last snapshot. Write the resume logic so a requeued job continues instead of restarting (see `hpc-job-scripts` for requeue and `--signal`).
8. **Multiple shuffles/projects.** One GPU per training run unless the docs for the installed version describe multi-GPU. Use job arrays with one shuffle or project per task, each with isolated output (the BatchProcessing recipe uses a `sys.argv[1]` index per GPU).
9. **`analyze_videos` caching.** Already-analyzed videos are skipped, so reruns after a failure are cheap and safe. Use `destfolder` to write results to scratch/project storage. Per-video work parallelizes well as an array (one video or folder per task).
10. **Video I/O.** Decoding is CPU-bound; request enough CPUs for analysis jobs. Stage large videos to node-local scratch when the shared filesystem is slow (see `hpc-job-scripts/references/arrays-and-scratch.md`).
11. **Model downloads.** Pretrained backbones and SuperAnimal weights are downloaded on first use, which fails on compute nodes without internet. Run one short training or model-creation step on a login node (or pre-download weights) before submitting, and point the cache to shared storage if the home quota is small.

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
deeplabcut.evaluate_network(a.config, Shuffles=[a.shuffle], plotting=False)
```

## When something fails: search upstream before improvising

DLC moves fast, so an unexpected error is often a known bug, a regression in the installed version, or already fixed on `main`. Before inventing a workaround:

1. Get from the user the cluster's DLC version (`deeplabcut.__version__`), the engine, the PyTorch/CUDA versions, and the exact error message (first and last lines of the traceback). The searches below run locally, where the internet is available.
2. Search issues, open and closed, for the error text or function name (the `gh` CLI is preferred over web fetching):
   - `gh search issues --repo DeepLabCut/DeepLabCut "<error text>" --sort updated`
   - `gh issue view <number> --repo DeepLabCut/DeepLabCut --comments`
3. Search pull requests for fixes in progress or merged:
   - `gh search prs --repo DeepLabCut/DeepLabCut "<keyword>" --sort updated`
   - `gh pr view <number> --repo DeepLabCut/DeepLabCut`
4. Check recent commits and releases for relevant changes:
   - `gh api "repos/DeepLabCut/DeepLabCut/commits?per_page=30"`
   - `gh release list --repo DeepLabCut/DeepLabCut`
   - For a suspect file, `gh api "repos/DeepLabCut/DeepLabCut/commits?path=<file path>&per_page=10"`
5. Check the forum for usage and cluster questions: https://forum.image.sc/tag/deeplabcut
6. Compare dates with the installed version. If a fix is merged but unreleased, offer these options and let the user choose: pin an older release, install the pre-release (`pip install --pre deeplabcut`), or install from `main` (`pip install git+https://github.com/DeepLabCut/DeepLabCut.git`). Installing from `main` is less stable.
7. Report what you found with links, and say plainly whether an issue is confirmed, only similar, or not found. Do not present a workaround from an unrelated or unresolved issue as established. If nothing matches, say so before trying your own diagnosis.

## Not verified

This skill was written from the official docs only. Nothing here has been run on a real cluster. If a command or key fails on the cluster, trust the live docs and the cluster version's `help()` output (ask the user to paste it) over this file, and tell the user which part was wrong.

**Real-use evidence (2026-10-24, user project, two independent sessions):** diagnosing a
multi-animal-to-single-animal project split that produced fewer annotated frames than expected
(cross-referencing a Slurm console log, a JSON manifest/validation report and a checksum
manifest), and building a small orchestrator to submit multiple training jobs with varying
hyperparameters, checked against HPC and DLC best practices (headless-plotting backend,
dataloader-worker sizing, a shared-resource race condition in one script — all fixed and
verified locally with `bash -n`, the bundled sbatch linter, and dry runs, no cluster access
needed). Still not run on a real cluster.

## Related skills

- `animal-behaviour-tracking-analysis`: what to do with the DLC output (likelihood masking, distance, speed, ROI time, keypoint-MoSeq syllables).

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were done or not done: why this method, setting or tool was chosen, which alternative was rejected and why, which check or step was skipped, and which assumptions were made. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a package version or API differs from what it states, or it lacks guidance the task needs, record a generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
