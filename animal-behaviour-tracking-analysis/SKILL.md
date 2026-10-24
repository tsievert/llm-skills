---
name: animal-behaviour-tracking-analysis
description: Turns DeepLabCut (DLC) pose output into behavioural results. Basic metrics (likelihood masking, gap interpolation, pixel-to-cm calibration, smoothing, distance, speed, immobility/freezing bouts, time in ROI/zone, entries, latency, time bins) in R or Python, and unsupervised behavioural syllables with keypoint-MoSeq - headless resumable fitting on HPC/GPU, results.h5, usage/bout/transition analysis with hdf5r, glmmTMB, emmeans or h5py/pandas. Use when the user mentions DLC csv/h5 output analysis, velocity, distance travelled, time in zone, open field, elevated plus maze, freezing, ROI, keypoint-MoSeq, kpms, MoSeq, behavioural syllables, results.h5, or syllable transitions. Not for training or running the DLC network itself (use deeplabcut-hpc); combine with the hpc-* skills for jobs.
---

# Animal behaviour tracking analysis (DLC to keypoint-MoSeq and beyond)

Scope: **downstream of DLC**, two routes that can be combined. (a) **Hypothesis-driven basic metrics** (distance, speed, immobility, time in ROI, entries, latency, path shape) with `scripts/dlc_metrics.py` / `dlc_metrics.R`, see [references/dlc-basic-metrics.md](references/dlc-basic-metrics.md). (b) **Unsupervised syllables with keypoint-MoSeq (kpms)**, the rest of this file. Out of scope: other behaviour-classification tools (SimBA, B-SOiD, VAME). If the user asks for those, say this skill does not cover them.

keypoint-moseq changes fast (six releases between 2026-10-20 and 2026-10-22, when this was written). **Do not rely on memory for signatures or config keys.** Check the installed version and the stable docs (https://keypoint-moseq.readthedocs.io/en/stable/) before writing code.

## Where this skill runs

The assistant runs only on the user's local machine, never on the cluster (same rules as `deeplabcut-hpc`). It writes and reviews scripts, runs the lightweight downstream analysis locally, and gives the user exact commands for the cluster, asking for the output pasted back. Do not attempt `sbatch`, `nvidia-smi` or `jax.devices()` cluster-side checks. Whenever information is needed that only the cluster can give (kpms/JAX/CUDA versions, GPU memory, logs), stop and ask for the specific command output.

## Workflow (copy and track)

0. **Choose the route**: simple, pre-defined measures (distance, speed, zone time, immobility) go through `references/dlc-basic-metrics.md` and the `dlc_metrics` scripts, with no cluster needed; exploratory syllable discovery goes through steps 1-7 below. Both start from the same checked DLC output.
1. **Check upstream tracking quality** (DLC): likelihoods, NaN proportions per recording and keypoint, identity swaps for multi-animal. kpms tolerates noise but not large NaN fractions.
2. **Decide the model inputs**: 5-10 informative keypoints (no tail for rodents), anterior/posterior keypoints for heading, fps, which recordings are pooled. See [references/keypoint-moseq-workflow.md](references/keypoint-moseq-workflow.md).
3. **Fit on a GPU node** with `scripts/kpms_headless_fit.py` and `assets/kpms_fit.sbatch` (lint with `hpc-job-scripts/scripts/check_sbatch.sh`). Load `hpc-cluster-docs` first. Details: [references/hpc-and-troubleshooting.md](references/hpc-and-troubleshooting.md).
4. **Check the fit**: median syllable duration versus target (kappa), number of syllables, stability across seeds (expected marginal likelihood, confusion matrix), and **watch grid movies or trajectory plots** before interpreting or naming any syllable.
5. **Extract** `results.h5` and summarise with `scripts/kpms_summarise_results.py` (Python, no JAX) or `scripts/kpms_results.R` (R, hdf5r).
6. **Analyse**: for kpms usage, durations and transitions see [references/downstream-analysis.md](references/downstream-analysis.md); for the step from any metric table to models (design, metadata, which model for which metric, kpms beyond its built-in tests) see [references/statistical-analysis.md](references/statistical-analysis.md) and the tested template `scripts/stats_demo.R`. For the generic GLMM fitting/diagnostics workflow itself, use `mixed-models-glmm` and its `glmm_templates.R`.
7. **Record provenance**: kpms/jax versions, seed, kappa(s), iterations, latent_dim, model name, DLC model and shuffle.

## What runs where

| Step | Where |
|---|---|
| DLC tracking | GPU node (`deeplabcut-hpc`) |
| `kpms_headless_fit.py` (fit, extract) | GPU node (Linux; CPU works for tiny tests only) |
| Interactive steps (noise calibration, group-setting widget) | Workstation notebook, optional |
| Grid movies / overlays | Wherever the videos and ffmpeg are; can be heavy |
| `kpms_summarise_results.py`, `dlc_metrics.*`, R analysis, figures | Local machine or login node (no GPU needed) |

## Rules that prevent common failures

1. **Never create `project_dir` before `setup_project`**: it refuses an existing folder (the script handles this; do not `mkdir` it).
2. **One JAX process per GPU.** JAX preallocates most GPU memory, so a second process on the same GPU runs out of memory. Job arrays: one task, one GPU, one model.
3. **Prepare once, then fan out.** For restarts or model selection run the script with `--prepare-only` first, then submit the array; concurrent tasks otherwise race on `config.yml`, QA files and `pca.p`.
4. **Reindex syllables before `extract_results`**: reindexing changes only the checkpoint. The script does this in the right order; if you do it by hand, re-extract results and redo any plots afterwards.
5. **Kappa is the main knob and is not transferable between the AR-HMM and full model**: the full model needs a lower kappa for the same durations. Tune on median syllable duration, not on syllable count. Re-fit after changing it.
6. **Do not interpret syllable numbers across separately fitted models.** Numbering is arbitrary per model (frequency-ordered after reindexing, which is not the same as matching).
7. **Recording names come from file names.** DLC names usually include a long `DLC_...` network suffix and multi-animal files become `<file>_<individual>`. Strip and map names to a metadata table explicitly and check for unmatched or duplicated keys.
8. **No display on compute nodes**: `MPLBACKEND=Agg`; interactive widgets (`noise_calibration`, `interactive_group_setting`) do not work headless. The script skips calibration; see the troubleshooting reference if NaNs appear.
9. **Pseudoreplication.** Frames and bouts are not independent. The unit is the recording, and recordings nest in animals. Model with animal random effects or aggregate to the animal.
10. **Many syllables means many tests.** Restrict to syllables above a stated usage threshold chosen before looking at group differences, and adjust (BH or similar). Syllable usage is compositional (shares sum to 1), so one syllable going up pushes others down.

## Helper packages (checked on CRAN 2026-10-23)

| Need | Package | Status in this skill |
|---|---|---|
| Movement metrics, ROI, speed in Python | `movement` (PyPI; v0.17.0) | Tested: path length and ROI time agree with the scripts within about 0.2%; polygon ROIs only, no circles, entries or immobility |
| Movement metrics in R | `animovement` (R-universe, installed with permission), `trajr` and `signal` (CRAN) | Tested: animovement distance and ROI time match the scripts; no polygon ROIs, entries or immobility; `.h5` works with Bioconductor rhdf5 (installed). See the reference |
| Read results.h5 in R | `hdf5r` (CRAN) | Tested: dimension order, nested groups, values equal to kpms CSV |
| Mixed models, censored latencies, GAMs | `glmmTMB`, `lme4`/`lmerTest`, `emmeans`, `DHARMa`, `coxme`, `mgcv` (general GLMM workflow in `mixed-models-glmm`; this skill covers only `coxme` latency, the GAM time course and kpms syllable models) | Tested on simulated data in `scripts/stats_demo.R` |
| Call Python from R/Quarto | `reticulate` | Mentioned only, not used (fitting belongs on the cluster) |
| Compositional usage | `DirichletReg`, `compositions` | Not tested |
| Multivariate usage tests | `vegan` + `permute` (PERMANOVA, whole-animal permutations) | Tested on simulated data in `scripts/stats_demo.R` |
| Transition graphs | `igraph`, `tidygraph`, `ggraph` | Not tested here |
| Classical trajectory metrics | `trajr` | Not tested; belongs to the later metrics part |
| Explicit HMMs on movement data | `momentuHMM`, `hmmTMB`, `moveHMM` | Different approach (parametric states on speed/turning), not a kpms substitute |
| Alternative R reader | `rhdf5` (Bioconductor, not CRAN) | Not used |

There is no CRAN package for keypoint-MoSeq itself; the fitting side is Python only.

## Files

- [references/dlc-basic-metrics.md](references/dlc-basic-metrics.md): pipeline and decisions for distance, speed, immobility and ROI metrics, worked numbers, statistics, existing tools incl. a tested animovement recipe and its gotchas (y-flip, fps, rhdf5).
- `scripts/dlc_metrics.py` and `scripts/dlc_metrics.R`: same-definition basic metrics from DLC csv/h5 (summary, per-frame, time bins).
- [references/keypoint-moseq-workflow.md](references/keypoint-moseq-workflow.md): API walk-through, config keys, kappa tuning, data requirements, advanced options.
- [references/hpc-and-troubleshooting.md](references/hpc-and-troubleshooting.md): install, GPU/JAX, version findings, job layout, errors, how to search upstream issues.
- [references/downstream-analysis.md](references/downstream-analysis.md): R and Python recipes, statistics, transitions, validation.
- [references/statistical-analysis.md](references/statistical-analysis.md): from metric tables to statistics (unit of analysis, tidy layout, which model for which metric, kpms built-in tests versus export, compositional cautions, Python route, reporting). Hands off the generic GLMM workflow to `mixed-models-glmm`.
- `scripts/stats_demo.R`: simulated 24-animal design with runnable templates for the tracking-specific analyses (latency, GAM time course, kpms syllable usage/transitions/bout durations); the Gamma/binomial/nbinom2/zero-inflation templates for the same design are in `mixed-models-glmm/scripts/glmm_templates.R`.
- `scripts/kpms_headless_fit.py`: resumable headless fit (run with `--help`).
- `scripts/kpms_summarise_results.py`: results.h5 to bouts/usage/transitions CSV.
- `scripts/kpms_results.R`: same summaries in R plus a frame-level reader.
- `assets/kpms_fit.sbatch`: Slurm template (single fit or array of seeds).

## Not verified

Basic-metrics scripts: tested on synthetic DLC-format CSV/h5 (single and multi-animal), R and Python agree, cross-checked against trajr, animovement and movement; not run on real recordings or other camera geometries. kpms: tested locally on Windows with kpms 0.6.6 and 0.8.0 (CPU, pandas<3; 0.8.0 only a short fit, resume, `kpms_summarise_results.py` and `compute_moseq_df`/`compute_stats_df`, not the full list below) on synthetic DLC-format CSVs: fresh fit, resume in the AR and full phases, concurrent seed fits, results extraction, R and Python summaries agree with each other and with kpms' CSV export. **Not tested:** GPU runs, kpms 0.8.0 concurrent seed fits and the R reader on 0.8.0 output, Slurm, multi-animal DLC files, real behavioural data, `apply_model`, grid movies, location-aware mode. If something fails on the cluster, trust the live docs and `help()` for the installed version over this file and tell the user which part was wrong.

## Related skills

- `mixed-models-glmm`: the generic GLMM fitting/diagnostics/reporting workflow (family choice, DHARMa, random effects, zero inflation, multiplicity, repeatability) that this skill's model tables and templates hand off to.
- `hpc-python-code` and `hpc-r-code`: code that runs the fits or analyses inside cluster jobs.
- `manuscript-figures-ggplot`: journal-ready figures from the summaries and model results.
- `data-repository-readme`: README and data dictionary for depositing the tracking data and metrics.
- `python-reproducible-pipeline`: wrapping DLC output, metrics, fits and statistics into one re-runnable, pinned workflow (Snakemake + uv).

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were done or not done: why this method, setting or tool was chosen, which alternative was rejected and why, which check or step was skipped, and which assumptions were made. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a package version or API differs from what it states, or it lacks guidance the task needs, record a generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
