# keypoint-MoSeq on HPC: install, jobs, troubleshooting

Contents: install and version findings, job layout, sizing, known problems, searching upstream.

Load `hpc-cluster-docs` first for the site's modules, partitions and GPU syntax, then `hpc-job-scripts`, `hpc-gpu-jobs`, `hpc-resource-allocation`. This file only adds kpms specifics.

## Install

- Docs (install page, 2026-10-23): conda env with Python 3.10, then `pip install keypoint-moseq` (CPU) or `pip install keypoint-moseq[cuda]` (GPU, CUDA 12). Supported platforms follow JAX: CPU and GPU on Linux, CPU on macOS and Windows; GPU on WSL2 experimental. The first import after installation can take minutes.
- PyPI metadata (2026-10-22): kpms 0.7.1, `requires_python >=3.10`; the 0.7.0 release notes say Python 3.10-3.14 and that pins on numpy, jax, pandas and others were dropped, so a fresh install gets the newest versions (NumPy 2, pandas 3 on Python 3.11+). The install page still says 3.10; either works per the release notes, but use the version the cluster's JAX wheels support.
- Install on a login node or in an interactive job, into an environment on shared storage; never inside the batch script. Use `pip install "keypoint-moseq[cuda]"` so JAX brings CUDA 12 wheels; a `module load cuda` is usually not needed but the NVIDIA driver must be new enough (ask the user for `nvidia-smi` output).
- Verify on a GPU node (ask the user to run it and paste the output):

```bash
python -c "import jax, keypoint_moseq as k; print(k.__version__, jax.__version__, jax.default_backend(), jax.devices())"
```

`jax.default_backend()` must print `gpu`. The sbatch template aborts otherwise.

### Findings from local testing on Windows (2026-10-23)

- kpms 0.7.x could not be installed on Windows with `uv pip`: it declares `jax-cuda12-pjrt`, which only has Linux wheels (and an older pinned version was yanked), so resolution fails. The newest installable was 0.6.6 (CPU). This is not a problem on Linux clusters, but it means Windows cannot reproduce a 0.7.x cluster environment.
- kpms 0.6.6 with pandas 3 fails in `check_nan_proportions` (`Styler` has no `applymap`). Install `pandas<3` for 0.6.x. The 0.7.0 notes mention pandas 3 fixes for `plot_syll_stats_with_sem`; not tested.
- A CPU fit of 12 iterations on 4 x 1500 frames took roughly 45 s including JIT compilation; useful for smoke tests, not for real data.

## Job layout

| Job | GPUs | Notes |
|---|---|---|
| `--prepare-only` | 0-1 | Config, outlier removal, PCA. Run once, before any array. PCA is cheap; one GPU is not required |
| Fit (one model) | 1 | `assets/kpms_fit.sbatch` with `--array=0-0` |
| Restarts / model selection | 1 per task | `--array=0-19%4`, seed = task id, model name `run_seed<N>`. Then compare with `expected_marginal_likelihoods` locally or in a short job |
| Kappa scan | 1 per task | One kappa per task, model name from kappa |
| Grid movies / overlays | 0-1 | Video decoding is CPU-bound and can be slow; separate job, request CPUs rather than GPU |

Resource sizing: memory scales with dataset size and latent dimensions (docs: about 3 MB per 100 frames at 4 latent dimensions on the GPU). Measure with `sacct`/`seff` after a first run instead of guessing (`hpc-resource-allocation`). Host RAM needs to hold all keypoints; GPU memory is the usual limit.

Time limit: the script saves checkpoints every `--save-every` iterations (default 25) and resumes from the last one, so a time-limit kill loses at most that many iterations. Resubmit the same command. Resume was tested for the AR phase and the full phase.

Environment variables in the template: `MPLBACKEND=Agg` (no display), `PYTHONUNBUFFERED=1` (live logs). Do not set `OMP_NUM_THREADS` higher than `--cpus-per-task`.

## Known problems and fixes (docs FAQ unless noted)

| Symptom | Fix |
|---|---|
| GPU out of memory, or kernel/job dies | One JAX process per GPU. Fit on a subset then `apply_model`; `parallel_message_passing=False`; `set_mixed_map_iters(4)`; lower `latent_dim`. On Windows a dead kernel is often OOM |
| NaNs during fitting | Check `jax.config.read('jax_enable_x64')`; raise `jitter` from 1e-3 to 1e-2 or 1e-1; `parallel_message_passing=True`; check NaN proportions of the input; calibrate noise on a workstation |
| "no kernel image is available" | `jax.default_backend()` is not `gpu`: check CUDA wheels, driver, and that the right env is active |
| Many NaNs in some recordings | `check_nan_proportions(coordinates, bodyparts, breakdown=True)`; re-track with a lower threshold |
| `libcudart` / `ptxas` not found | Seen in upstream issue #155 (older pip install on an HPC); use the `[cuda]` extra in a clean env, check driver |
| Noise calibration errors | Interactive step; upstream issues #220 (calibration failing, skipping may cause NaNs) and #232 (frame outside video bounds) are related. Skipping it is what the headless script does; if NaNs appear, calibrate on a workstation and copy the resulting `slope`/`intercept` into `config.yml` |
| Multi-GPU | Upstream issue #236 reports mixed multi-GPU fitting failing; prefer one GPU per task |
| `apply_model` gives more syllables | Upstream issue #176 discusses this; expect syllable counts to depend on data |

Issue numbers come from a GitHub search on 2026-10-23 (titles and gists only; resolutions were not read). Treat them as leads, not confirmed fixes.

## When something fails: search upstream before improvising

1. Get the cluster's `keypoint_moseq`, `jax`, `jaxlib` and `jax_moseq` versions (`pip list | grep -i -E "jax|moseq"`) and the first and last lines of the traceback from the user.
2. Search issues: `gh search issues --repo dattalab/keypoint-moseq "<error text>" --sort updated`. If `gh` is not on PATH (it was not in Git Bash or R on the user's machine), use the API: `https://api.github.com/search/issues?q=repo:dattalab/keypoint-moseq+<terms>`.
3. Check releases (`https://api.github.com/repos/dattalab/keypoint-moseq/releases`) and `jax-moseq` (https://github.com/dattalab/jax-moseq) for fixes newer than the cluster's version. Recent releases fixed install failures (0.6.11, dynamax dependency) and NumPy 2.3 frequency errors (jax-moseq 0.3.7).
4. Slack and the docs FAQ: https://keypoint-moseq.readthedocs.io/en/stable/FAQs.html.
5. Report what was found with links and say whether an issue is confirmed, similar only, or not found. If a fix exists only on `main`, offer pinning an older release, upgrading, or installing from git, and let the user choose; installing from GitHub needs the user's explicit consent in this repo's rules.
