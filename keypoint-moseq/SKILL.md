---
name: keypoint-moseq
description: Fits and interprets keypoint-MoSeq (kpms), unsupervised behavioural syllables from DeepLabCut, SLEAP or other 2D/3D keypoint tracking. Covers headless resumable fitting on GPU/HPC, kappa and syllable-duration tuning, species and frame-rate checks, noise calibration and other known user problems, grid movies, apply_model to new data, results.h5, and syllable usage, bout and transition analysis in R or Python. Use when the user mentions keypoint-MoSeq, kpms, MoSeq, behavioural syllables, kappa, results.h5, jax-moseq or syllable transitions. Not for depth-camera MoSeq (moseq2), B-SOiD, VAME or SimBA. For distance, speed, zone time or freezing from DLC output use animal-behaviour-tracking-analysis; for DLC tracking itself use deeplabcut-hpc.
metadata:
  prompt_signals: '\bkpms\b|keypoint[-_]moseq|\bjax[-_]moseq\b|\bkappa\b[^.?!\n]{0,60}\bsyllable'
  file_signals: 'import keypoint_moseq|from keypoint_moseq|\bjax_moseq\b|\bkpms\.[a-z_]+\('
---

# keypoint-MoSeq (kpms)

Scope: **downstream of keypoint tracking** (DLC, SLEAP, Lightning Pose). Unsupervised syllables with keypoint-MoSeq: model inputs, fitting, checking the fit, extracting `results.h5`, and analysing syllable usage, durations and transitions. Hypothesis-driven metrics (distance, speed, immobility, ROI) belong to `animal-behaviour-tracking-analysis`, which also owns the general statistics path for any metric table. Out of scope: other classification tools (SimBA, B-SOiD, VAME; the literature comparing them is summarised in [references/use-cases-and-literature.md](references/use-cases-and-literature.md)) and the **depth-camera MoSeq** predecessor (`moseq2-*`). Many papers write "MoSeq" for either, so ask which one the user means before applying anything here.

keypoint-moseq changes fast: about fifteen releases between 2026-10-20 and 2026-11-09 (0.6.13 to 0.8.7), several with breaking API or output changes (silently ignored renamed arguments, `compute_stats_df` signature, result-changing `stats_df`/`run_kruskal` fixes in 0.8.4, float32 fitting by default from 0.8.6 so refits are not reproducible from 0.8.5 seeds). **Do not rely on memory for signatures or config keys.** Check the installed version (`kpms.check_installation()`), the "Version changes that matter" table in [references/keypoint-moseq-workflow.md](references/keypoint-moseq-workflow.md), and the stable docs (https://keypoint-moseq.readthedocs.io/en/stable/) before writing code. What was read and run, and when: [references/tested-and-not-tested.md](references/tested-and-not-tested.md).

## Where this skill runs

The assistant runs only on the user's local machine, never on the cluster (same rules as `deeplabcut-hpc`). It writes and reviews scripts, runs the lightweight downstream analysis locally, and gives the user exact commands for the cluster, asking for the output pasted back. Do not attempt `sbatch`, `nvidia-smi` or `jax.devices()` cluster-side checks. Whenever information is needed that only the cluster can give (kpms/JAX/CUDA versions, GPU memory, logs), stop and ask for the specific command output.

## Workflow (copy and track)

1. **Check upstream tracking quality** (DLC): likelihoods, NaN proportions per recording and keypoint, identity swaps for multi-animal. kpms tolerates noise but not large NaN fractions or failed recordings; drop recordings whose tracking failed.
2. **Decide the model inputs**: 5-10 informative keypoints (no tail for rodents), anterior/posterior keypoints for heading, the real fps, which recordings are pooled. Run the "Species and frame-rate checks" below. See [references/keypoint-moseq-workflow.md](references/keypoint-moseq-workflow.md).
3. **Fit on a GPU node** with `scripts/kpms_headless_fit.py` and `assets/kpms_fit.sbatch` (lint with `hpc-job-scripts/scripts/check_sbatch.sh`). Load `hpc-cluster-docs` first. Details: [references/hpc-and-troubleshooting.md](references/hpc-and-troubleshooting.md).
4. **Check the fit**: median syllable duration versus target (kappa), number of syllables, stability across seeds (expected marginal likelihood, confusion matrix), and **watch grid movies or trajectory plots** before interpreting or naming any syllable.
5. **Extract** `results.h5` and summarise with `scripts/kpms_summarise_results.py` (Python, no JAX) or `scripts/kpms_results.R` (R, hdf5r).
6. **Analyse**: usage, durations and transitions in [references/downstream-analysis.md](references/downstream-analysis.md); which models and tests for syllable data (and what the built-in test does not do) in [references/syllable-statistics.md](references/syllable-statistics.md). The generic path from a metric table to models (and the simulated-design template that also holds the syllable model templates) is in the `animal-behaviour-tracking-analysis` skill, its statistical-analysis reference and `stats_demo.R`; the GLMM workflow itself is `mixed-models-glmm`.
7. **Record provenance**: kpms/jax versions, float32 or float64 (default float32 from 0.8.6), seed, kappa(s), iterations, latent_dim, model name, DLC model and shuffle, bodyparts used, fps.

When something fails or looks odd (calibration widget, NaNs, odd durations, `apply_model`, grid movies, trimming): [references/common-problems.md](references/common-problems.md) first, then the search-upstream steps at the end of `hpc-and-troubleshooting.md`.

## Species and frame-rate checks

kpms is documented for mice, rats and fruit flies only; no confirmed use on other species was found. For any other species, or a frame rate far from 30 fps, work through the seven checks (keypoints, target duration in frames, real `fps`, downsampling, body size, stationary periods, tracking quality per group) in [references/species-and-frame-rate.md](references/species-and-frame-rate.md) before fitting, and say that this skill has not tested it.

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
2. **One JAX process per GPU.** JAX preallocates 75% of GPU memory (FAQ), so a second process on the same GPU runs out of memory. Job arrays: one task, one GPU, one model.
3. **Prepare once, then fan out.** For restarts or model selection run the script with `--prepare-only` first, then submit the array; concurrent tasks otherwise race on `config.yml`, QA files and `pca.p`.
4. **Reindex syllables before `extract_results`**: reindexing changes only the checkpoint. The script does this in the right order; if you do it by hand, re-extract results and redo any plots afterwards.
5. **Kappa is the main knob and is not transferable between the AR-HMM and full model**: the full model needs a lower kappa for the same durations. Tune on median syllable duration, not on syllable count. Re-fit after changing it. A single-seed scan can mislead (seed-to-seed spread at one kappa has exceeded the kappa effect): replicate seeds at the chosen kappa and check the median duration of the final multi-seed fits.
6. **Do not interpret syllable numbers across separately fitted models.** Numbering is arbitrary per model (frequency-ordered after reindexing, which is not the same as matching).
7. **Check bodypart order across files before pooling.** `load_keypoints` assigns bodyparts by position from the first file, silently mislabelling a file with a different column order; `kpms_headless_fit.py` compares headers first. Details: `common-problems.md`.
8. **Recording names come from file names** (DLC suffixes, `<file>_<individual>`): map them to a metadata table and check for unmatched or duplicated keys. `apply_model` on new data with an existing name overwrites that recording's results (upstream #218). Details: `common-problems.md`.
9. **No display on compute nodes**: `MPLBACKEND=Agg`; interactive widgets (`noise_calibration`, `interactive_group_setting`) do not work headless. The script skips calibration; if NaNs appear see the NaN rows in `common-problems.md`.
10. **Jitter is a last resort, not a free fix for NaNs.** Check the data first; it acts only in the serial Kalman sampler, not the GPU default. Details: `common-problems.md` (Jitter and NaNs).
11. **Pseudoreplication.** Frames and bouts are not independent. The unit is the recording, and recordings nest in animals. Model with animal random effects or aggregate to the animal.
12. **Many syllables means many tests.** Restrict to syllables above a stated usage threshold chosen before looking at group differences, and adjust (BH or similar). Syllable usage is compositional (shares sum to 1), so one syllable going up pushes others down.

## Files

- [references/keypoint-moseq-workflow.md](references/keypoint-moseq-workflow.md): API walk-through, version changes, config keys, kappa tuning (with values used in published studies), checking the fit, applying a model, data requirements.
- [references/hpc-and-troubleshooting.md](references/hpc-and-troubleshooting.md): install, GPU/JAX, version findings, job layout, errors, how to search upstream issues.
- [references/common-problems.md](references/common-problems.md): calibration troubleshooting table and the recurring user problems from the upstream issue tracker (NaNs, odd durations, `apply_model`, trimming, grid movies, multi-GPU), with the maintainers' answers.
- [references/downstream-analysis.md](references/downstream-analysis.md): R and Python recipes, transitions, validation and reporting, the kpms built-in analysis, helper packages (no CRAN package for kpms itself; fitting is Python only).
- [references/syllable-statistics.md](references/syllable-statistics.md): kpms built-in tests versus export, models per question, cautions, and what published studies did.
- [references/use-cases-and-literature.md](references/use-cases-and-literature.md): publication, use cases found in citing papers, non-rodent evidence, comparisons with other tools, open questions.
- [references/species-and-frame-rate.md](references/species-and-frame-rate.md): seven checks for non-rodent species and other frame rates.
- [references/tested-and-not-tested.md](references/tested-and-not-tested.md): versions and tests run, what is unverified.
- `scripts/kpms_headless_fit.py`: resumable headless fit (run with `--help`).
- `scripts/kpms_summarise_results.py`: results.h5 to bouts/usage/transitions CSV.
- `scripts/kpms_results.R`: same summaries in R plus a frame-level reader.
- `assets/kpms_fit.sbatch`: Slurm template (single fit or array of seeds).

## Watch for bug candidates

Throughout the work, keep an eye out for errors, unexpected behaviour, or deviations from the documentation (a documented argument ignored, output that differs from what the docs describe, silent wrong results, NaNs or degenerate fits without a data explanation). When you see one, say so, check it against the live docs and the upstream issue tracker, and tell the user it may be worth reporting as a bug. Offer to draft the issue with kpms/jax versions, a minimal reproduction and the traceback; do not file it yourself. Upstream is `dattalab/keypoint-moseq` (no issue template; read its CONTRIBUTING.md first). The general procedure is in the `upstream-bug-report` skill.

## Not verified

Tested on CPU with synthetic DLC-format data only; GPU, Slurm, real data, `apply_model`, grid movies, the calibration widget and other species are untested ([references/tested-and-not-tested.md](references/tested-and-not-tested.md)). If something fails on the cluster, trust the live docs and `help()` for the installed version over this file and tell the user which part was wrong.

## Related skills

- `animal-behaviour-tracking-analysis`: basic metrics from DLC output (distance, speed, immobility, ROI), the cross-check for syllable results, and the general path from metric tables to statistics.
- `deeplabcut-hpc`: producing the DLC tracking that goes into kpms.
- `mixed-models-glmm`: the generic GLMM fitting/diagnostics/reporting workflow that the syllable models hand off to.
- `gam-mgcv`: time-resolved or peri-stimulus syllable usage as a GAM.
- `hpc-python-code`: Python code that runs the fits inside cluster jobs.
- `manuscript-figures-ggplot`: journal-ready figures from the summaries and model results.
- `upstream-bug-report`: checking a suspected kpms bug against upstream issues and drafting a redacted report.
- `python-reproducible-pipeline`: wrapping tracking, fits and statistics into one re-runnable, pinned workflow (Snakemake + uv).
- `openalex`: follow-up literature searches on kpms use cases.

## Explain the reasoning (teaching rule)

Teach, don't replace the user's thinking: say briefly (a sentence or two) why things were or were not done, name the trade-off and which decision is the user's, and point to a reference for depth.

## Capture lessons (self-improvement rule)

Load the `skill-lessons` skill and append a generic, anonymised entry (no project data, IDs or paths) as soon as something unanticipated happens: an error or warning, advice or code that failed, a user correction, a version or API mismatch, missing guidance, or a recommendation that held up (`worked-well`). Also write one `use-case` entry per session. When unsure, record it with `generality: unsure`. Entries are hypotheses for `skill-feedback-triage`.
