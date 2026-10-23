---
name: mixed-models-glmm
description: Fits, checks, compares and reports linear and generalized linear mixed models in R with glmmTMB, lme4/lmerTest, DHARMa, performance and emmeans. Covers repeated-measures and nested designs (animals, trials, sessions), choice of family (Gamma, binomial, beta-binomial, negative binomial, zero-inflated, Gaussian on log scale), offsets, random intercepts and slopes, singular fits and convergence, overdispersion, simulated-residual diagnostics, LRT/AIC model comparison, repeatability (ICC), post hoc contrasts on the response scale, and multiplicity. Use when the user mentions GLMM, LMM, glmmTMB, lme4, lmer, random effects, repeated measures, pseudoreplication, overdispersion, zero inflation, DHARMa, emmeans, or ICC. For smooth non-linear effects use gam-mgcv instead.
metadata:
  version: "1.0"
---

# Mixed models and GLMMs in R

Default stack: `glmmTMB` for fitting (handles Gamma, beta-binomial, nbinom2, zero inflation, dispersion models), `lmerTest` for Gaussian models needing Satterthwaite df, `DHARMa` for residuals, `emmeans` for contrasts, `performance` for ICC/R2/singularity. All CRAN. Tested versions: glmmTMB 1.1.15.2, DHARMa 0.5.0, emmeans 2.0.4, lme4 2.0.6, performance 0.19.0, lmerTest 3.2.1.

Tested, runnable templates for every pattern below: [scripts/glmm_templates.R](scripts/glmm_templates.R) (simulated data; run with `source(..., local = new.env())`). Copy the relevant block and adapt it. Details and pitfalls: [references/pitfalls-and-reporting.md](references/pitfalls-and-reporting.md).

## Workflow

1. **Identify the unit of replication.** Which factors vary between animals (group, sex) and which within (day, trial)? Every animal contributes repeated rows, so `(1 | animal)` is the minimum. Nested levels: `(1 | animal/session)`. Treating rows as independent is pseudoreplication. Ask the user if the design is unclear.
2. **Choose the family from the response**, not from a normality test:

   | Response | Family (glmmTMB) | Notes |
   |---|---|---|
   | Positive continuous (distance, duration, latency) | `Gamma(link = "log")` or `lmer(log(y))` | Gamma gives ratios of means; log-Gaussian gives ratios of geometric means |
   | Successes out of N (frames in ROI, transitions) | `binomial` with `cbind(k, n - k)`, then `betabinomial` | Plain binomial on frame counts was strongly overdispersed in tests (AIC 6991 vs 773) |
   | Counts, same exposure | `poisson`, then `nbinom2` | `nbinom2` is the usual default; `nbinom1` if variance is linear in mean |
   | Counts, different exposure | add `offset(log(exposure))` | Contrast with `emmeans(..., offset = 0)` for rates per unit |
   | Many zeros | `ziformula = ~ 1` or `~ group` | See zero inflation below |
   | Proportion with no N | `beta_family()`; 0/1 values need `ordbeta` or a transformation | Do not use `lm` on arcsine |
   | Time to event with censoring | `coxme` (survival), not a GLMM | see the `animal-behaviour-tracking-analysis` skill, file statistical-analysis.md |
   | Non-linear in time/space | GAM | use the `gam-mgcv` skill |

3. **Fit the full model of the pre-specified question first** (fixed effects of interest, covariates, design-justified random effects). Do not drop terms by stepwise p-values.
4. **Diagnose with DHARMa before looking at coefficients**: `sim <- simulateResiduals(m)`, then `plot(sim)`, `testDispersion(sim)`, `testZeroInflation(sim)`, `testOutliers(sim)`. Residuals against each predictor via `plotResiduals(sim, x)`. With few groups or small n, these tests have low power: zero-inflation p = 0.07 coexisted with an AIC gain of 37 for the zero-inflated model in the tests, so use AIC and subject knowledge together with the test.
5. **Fix problems in this order**: wrong family or link, then overdispersion (switch family, add observation-level term only if needed), then zero inflation, then dispersion model (`dispformula = ~ group`), then random-slope structure.
6. **Test and estimate**:
   - Overall term effect: LRT with `anova(m_reduced, m_full)` (glmmTMB refits by ML; both models need the same data and family). For Gaussian `lmerTest::lmer`, `anova(m)` gives Satterthwaite F tests.
   - Contrasts: `pairs(emmeans(m, ~ group), type = "response")` gives ratios/odds ratios with CIs. State the scale. glmmTMB tests are Wald z (asymptotic, df = Inf); with few animals (<~15 per factor level) call them approximate.
   - Interactions: if `group:day` is in the model, `emmeans(~ group)` averages over `day` and warns. Present `~ group | day` or test the interaction first.
7. **Multiplicity**: define primary endpoint(s) up front; adjust across endpoints (`p.adjust(..., "holm")` on the overall tests, or BH when screening many outcomes such as syllables) and let `emmeans` adjust within a family of contrasts (Tukey default).
8. **Report**: family and link, random-effect structure and variances, n animals and n observations, effect sizes with CIs on the response scale, ICC if repeatability matters, diagnostics done, any convergence/singularity decisions.

## Random effects

- Random slopes `(1 + trial | animal)` need enough repeated observations per animal (here 12 trials; with 2 sessions they are not estimable). A correlation of exactly -1/1 or `check_singularity()` = TRUE (seen in tests) means the structure is too rich: try `(1 | animal) + (0 + trial | animal)`, or drop the slope and say so.
- Compare structures with AIC and the LRT (conservative for variance components on the boundary). Keep intercepts that reflect the design even when their variance estimate is small.
- Random intercepts alone do not control pseudoreplication for effects that vary within animals when animals differ in their response: add random slopes for within-animal predictors where the data can support them (Schielzeth & Forstmeier 2009).
- Fewer than ~5 levels of a grouping factor: the variance is poorly estimated. Simulation work suggests fixed-effect estimates are still fine if the grouping is a nuisance (Gomes 2022; Oberpriller 2022 examines type I error and power); treating it as fixed is the usual alternative. Do not interpret that variance.
- Center and scale continuous covariates (`trial_c`) to aid convergence and make the intercept meaningful.

## Zero inflation

Compare `nbinom2` with and without `ziformula`. Then say which quantity you report: `emmeans(m, ~ group, component = "cond")` (count given not a structural zero), `"zi"` (odds of structural zero, logit scale), or `"response"` (overall expected count, estimates on the response scale; contrasts are differences). Structural zeros need a biological reason (animal could not or did not engage), not just an excess of zeros.

## Repeatability

`performance::icc(m)` gives adjusted and unadjusted ICC on the link scale; for non-Gaussian families it is not the same as the observed-scale repeatability. Report the scale. Use `r2(m)` for marginal and conditional R2. Confidence intervals for repeatability need a bootstrap: `rptR::rpt()` (0.9.23, tested) with `datatype = "Gaussian"` or `"Poisson"`/`"Binary"`/`"Proportion"`, `nboot >= 1000` for real work (the template uses fewer). It has no Gamma or negative-binomial datatype; use Gaussian on a transformed scale or `icc()`. Never use extracted random-effect predictions (BLUPs) as data in a second-stage test: they carry unpropagated error and give spurious P values. Model the covariance jointly (bivariate or multi-response mixed model) instead (see literature in the reference file).

## Known issues seen in testing

- `DHARMa::testCategorical(plot = FALSE)` errored ("plot.new has not been called yet") in DHARMa 0.5.0; the template uses a base-R Levene-like check instead.
- glmmTMB convergence warnings: "singular convergence (7)" usually accompanies a boundary random-effect fit; simplify the structure rather than changing optimizers.
- `broom.mixed`, `car`, `ggeffects` are not installed locally; templates avoid them. Installing from CRAN is allowed.
- `rptR` prints a long progress bar and may emit singular-fit warnings inside bootstraps; both are harmless but noisy.
- Issues reported in the ecology/behaviour literature and glmmTMB tracker (BLUP misuse, data-driven family selection, spatial autocorrelation, rank deficiency, `simulate()` conditioning): see [references/pitfalls-and-reporting.md](references/pitfalls-and-reporting.md), section "Issues reported for ecological and behavioural data".
- Not tested: real data, crossed random effects with many levels, spatial/temporal autocorrelation (`ar1()`, `exp()` covariance structures in glmmTMB), ordinal models, brms/Bayesian alternatives.

## Related skills

`gam-mgcv` and `gam-interpretation` for non-linear time courses; `animal-behaviour-tracking-analysis` for DLC metrics and the matching statistics examples; `openalex` for literature on methods.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were done or not done: why this method, setting or tool was chosen, which alternative was rejected and why, which check or step was skipped, and which assumptions were made. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a package version or API differs from what it states, or it lacks guidance the task needs, record a generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
