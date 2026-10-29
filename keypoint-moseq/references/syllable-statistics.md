# Statistics for keypoint-MoSeq syllable data

## Contents

- [Scope](#scope)
- [What is built in, and why to export instead](#what-is-built-in-and-why-to-export-instead)
- [Export route](#export-route)
- [Cautions specific to syllable data](#cautions-specific-to-syllable-data)
- [What published studies did](#what-published-studies-did)
- [Python route (statsmodels)](#python-route-statsmodels)

## Scope

Syllable-specific statistics. The generic path (unit of analysis, tidy layout, which model for which metric, reporting) is in `animal-behaviour-tracking-analysis` (`references/statistical-analysis.md`), runnable templates are in its `scripts/stats_demo.R` (simulated 24-animal, 3-group, 2-session design), and the family choice, DHARMa checks, random effects and multiplicity are in `mixed-models-glmm`. Syllable tables come from `scripts/kpms_summarise_results.py` or `scripts/kpms_results.R` (see `downstream-analysis.md`).

## What is built in, and why to export instead

Read from the kpms 0.6.6 source, with the `run_kruskal` signature rechecked in 0.8.3 (not run on real data; 0.8.2 fixed `run_kruskal` reporting syllable labels wrongly, so re-run any 0.8.1 or older built-in tests before trusting the labels):

- `interactive_group_setting` writes `index.csv` with two columns, `name` (recording) and `group`. The `group` label is the only metadata kpms can use.
- `plot_syll_stats_with_sem` runs `run_kruskal`, a permutation Kruskal-Wallis test per syllable with Benjamini-Hochberg correction across syllables, then Dunn's pairwise tests. This works for more than two groups; `ctrl_group` and `exp_group` only choose which pair's significant syllables are marked on the plot. The plotted error bars are 68% intervals (about one SEM). The maintainers confirmed the test and the FDR step in upstream issues #226 and #260 (and added them to the FAQ).
- The unit in the test is the recording (`name`): several recordings from one animal are treated as independent. There are no covariates (sex, day, batch), no interactions, no repeated-measures or nested structure, no effect size or interval, and the test is rank-based.

That is adequate for a quick look in a one-recording-per-animal, one-factor design. For anything with repeated sessions, covariates, more than one factor or a requirement to report effect sizes, export the tables and model them yourself.

## Export route

1. Fit and extract as usual, then summarise: `usage` (bouts and frames per recording and syllable, zeros included), `bouts`, `transitions`.
2. Join the metadata table by `recording`; keep `animal`, `group`, `sex`, `day` and so on.
3. Decide the syllable set before testing: syllables above a usage threshold (kpms uses `min_frequency` 0.005 in plots), stated in advance, and the same set for every model.
4. Pick the question and the model:

| Question | Model (R, in `animal-behaviour-tracking-analysis/scripts/stats_demo.R`) |
|---|---|
| Which syllables differ between groups? | Per syllable: `glmmTMB(n_bouts ~ group + day + sex + offset(log(total)) + (1|animal), family = nbinom2)`, overall group effect by likelihood-ratio test, rate ratios vs control with `emmeans`, Benjamini-Hochberg across **syllables** (not across contrast rows) |
| Does the whole repertoire differ? | PERMANOVA (`vegan::adonis2`) on Hellinger-transformed shares with whole-animal permutations: `how(plots = Plots(strata = animal, type = "free"), within = Within(type = "none"))`; check `betadisper` since PERMANOVA also reacts to differences in spread |
| Low-dimensional summary | Centred log-ratio of shares (pseudocount is a choice; report it), PCA, then `lmer(PC1 ~ group*day + sex + (1|animal))` |
| Do bouts last longer? | Bout-level `lmer(log(dur_s) ~ group + (1|animal/recording))`, overall or for a pre-chosen syllable |
| Do transitions change? | One transition at a time: binomial GLMM with successes = exits to B out of all exits from A; restrict to pre-specified, well-sampled transitions. Whole-matrix comparisons: a distance between condition-averaged matrices (per-animal matrices first) with a permutation test that shuffles whole animals |
| Change within a session or around a stimulus | Per-minute (or per peri-stimulus bin) usage as a GAM in time (`gam-mgcv`), or a paired comparison of before and after bins per animal |

5. Report the number of syllables tested, the threshold, the adjustment, effect sizes with intervals, and run the same analysis on models from other seeds to see whether conclusions hold (syllable numbers are not comparable across models, so compare behaviours via grid movies, not numbers).

## Cautions specific to syllable data

- **Compositional closure**: usage shares sum to 1, so a real increase in one syllable lowers others. In a Python simulation where only syllable 2 truly increased, syllable 0 also came out significantly "reduced" (rate ratio 0.58, BH-adjusted q 0.011). Interpret per-syllable decreases cautiously, give shares and absolute counts, and consider the repertoire-level tests.
- **Selection circularity**: choosing syllables for a figure because they differ, then testing them, inflates significance. Use the pre-specified set, or confirm on held-out animals (apply the fitted model to new recordings with `apply_model`).
- **Fit on all animals**: the model is unsupervised and does not see group labels, so fitting it to all recordings is acceptable, but syllable boundaries may reflect session or camera differences. Check that syllables are not driven by batch or setup.
- **Usage from frames or bouts**: bouts reflect how often a syllable starts, frames also reflect how long it lasts. Report both and say which the test used.
- **Pooled or per-syllable tests treating syllables as independent**: syllables from one animal are correlated; this is why a per-syllable model needs the animal random effect.

## What published studies did

From the methods sections of four open-access citing papers read on 2026-10-29 (details in `use-cases-and-literature.md` and the research ledger). None of the four used a mixed model with animal as a random effect on syllable usage, so the recommendations above go beyond common practice; the reason is pseudoreplication (frames, bouts and recordings from one animal) and compositional closure.

- The kpms package's own Kruskal-Wallis with Dunn post hoc (Benjamini-Hochberg, FDR 0.05) for usage and velocity across conditions, plus an entropy rate of the transition matrix.
- Kruskal-Wallis with Dunn post hoc (Holm or FDR) on median motif durations when comparing tools.
- Chi-square proportion tests and Mann-Whitney tests with Bonferroni on syllable onset proportions and per-syllable transition probabilities; PCA on syllable usage and on transition ("syntax") proportions.
- A peri-stimulus design: syllable counts in 1-minute bins before and after a cue, an overall multivariate test (Hotelling's T-squared after a normality check), then per-syllable ANOVA or Kruskal-Wallis with post hoc tests; per-mouse transition matrices with self-transitions removed, averaged per condition, compared by Manhattan distance with a permutation test; Shannon entropy of transitions; intersection over union of behavioural profiles with a permutation test.

`compute_stats_df` does not cover peri-stimulus or binned designs: build them from `compute_moseq_df` or from the `bouts` table (see `downstream-analysis.md`).

## Python route (statsmodels)

Tested on simulated data in the kpms environment (statsmodels is a kpms dependency): a mixed model on log distance and, per syllable, a Poisson GEE with exposure offset and animal-clustered robust errors (accounts for overdispersion and repeated recordings; typically less informative than a negative-binomial GLMM):

```python
import numpy as np, statsmodels.api as sm, statsmodels.formula.api as smf
m = smf.mixedlm("np.log(distance) ~ C(group, Treatment('ctrl')) * day + sex", meta, groups=meta["animal"]).fit(reml=True)
g = smf.gee("n ~ C(group, Treatment('ctrl')) + day + sex", groups="animal", data=d, offset=np.log(d.total),
            family=sm.families.Poisson(), cov_struct=sm.cov_struct.Exchangeable()).fit()
```

Adjust p-values over syllables with `statsmodels.stats.multitest.multipletests(p, method="fdr_bh")`. For censored latencies, zero-inflated or beta-binomial models and DHARMa-style checks the R route is richer. `reticulate` is not needed: export CSV tables between the languages.
