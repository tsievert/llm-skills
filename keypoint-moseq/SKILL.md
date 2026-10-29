---
name: keypoint-moseq
description: Fits and interprets keypoint-MoSeq (kpms), unsupervised behavioural syllables from DeepLabCut, SLEAP or other 2D/3D keypoint tracking. Covers headless resumable fitting on GPU/HPC, kappa and syllable-duration tuning, species and frame-rate checks, noise calibration and other known user problems, grid movies, apply_model to new data, results.h5, and syllable usage, bout and transition analysis in R or Python. Use when the user mentions keypoint-MoSeq, kpms, MoSeq, behavioural syllables, kappa, results.h5, jax-moseq or syllable transitions. Not for depth-camera MoSeq (moseq2), B-SOiD, VAME or SimBA. For distance, speed, zone time or freezing from DLC output use animal-behaviour-tracking-analysis; for DLC tracking itself use deeplabcut-hpc.
metadata:
  prompt_signals: '\bkpms\b|keypoint[-_]moseq|\bjax[-_]moseq\b|\bkappa\b[^.?!\n]{0,60}\bsyllable'
  file_signals: 'import keypoint_moseq|from keypoint_moseq|\bjax_moseq\b|\bkpms\.[a-z_]+\('
---

# keypoint-MoSeq (kpms)

Scope: **downstream of keypoint tracking** (DLC, SLEAP, Lightning Pose). Unsupervised syllables with keypoint-MoSeq: model inputs, fitting, checking the fit, extracting `results.h5`, and analysing syllable usage, durations and transitions. Hypothesis-driven metrics (distance, speed, immobility, ROI) belong to `animal-behaviour-tracking-analysis`, which also owns the general statistics path for any metric table. Out of scope: other classification tools (SimBA, B-SOiD, VAME; the literature comparing them is summarised in [references/use-cases-and-literature.md](references/use-cases-and-literature.md)) and the **depth-camera MoSeq** predecessor (`moseq2-*`). Many papers write "MoSeq" for either, so ask which one the user means before applying anything here.

keypoint-moseq changes fast: roughly a dozen releases between 2026-10-20 and 2026-10-28 (0.6.13 to 0.8.3), several with breaking API or output changes (renamed arguments that are silently ignored, `compute_stats_df` signature, `check_videos`, loader behaviour, jax-moseq >= 0.3.8). **Do not rely on memory for signatures or config keys.** Check the installed version (`kpms.check_installation()`), the "Version changes that matter" table in [references/keypoint-moseq-workflow.md](references/keypoint-moseq-workflow.md), and the stable docs (https://keypoint-moseq.readthedocs.io/en/stable/) before writing code. Last full check against upstream: 2026-10-29, version 0.8.3.

## Where this skill runs

The assistant runs only on the user's local machine, never on the cluster (same rules as `deeplabcut-hpc`). It writes and reviews scripts, runs the lightweight downstream analysis locally, and gives the user exact commands for the cluster, asking for the output pasted back. Do not attempt `sbatch`, `nvidia-smi` or `jax.devices()` cluster-side checks. Whenever information is needed that only the cluster can give (kpms/JAX/CUDA versions, GPU memory, logs), stop and ask for the specific command output.

## Workflow (copy and track)

1. **Check upstream tracking quality** (DLC): likelihoods, NaN proportions per recording and keypoint, identity swaps for multi-animal. kpms tolerates noise but not large NaN fractions or failed recordings; drop recordings whose tracking failed.
2. **Decide the model inputs**: 5-10 informative keypoints (no tail for rodents), anterior/posterior keypoints for heading, the real fps, which recordings are pooled. Run the "Species and frame-rate checks" below. See [references/keypoint-moseq-workflow.md](references/keypoint-moseq-workflow.md).
3. **Fit on a GPU node** with `scripts/kpms_headless_fit.py` and `assets/kpms_fit.sbatch` (lint with `hpc-job-scripts/scripts/check_sbatch.sh`). Load `hpc-cluster-docs` first. Details: [references/hpc-and-troubleshooting.md](references/hpc-and-troubleshooting.md).
4. **Check the fit**: median syllable duration versus target (kappa), number of syllables, stability across seeds (expected marginal likelihood, confusion matrix), and **watch grid movies or trajectory plots** before interpreting or naming any syllable.
5. **Extract** `results.h5` and summarise with `scripts/kpms_summarise_results.py` (Python, no JAX) or `scripts/kpms_results.R` (R, hdf5r).
6. **Analyse**: usage, durations and transitions in [references/downstream-analysis.md](references/downstream-analysis.md); which models and tests for syllable data (and what the built-in test does not do) in [references/syllable-statistics.md](references/syllable-statistics.md). The generic path from a metric table to models (and the simulated-design template that also holds the syllable model templates) is in the `animal-behaviour-tracking-analysis` skill, its statistical-analysis reference and `stats_demo.R`; the GLMM workflow itself is `mixed-models-glmm`.
7. **Record provenance**: kpms/jax versions, seed, kappa(s), iterations, latent_dim, model name, DLC model and shuffle, bodyparts used, fps.

When something fails or looks odd (calibration widget, NaNs, odd durations, `apply_model`, grid movies, trimming): [references/common-problems.md](references/common-problems.md) first, then the search-upstream steps at the end of `hpc-and-troubleshooting.md`.

## Species and frame-rate checks

What is documented: the Nature Methods paper (Weinreb et al. 2024) demonstrates mice (2D and 3D keypoints), rats (3D motion capture) and fruit flies (2D LEAP keypoints at 100 fps, where a different target timescale gave motifs from tens to hundreds of ms). A 2026-10 literature search of the citing papers found **no confirmed use on other species** (infants, zebrafish, macaques, marmosets, livestock and others only cite it or use their own models). Say that kpms is untested by this skill and unreported in what was searched for those animals, then work through these checks with the user:

1. **Keypoints**: enough informative points to read the behaviour from the keypoints alone (benchmarks use 7 to 21; a maintainer called 3 "really pushing it" for single-animal syllables). Drop unreliable points (rodent tails). Anterior and posterior points must exist and be rarely occluded: heading and egocentric alignment depend on them.
2. **Target duration in frames**: kappa is tuned to a median syllable duration, so the target is `duration x fps`. About 400 ms is the rodent rule of thumb (12 frames at 30 fps, 10 at 25, 8 at 20). For another species take the timescale of its movement units from the literature or the user, then confirm with grid movies. Do not compare durations or syllable numbers across species or frame rates.
3. **Frame rate**: set the real `fps` in the config (0.8.0 uses it for velocities and durations). At 100-200 fps the same target is many more frames, so kappa may need to be higher than the docs scan (upper end 1e7, "typically high enough" per a maintainer). Rescan kappa; never copy a value from another setup (published values span 1e-6 to 1e10).
4. **Downsampling** (for example 200 to 40 fps) is documented but one thread on it (#153) was never resolved; if used, compare `len(coordinates[key])` with video frame counts and delete stale `error_annotations.csv` first. See [references/common-problems.md](references/common-problems.md).
5. **Body size and setup**: animals of very different size (adults and pups) need separate models; a changed camera or keypoint set needs a refit, not `apply_model`.
6. **Stationary periods** (long sleep or inactivity) are hard for the autoregressive model and can end fits in NaNs; mask still periods with a centroid-speed rule and model the active periods.
7. **Tracking quality per group**: compare NaN proportions between groups before reading differences in usage as behaviour.

Cross-checking with a simple alternative (speed and immobility from `animal-behaviour-tracking-analysis`) is cheap and worth doing for a new species.

## What runs where

| Step | Where |
|---|---|
| DLC tracking | GPU node (`deeplabcut-hpc`) |
| `kpms_headless_fit.py` (fit, extract) | GPU node (Linux; CPU works for tiny tests only) |
| Interactive steps (noise calibration, group-setting widget) | Workstation notebook (JupyterLab with `%matplotlib widget`), optional |
| Grid movies / overlays | Wherever the videos and ffmpeg are; can be heavy |
| `kpms_summarise_results.py`, R analysis, figures | Local machine or login node (no GPU needed) |

## Rules that prevent common failures

1. **Never create `project_dir` before `setup_project`**: it refuses an existing folder (the script handles this; do not `mkdir` it).
2. **One JAX process per GPU.** JAX preallocates most GPU memory, so a second process on the same GPU runs out of memory. Job arrays: one task, one GPU, one model.
3. **Prepare once, then fan out.** For restarts or model selection run the script with `--prepare-only` first, then submit the array; concurrent tasks otherwise race on `config.yml`, QA files and `pca.p`.
4. **Reindex syllables before `extract_results`**: reindexing changes only the checkpoint. The script does this in the right order; if you do it by hand, re-extract results and redo any plots afterwards.
5. **Kappa is the main knob and is not transferable between the AR-HMM and full model**: the full model needs a lower kappa for the same durations. Tune on median syllable duration, not on syllable count. Re-fit after changing it.
6. **Do not interpret syllable numbers across separately fitted models.** Numbering is arbitrary per model (frequency-ordered after reindexing, which is not the same as matching).
7. **Check bodypart order across files before pooling.** `load_keypoints` takes the bodyparts from the first file and assigns the others by position, silently mislabelling a file with a different column order (tested on 0.8.3). `scripts/kpms_headless_fit.py` compares the csv/h5 headers first and exits listing the differing files (`--skip-header-check` to override); if you load files another way, check the headers yourself.
8. **Recording names come from file names.** DLC names usually include a long `DLC_...` network suffix and multi-animal files become `<file>_<individual>`. Strip and map names to a metadata table explicitly and check for unmatched or duplicated keys. Results are keyed by recording name, so `apply_model` on new data with a name that already exists overwrites that recording's results (upstream #218): check `coordinates.keys()` of old and new data differ.
9. **No display on compute nodes**: `MPLBACKEND=Agg`; interactive widgets (`noise_calibration`, `interactive_group_setting`) do not work headless. The script skips calibration; if NaNs appear see the NaN rows in `common-problems.md`.
10. **Jitter is a last resort, not a free fix for NaNs.** The docs suggest raising `jitter` from 1e-3 to 1e-2 or 1e-1 when fitting yields NaNs. In an upstream thread (#153) the maximum, 1e-1, on NaN-heavy 200 fps data produced odd centroid coordinates and tiny trajectory plots, while 1e-2 on the same data gave normal plots. Raise it one step at a time, look at trajectory plots after each change, and fix the cause (failed recordings, still periods, float precision) first.
11. **Pseudoreplication.** Frames and bouts are not independent. The unit is the recording, and recordings nest in animals. Model with animal random effects or aggregate to the animal.
12. **Many syllables means many tests.** Restrict to syllables above a stated usage threshold chosen before looking at group differences, and adjust (BH or similar). Syllable usage is compositional (shares sum to 1), so one syllable going up pushes others down.

## Helper packages (checked on CRAN 2026-10-23)

| Need | Package | Status in this skill |
|---|---|---|
| Read results.h5 in R | `hdf5r` (CRAN) | Tested: dimension order, nested groups, values equal to kpms CSV |
| Mixed models, GAMs for syllable data | `glmmTMB`, `lme4`/`lmerTest`, `emmeans`, `DHARMa`, `mgcv` (general workflow in `mixed-models-glmm`) | Tested on simulated data in `stats_demo.R` of `animal-behaviour-tracking-analysis` |
| Compositional usage | `DirichletReg`, `compositions` | Not tested |
| Multivariate usage tests | `vegan` + `permute` (PERMANOVA, whole-animal permutations) | Tested on simulated data in `stats_demo.R` |
| Transition graphs | `igraph`, `tidygraph`, `ggraph` | Not tested here |
| Call Python from R/Quarto | `reticulate` | Mentioned only, not used (fitting belongs on the cluster) |
| Explicit HMMs on movement data | `momentuHMM`, `hmmTMB`, `moveHMM` | Different approach (parametric states on speed/turning), not a kpms substitute |
| Alternative R reader | `rhdf5` (Bioconductor) | Not used |

There is no CRAN package for keypoint-MoSeq itself; the fitting side is Python only.

## Files

- [references/keypoint-moseq-workflow.md](references/keypoint-moseq-workflow.md): API walk-through, version changes, config keys, kappa tuning (with values used in published studies), checking the fit, applying a model, data requirements.
- [references/hpc-and-troubleshooting.md](references/hpc-and-troubleshooting.md): install, GPU/JAX, version findings, job layout, errors, how to search upstream issues.
- [references/common-problems.md](references/common-problems.md): calibration troubleshooting table and the recurring user problems from the upstream issue tracker (NaNs, odd durations, `apply_model`, trimming, grid movies, multi-GPU), with the maintainers' answers.
- [references/downstream-analysis.md](references/downstream-analysis.md): R and Python recipes, transitions, validation and reporting, the kpms built-in analysis.
- [references/syllable-statistics.md](references/syllable-statistics.md): kpms built-in tests versus export, models per question, cautions, and what published studies did.
- [references/use-cases-and-literature.md](references/use-cases-and-literature.md): publication, use cases found in citing papers, non-rodent evidence, comparisons with other tools, open questions.
- `scripts/kpms_headless_fit.py`: resumable headless fit (run with `--help`).
- `scripts/kpms_summarise_results.py`: results.h5 to bouts/usage/transitions CSV.
- `scripts/kpms_results.R`: same summaries in R plus a frame-level reader.
- `assets/kpms_fit.sbatch`: Slurm template (single fit or array of seeds).

## Not verified

kpms: tested locally on Windows with kpms 0.6.6, 0.8.0 and 0.8.3 (CPU; 0.6.6 and 0.8.0 with pandas<3; 0.8.0 and 0.8.3 only a short fit, resume, `kpms_summarise_results.py`, the R reader and `compute_moseq_df`/`compute_stats_df`, pandas 3.1.0 on 0.8.3, not the full list below) on synthetic DLC-format CSVs: fresh fit, resume in the AR and full phases, concurrent seed fits, results extraction, R and Python summaries agree with each other and with kpms' CSV export. **Not tested:** GPU runs, kpms 0.8.x concurrent seed fits, Slurm, 0.8.3's SLEAP/Lightning Pose/`.h5` loaders (the DLC csv loader was tested on synthetic multi-animal data, including a silent bodyparts-order mismatch across files, see the workflow reference), real behavioural data, `apply_model`, grid movies, location-aware mode, the calibration widget, any species other than those in the paper. The troubleshooting content in `common-problems.md` comes from reading upstream issues and papers (2026-10-29), not from reproducing the problems. If something fails on the cluster, trust the live docs and `help()` for the installed version over this file and tell the user which part was wrong.

## Related skills

- `animal-behaviour-tracking-analysis`: basic metrics from DLC output (distance, speed, immobility, ROI), the cross-check for syllable results, and the general path from metric tables to statistics.
- `deeplabcut-hpc`: producing the DLC tracking that goes into kpms.
- `mixed-models-glmm`: the generic GLMM fitting/diagnostics/reporting workflow that the syllable models hand off to.
- `gam-mgcv`: time-resolved or peri-stimulus syllable usage as a GAM.
- `hpc-python-code`: Python code that runs the fits inside cluster jobs.
- `manuscript-figures-ggplot`: journal-ready figures from the summaries and model results.
- `python-reproducible-pipeline`: wrapping tracking, fits and statistics into one re-runnable, pinned workflow (Snakemake + uv).
- `openalex`: follow-up literature searches on kpms use cases.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were done or not done: why this method, setting or tool was chosen, which alternative was rejected and why, which check or step was skipped, and which assumptions were made. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a package version or API differs from what it states, or it lacks guidance the task needs, record a generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
