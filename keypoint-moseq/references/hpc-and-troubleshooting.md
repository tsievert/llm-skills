# keypoint-MoSeq on HPC: install, jobs, troubleshooting

Contents: install and version findings, job layout, sizing, known problems, searching upstream.

Load `hpc-cluster-docs` first for the site's modules, partitions and GPU syntax, then `hpc-job-scripts`, `hpc-gpu-jobs`, `hpc-resource-allocation`. This file only adds kpms specifics.

## Install

- Docs (install page, re-read 2026-10-29): supports Python 3.10 to 3.14; the example creates a conda env with Python 3.12, then `pip install keypoint-moseq` (CPU) or `pip install keypoint-moseq[cuda]` (GPU, CUDA 12). Supported platforms follow JAX: CPU and GPU on Linux, CPU on macOS and Windows; GPU on WSL2 experimental. The first import after installation can take minutes.
- Release 0.8.0 (PyPI and GitHub, 2026-10-23): GPU is now strictly the `[cuda]` extra (Linux, CUDA 12) and a plain `pip install keypoint-moseq` is CPU-only; macOS and Windows get the current release again (earlier releases pulled Linux-only CUDA packages, so pip there silently fell back to 0.6.6). Adds `kpms.check_installation()`, which is worth asking the user to run after every install. Check `pip list` for the actual version, because a silent fallback to an old release is the failure to look for.
- PyPI metadata (2026-10-22, 0.7.1): `requires_python >=3.10`; the 0.7.0 release notes say Python 3.10-3.14 and that pins on numpy, jax, pandas and others were dropped, so a fresh install gets the newest versions (NumPy 2, pandas 3 on Python 3.11+). The install page still says 3.10; either works per the release notes, but use the version the cluster's JAX wheels support.
- Install on a login node or in an interactive job, into an environment on shared storage; never inside the batch script. Use `pip install "keypoint-moseq[cuda]"` so JAX brings CUDA 12 wheels; a `module load cuda` is usually not needed but the NVIDIA driver must be new enough (ask the user for `nvidia-smi` output).
- Verify on a GPU node (ask the user to run it and paste the output):

```bash
python -c "import jax, keypoint_moseq as k; print(k.__version__, jax.__version__, jax.default_backend(), jax.devices())"
```

`jax.default_backend()` must print `gpu`. The sbatch template aborts otherwise.

If a local `uv`/`python` install is invisible to the assistant's `bash` calls even though a
separate terminal sees it, this is usually a stale-PATH issue, not a missing install — see
"uv/Python not found by the assistant's shell" in `python-reproducible-pipeline`
(`references/environments-and-pinning.md`).

### Findings from local testing on Windows (2026-10-23)

- kpms 0.7.x could not be installed on Windows with `uv pip` (it declared the Linux-only `jax-cuda12-pjrt`), so the newest installable was 0.6.6. **Fixed in 0.8.0**, which installed on Windows (Python 3.12, uv, CPU; jax 0.12.0.1, numpy 2.5.4) without problems.
- `check_nan_proportions` failed with pandas 3 (`Styler` has no `applymap`) in 0.6.6 and 0.8.0 (pandas 3.1.0; `pandas<3` worked). **Stale as of 0.8.3** (2026-10-29): it runs under pandas 3.1.0 (jax 0.12.0.1, numpy 2.5.4, Python 3.12), so no pin is needed there; keep `pandas<3` only for 0.8.0 or older. The 0.7.0 pandas 3 fix for `plot_syll_stats_with_sem` was not tested.
- 0.8.3 installed cleanly on Windows (uv, CPU) and the headless script, resume, `compute_moseq_df`/`compute_stats_df`/`generate_transition_matrices`, the Python summariser and the R reader all ran on its output. jax-moseq 0.3.8 is now required (0.8.2).
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
| NaNs during fitting | Check `jax.config.read('jax_enable_x64')`; raise `jitter` one step at a time from 1e-3 (1e-1 is the maximum and produced odd coordinates and plots in upstream thread #153; look at trajectory plots after each change, see rule 10 in `SKILL.md`); `parallel_message_passing=True`; check NaN proportions of the input; calibrate noise on a workstation |
| "no kernel image is available" | `jax.default_backend()` is not `gpu`: check CUDA wheels, driver, and that the right env is active |
| Many NaNs in some recordings | `check_nan_proportions(coordinates, bodyparts, breakdown=True)`; re-track with a lower threshold |
| `libcudart` / `ptxas` not found | Seen in upstream issue #155 (older pip install on an HPC); use the `[cuda]` extra in a clean env, check driver |
| Noise calibration errors | Interactive step; upstream issues #220 (calibration failing, skipping may cause NaNs) and #232 (frame outside video bounds) are related. Skipping it is what the headless script does; if NaNs appear, calibrate on a workstation and copy the resulting `slope`/`intercept` into `config.yml` |
| Multi-GPU | Upstream issue #236: turn off parallel message passing, raise `mixed_map_iters` (maximum about n_recordings / n_gpus), or fit a subset and apply; otherwise one GPU per task |
| `apply_model` gives more syllables | Upstream issue #176: apply in batches; csv/h5 hold all syllables, grid movies and plots only those above `min_frequency`. See `common-problems.md` |

The first issue numbers above come from a GitHub search on 2026-10-23 (titles and gists only). Maintainer answers read on 2026-10-29 for calibration, NaNs, `apply_model`, trimming and multi-GPU are in [common-problems.md](common-problems.md). Treat all of them as leads, not confirmed fixes.

## Performance versus memory trade-off

- The only real benchmark is from the paper (Nature Methods, 2024): with a consumer GPU, fitting takes roughly 30-60 min for 5 h of data, and computation time scales roughly linearly with dataset size. GPU model and dataset composition are not specified, and this is not an HPC measurement.
- Every memory-saving option in the table above costs speed, not just memory: `parallel_message_passing=False` cuts memory about 4-6x but slows fitting by about the same factor; `set_mixed_map_iters(n)` splits the batch into `n` pieces for roughly 1/n memory at roughly n times the time. There is no documented setting that improves both at once.
- Large datasets can crash at initialization, before fitting even starts: upstream issue #177 ("Kernel crashing for large datasets initialization", **open**, checked 2026-10-26) reports a kernel death inside `jax_moseq`'s `resample_discrete_stateseqs`, reproduced by inflating a working dataset to the problem size. No fix or confirmed workaround exists upstream. If a large job dies silently at startup, treat this issue as the first lead, not generic OOM (which happens later, during fitting, not initialization).
- This skill has never measured kpms on an actual HPC GPU node or a real-sized dataset (see "Not verified" in `SKILL.md`). The sizing in the job-layout table above (about 3 MB/100 frames, checkpoint-every-25) comes from the docs, not from a run this skill performed. Treat it as a starting guess, not a tested default.

### Ask the user to help close this gap

The next time a real fit runs on the cluster, ask the user to report back the following, and record the answer as a `skill-lessons` entry (see "Capture lessons" in `SKILL.md`) with kpms/jax versions, dataset size, GPU model and the numbers themselves — this specific gap (no real HPC/GPU timing or memory data) is a standing, named trigger for that section, not just the generic "something failed" case:

1. `seff <jobid>` (and `sacct -j <jobid> --format=JobID,Elapsed,MaxRSS,State`) once the job finishes: wall time, CPU efficiency, max RSS.
2. The `run_summary.json` the fit script writes (now extended, see below) with frame count, iterations/second and GPU device name.
3. The `.gpu.log` produced by the background `nvidia-smi` poller added to `assets/kpms_fit.sbatch` below, for peak GPU memory and utilisation even if the job is killed mid-run.

`scripts/kpms_headless_fit.py` times the AR-only and full-model fit phases separately and records frame count, phase durations, iterations/second and the JAX device name in `run_summary.json`. `assets/kpms_fit.sbatch` starts a background `nvidia-smi --query-gpu=... -l 60` poll into `logs/%x_%A_%a.gpu.log` for the job's lifetime. Ask the user to paste back both files; use them to replace the docs-only sizing in this file with tested numbers, and log the raw numbers via `skill-lessons` so a future triage round can fold them in.

## When something fails: search upstream before improvising

1. Get the cluster's `keypoint_moseq`, `jax`, `jaxlib` and `jax_moseq` versions (`pip list | grep -i -E "jax|moseq"`) and the first and last lines of the traceback from the user.
2. Search issues: `gh search issues --repo dattalab/keypoint-moseq "<error text>" --sort updated`. If `gh` is not on PATH (it was not in Git Bash or R on the user's machine), use the API: `https://api.github.com/search/issues?q=repo:dattalab/keypoint-moseq+<terms>`.
3. Check releases (`https://api.github.com/repos/dattalab/keypoint-moseq/releases`) and `jax-moseq` (https://github.com/dattalab/jax-moseq) for fixes newer than the cluster's version. Recent releases fixed install failures (0.6.11, dynamax dependency) and NumPy 2.3 frequency errors (jax-moseq 0.3.7).
4. Docs FAQ: https://keypoint-moseq.readthedocs.io/en/stable/FAQs.html (it still lists a personal email for persistent NaNs; the repo itself now points support requests at GitHub issues, so open an issue instead) and Slack.
   Also read the release notes between the cluster's version and the latest: several 0.8.x releases changed outputs silently (see "Version changes that matter" in `keypoint-moseq-workflow.md`), so a behaviour difference may be a release change, not a bug.
5. Report what was found with links and say whether an issue is confirmed, similar only, or not found. If a fix exists only on `main`, offer pinning an older release, upgrading, or installing from git, and let the user choose; installing from GitHub needs the user's explicit consent in this repo's rules.
