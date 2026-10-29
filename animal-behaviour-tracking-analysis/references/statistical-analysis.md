# From extracted metrics to statistical analysis

## Contents

- [Principles](#principles)
- [Data layout: one tidy row per recording](#data-layout-one-tidy-row-per-recording)
- [Which model for which metric](#which-model-for-which-metric)
- [keypoint-MoSeq syllable data](#keypoint-moseq-syllable-data)
- [Python route (statsmodels)](#python-route-statsmodels)
- [Reporting checklist](#reporting-checklist)


This file covers what is specific to tracking data: how the extracted metrics map onto model choices, data layout, and a pointer to the syllable statistics (in the `keypoint-moseq` skill). **For the generic model-fitting workflow itself — choosing the family, diagnosing with DHARMa, random-effect structure, zero inflation, multiplicity, repeatability, reporting wording — use the `mixed-models-glmm` skill.** It owns that content and has the tested templates; this file used to duplicate them and now hands off instead. For GAM time courses use `gam-mgcv` (fitting) and `gam-interpretation` (plotting/inference).

Code specific to this domain (latency via `coxme`, the time-course GAM, and the keypoint-MoSeq syllable analyses) is in [scripts/stats_demo.R](../scripts/stats_demo.R), which simulates a 24-animal, 3-group, 2-session design (48 recordings). The Gamma/binomial/beta-binomial/nbinom2/zero-inflation/multiplicity templates for the same simulation design are in `mixed-models-glmm/scripts/glmm_templates.R`.

## Principles

1. **The experimental unit is the animal** (or whatever was randomised: cage, litter, mother). Frames, bouts and even recordings from one animal are not independent replicates. The number of animals per group sets the real sample size; many frames do not add power for a between-animal effect.
2. **Decide before looking**: primary endpoint(s), the model, exclusion rules (for example maximum `frac_missing_final`), which syllables are in scope. Everything else is exploratory and should be labelled so.
3. **Model the data type**: positive skewed (distance) is not Gaussian; shares of time are bounded; counts have exposure; latencies are censored; syllable usage is compositional.
4. **Report effect sizes with intervals** on a scale people can interpret (ratios, odds ratios, hazard ratios), not only p-values.
5. **Check the model**, not only the test: residuals (DHARMa), overdispersion, singular fits, influence of single animals.

## Data layout: one tidy row per recording

Build one metadata table first (one row per recording) and join every metric table to it by the recording key. Keys must match exactly; check for unmatched rows (see `downstream-analysis.md`, metadata join).

| Column | Notes |
|---|---|
| `recording` | key; file name without extension, DLC suffix removed |
| `animal` | the random-effect grouping factor; never omit it, even with one session per animal (then it is the recording) |
| `group` / treatment | between-animal factor; order the levels so the control is first |
| `day`, `session`, `time_of_day` | within-animal factors |
| `sex`, `batch`/`cage`, `weight`, `age` | covariates and blocking factors; include those known to affect the outcome |
| `duration_s`, `n_valid`, `frac_missing_final` | exposure and tracking quality; use as offsets, denominators, covariates or exclusion criteria |

Metrics come from `scripts/dlc_metrics.*` (`summary.csv`, `bins.csv`) or the `keypoint-moseq` skill's `kpms_summarise_results.py` / `kpms_results.R` (usage, bouts, transitions). Keep counts (frames, bouts, entries) as counts with their denominators; derive proportions inside the model, not before.

## Which model for which metric

Which family `mixed-models-glmm` picks for a given response, mapped onto the metric names this skill
produces (full workflow, diagnostics and pitfalls live there, not here):

| Metric from `dlc_metrics`/kpms summaries | Response type | Effect reported |
|---|---|---|
| Distance, mean speed | positive continuous | ratio of (geometric) means |
| Share of time in ROI or immobile | successes out of valid frames | odds ratio |
| Entries, bouts, events | count with exposure (`duration_s` offset) | rate ratio |
| Latency to first entry | time-to-event, never-entered = censored: `coxme(Surv(latency_s, event) ~ group + sex + (1|animal))` (not covered in `mixed-models-glmm`; the template is in `stats_demo.R`) | hazard ratio |
| Time course (per-minute bins) | GAM, see `gam-mgcv`/`gam-interpretation` | smooth differences |
| Bout durations, nested in animal/recording | positive continuous, nested random effect | ratio of geometric-mean duration |
| One transition probability | binomial on exits | odds ratio |

Design issues specific to tracking data that change which of the above applies — recordings nested in
animals, `frac_missing_final` as a covariate or exclusion rule, unbalanced/missing recordings — are noted
where each metric is defined in `dlc-basic-metrics.md`; the general logic (random intercepts vs slopes,
between- vs within-animal variance, multiplicity, singular fits, DHARMa) is in `mixed-models-glmm`.

## keypoint-MoSeq syllable data

Syllable usage, bouts and transitions have their own design issues (compositional closure, selection circularity, the limits of the built-in group test) and are covered in the `keypoint-moseq` skill (`references/syllable-statistics.md`). The runnable syllable templates (per-syllable negative binomial GLMM, PERMANOVA on usage, CLR + PCA, bout durations, transitions) stay in [scripts/stats_demo.R](../scripts/stats_demo.R) next to the latency and GAM templates, because they share one simulated design.

## Python route (statsmodels)

Tested on simulated data (statsmodels is a kpms dependency): a mixed model on log distance and, per syllable, a Poisson GEE with exposure offset and animal-clustered robust errors (accounts for overdispersion and repeated recordings; typically less informative than a negative-binomial GLMM):

```python
import numpy as np, statsmodels.api as sm, statsmodels.formula.api as smf
m = smf.mixedlm("np.log(distance) ~ C(group, Treatment('ctrl')) * day + sex", meta, groups=meta["animal"]).fit(reml=True)
g = smf.gee("n ~ C(group, Treatment('ctrl')) + day + sex", groups="animal", data=d, offset=np.log(d.total),
            family=sm.families.Poisson(), cov_struct=sm.cov_struct.Exchangeable()).fit()
```

Adjust p-values over syllables with `statsmodels.stats.multitest.multipletests(p, method="fdr_bh")`. For censored latencies, zero-inflated or beta-binomial models and DHARMa-style checks the R route is richer. `reticulate` is not needed: export CSV tables between the languages.

## Reporting checklist

- Design: animals per group, sessions per animal, recordings analysed and excluded (with reasons), tracking quality summary.
- Pipeline: DLC network and shuffle, likelihood threshold, gap rule, smoothing, calibration, immobility parameters, ROI definitions; for kpms the versions, seed, kappa, iterations, latent dimension, syllable threshold.
- Models: formula, family, random effects, how contrasts were computed, how multiplicity was handled, residual checks and any singular fits.
- Results: effect sizes with intervals for all pre-specified endpoints (also the null ones), plus raw per-animal data in the figure.
- Deposit: metadata table, metric tables, scripts and `stats_demo`-style analysis code (see the `reproducible-research-data` skill).
