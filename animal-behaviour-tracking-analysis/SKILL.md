---
name: animal-behaviour-tracking-analysis
description: Turns DeepLabCut (DLC) pose output into hypothesis-driven behavioural metrics in R or Python (likelihood masking, gap interpolation, pixel-to-cm calibration, smoothing, distance, speed, immobility/freezing bouts, time in ROI/zone, entries, latency, time bins) and maps the metric tables to statistics (unit of analysis, tidy layout, which model for which metric). Use when the user mentions DLC csv/h5 output analysis, velocity, distance travelled, time in zone, open field, elevated plus maze, freezing, immobility, ROI or latency. Not for unsupervised behavioural syllables or keypoint-MoSeq (use keypoint-moseq), not for training or running the DLC network (use deeplabcut-hpc); generic GLMM fitting belongs to mixed-models-glmm.
---

# Animal behaviour tracking analysis (DLC to behavioural metrics)

Scope: **downstream of DLC**, hypothesis-driven basic metrics (distance, speed, immobility, time in ROI, entries, latency, path shape) with `scripts/dlc_metrics.py` / `dlc_metrics.R`, see [references/dlc-basic-metrics.md](references/dlc-basic-metrics.md), and the path from any metric table to statistics, see [references/statistical-analysis.md](references/statistical-analysis.md). **Unsupervised syllables with keypoint-MoSeq are in the `keypoint-moseq` skill** (fitting, results.h5, syllable statistics). Out of scope: other behaviour-classification tools (SimBA, B-SOiD, VAME). If the user asks for those, say this skill does not cover them.

## Where this skill runs

The assistant runs only on the user's local machine. The metric scripts run locally on DLC csv/h5 files and need no cluster. DLC tracking itself runs on a GPU node (`deeplabcut-hpc`; the assistant does not run on the cluster there either). If a step needs information only the cluster has, ask the user to run the specific command and paste back the output.

## Workflow (copy and track)

1. **Check upstream tracking quality** (DLC): likelihoods, NaN proportions per recording and keypoint, identity swaps for multi-animal. Decide the likelihood threshold and gap rule before looking at group differences.
2. **Calibrate** pixels to cm from a known arena dimension, define ROIs, and set the smoothing and immobility parameters (document them; see the reference for the decisions and worked numbers).
3. **Compute** the metrics with `scripts/dlc_metrics.py` or `scripts/dlc_metrics.R` (same definitions in both; summary, per-frame and time-bin outputs).
4. **Validate** immobility/freezing against manual scoring on a sample (`validate_immobile()` / `--manual-immobile`) before using it for inference; the thresholds have so far been tested only on synthetic data.
5. **Analyse**: build the tidy table (one row per recording, joined to metadata) and choose the model per metric in [references/statistical-analysis.md](references/statistical-analysis.md); templates in `scripts/stats_demo.R`. For the generic GLMM workflow itself, use `mixed-models-glmm` and its `glmm_templates.R`.
6. **Record provenance**: DLC network and shuffle, thresholds, gap rule, smoothing, calibration, ROI definitions, immobility parameters.

For exploratory discovery of behavioural modules instead of pre-defined measures, use `keypoint-moseq`. A simple metric (speed, immobility) is also the cheapest cross-check of what syllables seem to show.

## Rules that prevent common failures

1. **Recording names come from file names.** DLC names usually include a long `DLC_...` network suffix and multi-animal files become `<file>_<individual>`. Strip and map names to a metadata table explicitly and check for unmatched or duplicated keys.
2. **Pseudoreplication.** Frames and bouts are not independent. The unit is the recording, and recordings nest in animals. Model with animal random effects or aggregate to the animal.
3. **Tracking quality can masquerade as behaviour.** If groups differ in NaN fraction or likelihood, compare tracking quality first.
4. **Image y axis points down** (and fps must be the real one); the reference lists the gotchas found when cross-checking against other tools.
5. **Thresholds are decisions, not defaults.** Immobility speed and duration, likelihood cut-off and gap length change the numbers; fix them in advance and report them.

## Helper packages (checked on CRAN 2026-10-23)

| Need | Package | Status in this skill |
|---|---|---|
| Movement metrics, ROI, speed in Python | `movement` (PyPI; v0.17.0) | Tested: path length and ROI time agree with the scripts within about 0.2%; polygon ROIs only, no circles, entries or immobility |
| Movement metrics in R | `animovement` (R-universe, installed with permission), `trajr` and `signal` (CRAN) | Tested: animovement distance and ROI time match the scripts; no polygon ROIs, entries or immobility; `.h5` works with Bioconductor rhdf5 (installed). See the reference |
| Mixed models, censored latencies, GAMs | `glmmTMB`, `lme4`/`lmerTest`, `emmeans`, `DHARMa`, `coxme`, `mgcv` (general GLMM workflow in `mixed-models-glmm`; this skill covers only `coxme` latency, the GAM time course and the kpms syllable templates in `stats_demo.R`) | Tested on simulated data in `scripts/stats_demo.R` |
| Classical trajectory metrics | `trajr` | Used as a cross-check in the reference |

## Files

- [references/dlc-basic-metrics.md](references/dlc-basic-metrics.md): pipeline and decisions for distance, speed, immobility and ROI metrics, worked numbers, statistics, existing tools incl. a tested animovement recipe and its gotchas (y-flip, fps, rhdf5).
- `scripts/dlc_metrics.py` and `scripts/dlc_metrics.R`: same-definition basic metrics from DLC csv/h5 (summary, per-frame, time bins).
- [references/statistical-analysis.md](references/statistical-analysis.md): from metric tables to statistics (unit of analysis, tidy layout, which model for which metric, Python route, reporting). Hands off the generic GLMM workflow to `mixed-models-glmm` and the syllable statistics to `keypoint-moseq`.
- `scripts/stats_demo.R`: simulated 24-animal design with runnable templates for the tracking-specific analyses (latency, GAM time course, kpms syllable usage/transitions/bout durations); the Gamma/binomial/nbinom2/zero-inflation templates for the same design are in `mixed-models-glmm/scripts/glmm_templates.R`.

## Not verified

Basic-metrics scripts: tested on synthetic DLC-format CSV/h5 (single and multi-animal), R and Python agree, cross-checked against trajr, animovement and movement; not run on real recordings or other camera geometries. Both scripts have a `validate_immobile()`/`--manual-immobile` check against manual scoring (see "Synthetic validation versus real recordings" in `references/dlc-basic-metrics.md`), tested on synthetic data in R and Python agreeing with each other, but not yet run against real manual scoring. The statistics templates are tested on simulated data only. If something fails, trust the live package documentation for the installed version over this file and tell the user which part was wrong.

## Related skills

- `keypoint-moseq`: unsupervised behavioural syllables from the same tracking (fitting, results.h5, syllable usage and transition statistics).
- `deeplabcut-hpc`: producing the DLC tracking that goes into the metrics.
- `mixed-models-glmm`: the generic GLMM fitting/diagnostics/reporting workflow (family choice, DHARMa, random effects, zero inflation, multiplicity, repeatability) that this skill's model tables and templates hand off to.
- `gam-mgcv`: time-course (per-minute bin) models of a metric.
- `hpc-python-code` and `hpc-r-code`: code that runs the metrics or analyses inside cluster jobs.
- `manuscript-figures-ggplot`: journal-ready figures from the summaries and model results.
- `data-repository-readme`: README and data dictionary for depositing the tracking data and metrics.
- `tidy-data-wrangling`: reshaping, cleaning and joining the metric tables before analysis (wide to long, missing codes, keys).
- `python-reproducible-pipeline`: wrapping DLC output, metrics and statistics into one re-runnable, pinned workflow (Snakemake + uv).

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were done or not done: why this method, setting or tool was chosen, which alternative was rejected and why, which check or step was skipped, and which assumptions were made. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a package version or API differs from what it states, or it lacks guidance the task needs, record a generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
