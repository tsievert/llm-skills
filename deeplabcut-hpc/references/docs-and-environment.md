# DLC docs lookup and environment

## Contents

- Official LLM entry point and doc pages
- Environment (3.0.2 docs, re-checked 2026-10-29)

## Official LLM entry point

Start at https://deeplabcut.github.io/DeepLabCut/llms.txt. It links to:

- `knowledge/manifest.json`: lists indexed API versions and which is current (`latest-release`).
- `knowledge/main/docs.jsonl`: one JSON object per doc page/section (`id, title, url, section, summary`). Large (~470 KB); fetch with a specific question, not whole.
- `knowledge/main/api.jsonl`: API symbols (`name, module, signature, summary`). The `latest-release` path for api.jsonl returned 404 in testing; use the version from the manifest instead (`knowledge/3.0.2/api.jsonl` worked on 2026-10-29) and fall back to `main`.
- API reference pages at `/dev/latest-release/reference/deeplabcut/`. The top-level page only indexes submodules; signatures live in `pose_estimation_pytorch/apis/training/` and `.../apis/videos/` (PyTorch) or `pose_estimation_tensorflow/...` (TF).

Useful doc pages: `docs/installation.html`, `docs/pytorch/pytorch_config.html`, `docs/pytorch/user_guide.html`, `docs/recipes/BatchProcessing.html`, `docs/docker.html`.

Match the docs to the cluster's DLC version. The docs do not cover Slurm/HPC; that part comes from the skill and the generic HPC skills.

## Environment (3.0.2 docs, re-checked 2026-10-29; 3.0.3 release notes read 2026-11-27)

- Python 3.10-3.12 (3.0.3 release notes do not change this; install page not re-read).
- 3.0.3 requires `pydantic>=2.12` (was `>=2`). In an existing env with an older pydantic pinned by another package, `pip install -U deeplabcut` may conflict; make a fresh env rather than forcing it. 3.0.2 dropped the `numpy<2` pin for core installs (the `[tf]` extra keeps it).
- Do not mix DLC versions on one project: a 3.0.3-written `pytorch_config.yaml` failed to load in 3.0.2 (see `ctd-topdown-preflight.md`). On Windows, any script with `dataloader_workers > 0` needs an `if __name__ == "__main__":` guard (spawn), or training fails with a bootstrapping RuntimeError.
- Behaviour changes worth knowing when moving from 3.0.2: top-down inference no longer skips frames without detections (output frame counts and NaN patterns can differ from earlier runs; re-analyse before comparing), PyTorch `analyze_videos` honours `overwrite` (since 3.0.2), unreadable videos now warn.
- Headless install: plain `pip install deeplabcut` (no `[gui]` extra). Use `[gui]` only on a workstation for labeling. Extras: `[modelzoo]` for SuperAnimal models, `[tf]` for TensorFlow.
- Install PyTorch with CUDA **before** DLC, from the PyTorch index matching the cluster driver, for example `pip install torch torchvision --index-url https://download.pytorch.org/whl/cu126`. PyTorch bundles its own CUDA runtime, so a `module load cuda` is usually unnecessary; the driver must be new enough. Check on a GPU node: `python -c "import torch; print(torch.cuda.is_available())"` must print `True`.
- Install on a login node or in an interactive job, never inside the batch script. Use a venv/conda env on shared storage (see `hpc-python-code`). Many sites provide containers; Apptainer can pull the DLC Docker images (see `docs/docker.html`, terminal mode).
- TensorFlow engine: avoid for new work (deprecated). If the user must use it, pin TF to the extra matching their CUDA (`tf-cu11`/`tf-cu12`) and expect dependency conflicts with PyTorch.
- GPU: NVIDIA with >= 8 GB VRAM is the documented ideal. CPU training is roughly 10x slower, so do not run training on CPU nodes.
- Local test recipes: the PyPI package is `tables` (`pytables` is the conda name only). Clean up stray test processes by filtering on the scratch venv path, never by image name (a blanket `python` kill is blocked and would hit other work).
- Prototyping locally with `uv`/a venv: if the assistant's own `bash` cannot find a `uv`/`python` that a separate terminal sees, it is usually a stale-PATH issue after install, not a missing install (see "uv/Python not found by the assistant's shell" in `python-reproducible-pipeline`'s environments-and-pinning reference).
