---
name: gam-mgcv
description: Fits and checks generalized additive models (GAMs) and generalized additive mixed models (GAMMs) in R with mgcv and related packages (gratia, gamm4, scam, DHARMa, brms). Covers choice of smooths and basis dimension k, REML, families, random-effect smooths and hierarchical GAMs, by-variables and interactions, autocorrelation, bam for large data, and diagnostics (gam.check, appraise, concurvity). Use when the user mentions GAM, GAMM, mgcv, gam(), bam(), s(), te(), ti(), smooths, splines, edf, or modelling non-linear effects. For plotting, interpreting or reporting a fitted GAM use gam-interpretation; for mixed models without smooth terms use mixed-models-glmm.
license: CC-BY-4.0
metadata:
  prompt_signals: '\bmgcv\b|\bgam\.check\b|\bbam\(|\bgratia\b'
  author: tsievert
  version: "1.0"
---

# GAMs and GAMMs with mgcv

Workflow and rules for additive models in R. Details live in `references/`; load only what the task needs. Items marked "reported" in the references come from one or two projects and are not reproduced: treat them as hypotheses.

## First steps

1. Check versions: `packageVersion("mgcv")`, `packageVersion("gratia")`. gratia's API changes between releases (0.11.x renamed sampling arguments and deprecated `evaluate_smooth()`; 0.12 deprecated the colour arguments of `draw()` and `grouped_by`, removed `fixef()` in favour of `fixed_effects()`, and requires R >= 4.4.0, mgcv >= 1.9-4, ggplot2 >= 4.0.3). If code from memory errors, read the current docs or NEWS (see Resources) instead of guessing.
2. Look at the data: response type, grouping structure, repeated measures, spatial or temporal ordering, sample size. These determine family, random effects and correlation handling.
3. Check Gavin Simpson's work (see Resources) when a question concerns gratia, plotting, posterior simulation, difference smooths, derivatives, or a modelling pattern you are unsure about. He is the author of gratia and publishes tutorials, course materials and related packages.

## Default fitting recipe

```r
library(mgcv)
m <- gam(y ~ s(x1) + s(x2) + f,      # f: factor
         data = df, family = gaussian(), method = "REML")
```

- Always set `method = "REML"` (or `"fREML"` in `bam()`). The default GCV is more prone to undersmoothing.
- Choose the family deliberately: `poisson`, `nb()`, `binomial`, `Gamma(link = "log")`, `tw()`, `betar()`, `scat()`, `ocat()`, `ziP()`, location-scale (`gaulss()`, `gammals()`, ...). Do not leave Gaussian as an accident for counts, proportions or positive skewed data. For binomial with trials use `cbind(succ, fail)` or `weights`.
- Offsets: `offset(log(exposure))` in the formula for rates.
- Factors must be real `factor`s (not character) for `by =` and `bs = "re"`.
- Do not hand-tune `sp` or `fx = TRUE` unless there is a reason; let REML estimate smoothness.
- Consider `select = TRUE` (double-penalty shrinkage, can remove terms) when many candidate smooths exist. With `select = TRUE` every smooth has two penalties, so a fixed `sp` inside `s()` needs one value per penalty, e.g. `s(x, sp = c(10, -1))` (`-1` = estimate; a scalar errors with "incorrect number of smoothing parameters"; reproduced). For cumulative or strongly autocorrelated outcomes, test `select` on a subset first ([references/workflow-and-long-fits.md](references/workflow-and-long-fits.md)).
- To test or extend an existing model, read formula, family and data from the saved model object or script (`formula(m)`, `family(m)`, `m$model`), never rebuild them from prose notes.
- For `bam()` fits the estimated dispersion is `m$sig2`; `m$scale` is a placeholder of 1 (reproduced; `summary(m)$scale` is right). Do not report `m$scale`.

## Basis dimension k

`k` is an upper bound on wiggliness, not the fitted complexity. Check with `gam.check(m)` or `mgcv::k.check(m)`: a low k-index with small p-value **and** edf close to `k'` suggests increasing k and refitting. A low k-index can also come from unmodelled structure, autocorrelation, or the wrong family, so do not just raise k blindly. Do not read `k'` or edf near the maximum as automatically a problem when the k-index is fine. See `?choose.k`.

## Choosing smooths

| Situation | Term |
|---|---|
| Default univariate | `s(x)` (thin plate, `bs = "tp"`) |
| Cyclic variable (day of year, hour) | `s(x, bs = "cc")`, set `knots = list(x = c(lo, hi))` |
| Same-unit 2D (space) | `s(lon, lat)` isotropic, or `bs = "ds"`/`"gp"`/`"sos"` (sphere) |
| Different units / scales | `te(x, z)` or `ti(x, z)` |
| Main effects plus pure interaction | `s(x) + s(z) + ti(x, z)` |
| Smooth per factor level | `s(x, by = f)` plus `f` as parametric term |
| Random intercept | `s(g, bs = "re")` |
| Random slope | `s(g, x, bs = "re")` |
| Global smooth plus level deviations (sum to zero) | `s(x) + s(g, x, bs = "sz")`, see sz section |
| Group-specific smooths, shared wiggliness | `s(x, g, bs = "fs")` |
| Extrapolation matters | consider `bs = "bs"` (B-spline); see Simpson's extrapolation post |
| Monotone / convex shape | `scam` or `mgcv::scasm()` |

Details, families and pitfalls: [references/smooths-and-families.md](references/smooths-and-families.md).

## Sum-to-zero factor smooths (`bs = "sz"`)

`s(fac, x, bs = "sz")` fits level-specific deviations from a main smooth, so the model is `s(x) + s(fac, x, bs = "sz")`. It is new and sparsely documented, and tooling support is uneven, so load [references/sz-smooths.md](references/sz-smooths.md) whenever a model uses it. Essentials:

- `fac` must be a real factor (a character vector gives an obscure error) and goes before the covariate. Do not add `fac` as a parametric term; the level smooths already contain the factor main effects.
- Default is one smoothing parameter per level; `id = 1` shares one across levels.
- `k.check()` returns no k-index for the term, so do not claim `k` was verified from it.
- The plotted term is a deviation from the main smooth, not the level's curve. Build level curves and level contrasts from whole-model predictions.
- `gratia::difference_smooths()` errors on `sz` terms (verified in 0.11.2.10, 0.11.2-64, 0.11.2.73 and the CRAN 0.12.1). `gratia::conditional_differences()` works on `sz` models where installed (verified in 0.11.2-64, 0.11.2.73 and 0.12.1; give both `by` and `condition`); the reference file also has a linear-combination helper for older versions. Check the installed gratia version and issues at https://github.com/gavinsimpson/gratia/issues?q=sz before asserting a limitation.

## Beyond mgcv families: gamlss2 and inlaws

When mgcv's families (including `gaulss()`, `gammals()`, `gevlss()`, `ziplss()`) cannot give a parameter its own predictor, or a family is missing, two non-CRAN packages exist: `gamlss2` (GAMLSS; `y ~ s(x) | s(x)` puts predictors on mu and sigma, mgcv smooths work) and `inlaws` (experimental extra families for `gam()`, e.g. `nbls()`, `zinb()`; unrelated to R-INLA). Both need the user's permission to install, and inlaws is flagged by its own README as largely untested, so validate against another tool. Tested syntax, gotchas (`predict(m, newdata = ...)`, undeclared `gamlss` dependency, no `bam()` for `nbls()`) and a worked comparison: [references/gamlss-and-extra-families.md](references/gamlss-and-extra-families.md).

## Mixed models and hierarchical GAMs

Prefer random effects and factor smooths inside `gam()`/`bam()` with REML. Use `gamm4` (lme4 backend), `gamm()` (nlme, for corAR1 and other correlation structures), `glmmTMB` (smooths via `s()`), or `brms` when you need correlated random slopes, specialised families, or a full Bayesian fit. Before including both unit and session random terms, tabulate repeats and level co-occurrence per unit ([references/workflow-and-long-fits.md](references/workflow-and-long-fits.md)). The five HGAM model types (G, GS, GI, S, I) from Pedersen et al. (2019) and the by-variable ordered factor pattern are in [references/hgam-and-random-effects.md](references/hgam-and-random-effects.md).

## Dependence in the data

Plain `gam()` assumes independent residuals. With time series, spatial or repeated-measures data, residual autocorrelation makes confidence intervals and p-values too optimistic and can distort smooth wiggliness. Inspect with `acf()`/`gratia::residuals_*` plots, then handle via random effects, a smooth of time/space, `bam(rho = , AR.start = )`, or `gamm(correlation = corAR1(...))`. Never claim significance without addressing known dependence.

## Diagnostics

- `gam.check(m)` / `gratia::appraise(m)`: QQ, residuals vs linear predictor, histogram, observed vs fitted. In gratia 0.12 `appraise()` uses scalable plots from 10,000 observations, simulation reference bands for `tw()`/`Tweedie()` models, and can show a posterior predictive check (`ppcheck = TRUE`); it also covers glmmTMB, lme4 and `gamm4` fits.
- Quantile residuals for discrete families: `gratia::quantile_residuals()`, `gratia::rootogram()` for counts, `gratia::dharma_residuals()` (simulation-based, no DHARMa needed in 0.12; returns a numeric vector) or `DHARMa`. Surrogate residuals exist for `ocat()` and `multinom()` fits (changelog). Passing residual checks does not validate the interpretation.
- Concurvity: `mgcv::concurvity(m, full = FALSE)` or `gratia::model_concurvity()`. High concurvity makes individual smooths unreliable, so say so when interpreting.
- Compare models with `AIC()` and `anova(m1, m2, test = "F")` as approximate tools. REML scores are not comparable across models with different fixed terms; refit with `method = "ML"` or compare predictive performance.
- With dependent data (repeated animals), in-sample AIC can favour a term that does not help predict new units; use leave-whole-groups-out CV. After an mgcv or gratia upgrade, re-run a saved anchor script and record `packageVersion()`. Both: [references/model-comparison.md](references/model-comparison.md).
- `summary(m)` p-values for smooths are approximate and conditional on the smoothing parameters; report effect shapes with intervals rather than relying only on p-values.

## Interpretation and prediction

Plotting, partial effects, simultaneous intervals, group comparisons, derivatives, posterior simulation and the wording of results belong to the `gam-interpretation` skill. It checks the installed gratia version first, which this skill does not, so gratia function advice lives only there. Fitting-side basics:

- Smooths are centred, so partial-effect plots show effects relative to the intercept, not the response scale.
- Whole-response predictions: `predict(m, newdata, type = "link", se.fit = TRUE)`, then back-transform with `family(m)$linkinv`, which gives valid intervals on the response scale.
- Exclude random effects from predictions with `exclude = "s(g)"` (and supply a dummy level); hold other covariates at typical values.
- Excluding random effects gives a typical-unit curve, not the group mean, and under a log link the two can differ several-fold. Ask early which the user wants, and avoid bare "population-level" (ambiguous). The explanation and the wording are in the `gam-interpretation` skill (its uncertainty-and-inference and phrasing references).
- Group-mean contrasts from conditional fits with random terms, and averaging over an additive covariate under a log link (tested recipes, single reports): `gam-interpretation` (its uncertainty-and-inference reference, section "Random effects and held-fixed covariates").
- Do not extrapolate outside the data.

## Large data

`bam(..., method = "fREML", discrete = TRUE, nthreads = n)` for tens of thousands of rows or more. Use `gam()` for smaller data; `bam()` smoothing selection differs slightly. Under `discrete = TRUE`, `select = TRUE` and some families behave differently; check `?bam`. For `method = "NCV"` (model comparison, cheap refits at fixed smoothing parameters, failure reporting, a verified clustered-sandwich recipe, checking `select = TRUE`) see [references/ncv-and-bam-notes.md](references/ncv-and-bam-notes.md). On clusters, set `nthreads` from the job allocation (see the `hpc-r-code` skill).

Before queueing several expensive fits, time one on a short row ladder (for example 640, 1,280, 2,560 rows) and extrapolate. `fs` and large `sz` terms are slow in `gam()`, and location-scale families are `gam()` only. Row-ladder recipe, `callr::r_bg()` background-fit rules and timings: [references/workflow-and-long-fits.md](references/workflow-and-long-fits.md).

## Reporting

For simulation checks of band or SE coverage (replicate counts, Monte Carlo SE, seeds, failed fits): [references/coverage-simulation.md](references/coverage-simulation.md).

State family and link, smoother types and k, estimation method, the diagnostics checked (and any remaining concerns), edf per smooth, and plots of partial effects with intervals. Be proportionate: a wiggly smooth with wide intervals is not evidence of a real feature. Report the unresolved issues (low k-index, concurvity, dependence) rather than hiding them. For bootstrap simultaneous (max-t) bands, state B and the critical-value rank, and use B of at least 1,000 for a final value ([references/model-comparison.md](references/model-comparison.md)).

## Resources

Load [references/resources.md](references/resources.md) for the curated list. Short version, check these first:

- gratia docs and changelog: https://gavinsimpson.github.io/gratia/ (repo: https://github.com/gavinsimpson/gratia)
- Gavin Simpson's blog: https://fromthebottomoftheheap.net/
- Gavin Simpson's GitHub (courses, `naboer`, other packages): https://github.com/gavinsimpson
- mgcv help: `?gam`, `?choose.k`, `?gam.check`, `?mgcv.FAQ`

## Watch for bug candidates

Keep an eye out for behaviour that deviates from the documentation of mgcv, gratia or related packages: a documented argument silently ignored, a function erroring on a documented model type, output that contradicts the help page, or a result that changes with an unrelated setting. Rule out the usual causes first (model misspecification, low `k`, concurvity, version differences; check the installed version's help and NEWS). If it still looks like a bug, say so, search the package's issue tracker, and offer to draft a report with versions and a minimal reproduction (built-in data such as `gamSim()`); do not file it yourself. Procedure: `upstream-bug-report`.

## Related skills

- `upstream-bug-report`: checking a suspected package bug against upstream issues and drafting a redacted report.
- `mixed-models-glmm`: linear or generalized mixed models without smooth terms (random intercepts and slopes, zero inflation, repeatability).
- `gam-interpretation`: plotting and cautiously interpreting a fitted GAM.
- `hpc-r-code`: running large `bam()` or many GAM fits on a cluster.

## Explain the reasoning (teaching rule)

Teach, don't replace the user's thinking: say briefly (a sentence or two) why things were or were not done, name the trade-off and which decision is the user's, and point to a reference for depth.

## Capture lessons (self-improvement rule)

Load the `skill-lessons` skill and append a generic, anonymised entry (no project data, IDs or paths) as soon as something unanticipated happens: an error or warning, advice or code that failed, a user correction, a version or API mismatch, missing guidance, or a recommendation that held up (`worked-well`). Also write one `use-case` entry per session. When unsure, record it with `generality: unsure`. Entries are hypotheses for `skill-feedback-triage`.
