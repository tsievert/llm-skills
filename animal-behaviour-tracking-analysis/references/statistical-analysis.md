# From extracted metrics to statistical analysis

Contents: principles, data layout, choosing the model, basic-metric templates, design issues, keypoint-MoSeq (what is built in, what to do instead), Python route, reporting.

All code below is in [scripts/stats_demo.R](../scripts/stats_demo.R), which simulates a 24-animal, 3-group, 2-session design (48 recordings) and runs every model. It is a set of templates tested for running correctly on simulated data. It does not replace choosing the model for your design, and the effects it finds are the ones built into the simulation. For modelling depth see the `gam-mgcv` and `gam-interpretation` skills (time courses) and the planned `mixed-models-glmm` skill.

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

Metrics come from `scripts/dlc_metrics.*` (`summary.csv`, `bins.csv`) or `scripts/kpms_summarise_results.py` / `kpms_results.R` (usage, bouts, transitions). Keep counts (frames, bouts, entries) as counts with their denominators; derive proportions inside the model, not before.

## Which model for which metric

| Metric | Distribution and model (R) | Effect reported |
|---|---|---|
| Distance, mean speed (positive, skewed) | `glmmTMB(distance ~ group*day + sex + (1|animal), family = Gamma(log))` or `lmer(log(distance) ...)` | ratio of geometric means |
| Share of time in ROI or immobile | counts out of valid frames: `glmmTMB(cbind(n_in, n_valid - n_in) ~ ... + (1|animal), family = binomial)`; if overdispersed, `betabinomial` | odds ratio |
| Entries, bouts, events | `glmmTMB(count ~ ... + offset(log(duration_s)) + (1|animal), family = nbinom2)` | rate ratio |
| Latency to first entry | time-to-event, never entered = censored at session length: `coxme(Surv(latency_s, event) ~ group + sex + (1|animal))` or `survival::coxph(... + cluster(animal))` | hazard ratio |
| Time course (per-minute bins) | GAM: `bam(y ~ group + s(minute) + s(minute, by = group, m = 1) + s(animal, bs = "re") + s(recording, bs = "re"), family = Gamma(log))` | smooth differences, see `gam-interpretation` |
| Bout durations | `lmer(log(dur_s) ~ group + (1|animal/recording))` | ratio of geometric-mean duration |
| One transition probability | `glmmTMB(cbind(to_B, from_total - to_B) ~ group + (1|animal), family = binomial)` | odds ratio |
| Several endpoints | adjust over the pre-specified family (Holm for few, BH for many) | adjusted p |

Group contrasts with `emmeans`: `pairs(emmeans(m, ~ group), type = "response")` returns ratios with the multiplicity adjustment (Tukey by default). If `group` interacts with `day`, the averaged contrast hides it; emmeans prints a note, so look at `~ group | day`.

### What the simulated runs showed (illustration, not evidence)

- Binomial model on ROI frame counts: DHARMa dispersion test p about 0 and AIC 4915; beta-binomial AIC 763. Frame counts are strongly overdispersed between recordings, so a plain binomial reports confidence that is not warranted. Check this every time you model proportions of frames.
- With 8 animals per group, a built-in 22% reduction in distance was not detected (ratio about 1.06, p 0.86 after averaging); between-animal variance and few animals limit power. Plan sample size on animals, ideally with a simulation like this one using your pilot variance.
- Three endpoints (distance, ROI share, entries) adjusted together with Holm: only the ROI share stayed below 0.05 (raw p 0.0008, adjusted 0.0023); distance (0.11) and entries (0.60) did not.
- Random-effect variances can estimate at zero (`boundary (singular) fit` for the recording-within-animal term in the bout model). That is not an error by itself; simplify the random structure or report it.

## Design issues that change the model

- **Repeated sessions**: random intercept for animal is the minimum. Add a random slope for day only if there are enough sessions per animal to estimate it; with two sessions it is not identifiable. For many ordered sessions consider an autocorrelation term (`ar1()` in glmmTMB) or a GAM in time.
- **Recordings nested in animals**: `(1 | animal/recording)`; with one recording per animal-day and `day` fixed, `(1 | animal)` is enough.
- **Between- vs within-animal factors**: group effects are tested against between-animal variance; day effects against within-animal variance. Do not use residual degrees of freedom from frames.
- **Covariates**: include sex, batch, weight or age when relevant; add `frac_missing_final` as a covariate or run a sensitivity analysis excluding poorly tracked recordings.
- **Interactions**: test `group:day` first if it is of interest; interpret main effects carefully when it is present.
- **Missing recordings**: unbalanced data are fine for mixed models, but say why recordings are missing and whether the reason relates to group.
- **Multiple metrics**: nominate a primary endpoint; adjust the rest; do not scan 30 metrics and report the best.

## keypoint-MoSeq: what is built in, and why to export instead

Read from the kpms 0.6.6 source (not run on real data; check the current docs, since this can change):

- `interactive_group_setting` writes `index.csv` with two columns, `name` (recording) and `group`. The `group` label is the only metadata kpms can use.
- `plot_syll_stats_with_sem` runs `run_kruskal`, a permutation Kruskal-Wallis test per syllable with Benjamini-Hochberg correction across syllables, then Dunn's pairwise tests. This works for more than two groups; `ctrl_group` and `exp_group` only choose which pair's significant syllables are marked on the plot. The plotted error bars are 68% intervals (about one SEM).
- The unit in the test is the recording (`name`): several recordings from one animal are treated as independent. There are no covariates (sex, day, batch), no interactions, no repeated-measures or nested structure, no effect size or interval, and the test is rank-based.

That is adequate for a quick look in a one-recording-per-animal, one-factor design. For anything with repeated sessions, covariates, more than one factor or a requirement to report effect sizes, export the tables and model them yourself.

### Export route

1. Fit and extract as usual, then summarise (`scripts/kpms_summarise_results.py` or `kpms_results.R`): `usage` (bouts and frames per recording and syllable, zeros included), `bouts`, `transitions`.
2. Join the metadata table by `recording`; keep `animal`, `group`, `sex`, `day` and so on.
3. Decide the syllable set before testing: syllables above a usage threshold (kpms uses `min_frequency` 0.005 in plots), stated in advance, and the same set for every model.
4. Pick the question and the model:

| Question | Model (R, in `stats_demo.R`) |
|---|---|
| Which syllables differ between groups? | Per syllable: `glmmTMB(n_bouts ~ group + day + sex + offset(log(total)) + (1|animal), family = nbinom2)`, overall group effect by likelihood-ratio test, rate ratios vs control with `emmeans`, Benjamini-Hochberg across **syllables** (not across contrast rows) |
| Does the whole repertoire differ? | PERMANOVA (`vegan::adonis2`) on Hellinger-transformed shares with whole-animal permutations: `how(plots = Plots(strata = animal, type = "free"), within = Within(type = "none"))`; check `betadisper` since PERMANOVA also reacts to differences in spread |
| Low-dimensional summary | Centred log-ratio of shares (pseudocount is a choice; report it), PCA, then `lmer(PC1 ~ group*day + sex + (1|animal))` |
| Do bouts last longer? | Bout-level `lmer(log(dur_s) ~ group + (1|animal/recording))`, overall or for a pre-chosen syllable |
| Do transitions change? | One transition at a time: binomial GLMM with successes = exits to B out of all exits from A; restrict to pre-specified, well-sampled transitions |
| Change within a session | Per-minute usage as a GAM in time (`gam-mgcv`) |

5. Report the number of syllables tested, the threshold, the adjustment, effect sizes with intervals, and run the same analysis on models from other seeds to see whether conclusions hold (syllable numbers are not comparable across models, so compare behaviours via grid movies, not numbers).

### Cautions specific to syllable data

- **Compositional closure**: usage shares sum to 1, so a real increase in one syllable lowers others. In a Python simulation where only syllable 2 truly increased, syllable 0 also came out significantly "reduced" (rate ratio 0.58, BH-adjusted q 0.011). Interpret per-syllable decreases cautiously, give shares and absolute counts, and consider the repertoire-level tests.
- **Selection circularity**: choosing syllables for a figure because they differ, then testing them, inflates significance. Use the pre-specified set, or confirm on held-out animals (apply the fitted model to new recordings with `apply_model`).
- **Fit on all animals**: the model is unsupervised and does not see group labels, so fitting it to all recordings is acceptable, but syllable boundaries may reflect session or camera differences. Check that syllables are not driven by batch or setup.
- **Usage from frames or bouts**: bouts reflect how often a syllable starts, frames also reflect how long it lasts. Report both and say which the test used.

## Python route (statsmodels)

Tested on simulated data in the kpms environment (statsmodels is a kpms dependency): a mixed model on log distance and, per syllable, a Poisson GEE with exposure offset and animal-clustered robust errors (accounts for overdispersion and repeated recordings; typically less informative than a negative-binomial GLMM):

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
- Deposit: metadata table, metric tables, scripts and `stats_demo`-style analysis code (see the planned `reproducible-research-data` skill).
