---
name: gam-mgcv
description: Fits and checks generalized additive models (GAMs) and generalized additive mixed models (GAMMs) in R with mgcv and related packages (gratia, gamm4, scam, DHARMa, brms). Covers choice of smooths and basis dimension k, REML, families, random-effect smooths and hierarchical GAMs, by-variables and interactions, autocorrelation, bam for large data, and diagnostics (gam.check, appraise, concurvity). Use when the user mentions GAM, GAMM, mgcv, gam(), bam(), s(), te(), ti(), smooths, splines, edf, or modelling non-linear effects. For plotting, interpreting or reporting a fitted GAM use gam-interpretation; for mixed models without smooth terms use mixed-models-glmm.
license: MIT
metadata:
  prompt_signals: '\bmgcv\b|\bgam\.check\b|\bbam\(|\bgratia\b'
  author: tsievert
  version: "1.0"
---

# GAMs and GAMMs with mgcv

Workflow and rules for additive models in R. Details live in `references/`; load only what the task needs.

## First steps

1. Check versions: `packageVersion("mgcv")`, `packageVersion("gratia")`. gratia's API changes between releases (0.11.x renamed sampling arguments, deprecated `evaluate_smooth()`, colour arguments in `draw()`, `grouped_by`). If code from memory errors, read the current docs or NEWS (see Resources) instead of guessing.
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
- Consider `select = TRUE` (double-penalty shrinkage, can remove terms) when many candidate smooths exist.

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
- `gratia::difference_smooths()` errors on `sz` terms (verified in 0.11.2.10, 0.11.2-64 and 0.11.2.73). `gratia::conditional_differences()` works on `sz` models where installed (verified in 0.11.2-64 and 0.11.2.73; give both `by` and `condition`); the reference file also has a linear-combination helper for older versions. Check the installed gratia version and issues at https://github.com/gavinsimpson/gratia/issues?q=sz before asserting a limitation.

## Beyond mgcv families: gamlss2 and inlaws

When mgcv's families (including `gaulss()`, `gammals()`, `gevlss()`, `ziplss()`) cannot give a parameter its own predictor, or a family is missing, two non-CRAN packages exist: `gamlss2` (GAMLSS; `y ~ s(x) | s(x)` puts predictors on mu and sigma, mgcv smooths work) and `inlaws` (experimental extra families for `gam()`, e.g. `nbls()`, `zinb()`; unrelated to R-INLA). Both need the user's permission to install, and inlaws is flagged by its own README as largely untested, so validate against another tool. Tested syntax, gotchas (`predict(m, newdata = ...)`, undeclared `gamlss` dependency, no `bam()` for `nbls()`) and a worked comparison: [references/gamlss-and-extra-families.md](references/gamlss-and-extra-families.md).

## Mixed models and hierarchical GAMs

Prefer random effects and factor smooths inside `gam()`/`bam()` with REML. Use `gamm4` (lme4 backend), `gamm()` (nlme, for corAR1 and other correlation structures), `glmmTMB` (smooths via `s()`), or `brms` when you need correlated random slopes, specialised families, or a full Bayesian fit. The five HGAM model types (G, GS, GI, S, I) from Pedersen et al. (2019) and the by-variable ordered factor pattern are in [references/hgam-and-random-effects.md](references/hgam-and-random-effects.md).

## Dependence in the data

Plain `gam()` assumes independent residuals. With time series, spatial or repeated-measures data, residual autocorrelation makes confidence intervals and p-values too optimistic and can distort smooth wiggliness. Inspect with `acf()`/`gratia::residuals_*` plots, then handle via random effects, a smooth of time/space, `bam(rho = , AR.start = )`, or `gamm(correlation = corAR1(...))`. Never claim significance without addressing known dependence.

## Diagnostics

- `gam.check(m)` / `gratia::appraise(m)`: QQ, residuals vs linear predictor, histogram, observed vs fitted.
- Quantile residuals for discrete families: `gratia::quantile_residuals()`, `gratia::rootogram()` for counts, `DHARMa` as an alternative.
- Concurvity: `mgcv::concurvity(m, full = FALSE)` or `gratia::model_concurvity()`. High concurvity makes individual smooths unreliable, so say so when interpreting.
- Compare models with `AIC()` and `anova(m1, m2, test = "F")` as approximate tools. REML scores are not comparable across models with different parametric (fixed) terms; refit with `method = "ML"` for that, or compare predictive performance.
- `summary(m)` p-values for smooths are approximate and conditional on the smoothing parameters; report effect shapes with intervals rather than relying only on p-values.

## Interpretation and prediction

Plotting, partial effects, simultaneous intervals, group comparisons, derivatives, posterior simulation and the wording of results belong to the `gam-interpretation` skill. It checks the installed gratia version first, which this skill does not, so gratia function advice lives only there. Fitting-side basics:

- Smooths are centred, so partial-effect plots show effects relative to the intercept, not the response scale.
- Whole-response predictions: `predict(m, newdata, type = "link", se.fit = TRUE)`, then back-transform with `family(m)$linkinv`, which gives valid intervals on the response scale.
- Exclude random effects from predictions with `exclude = "s(g)"` (and supply a dummy level); hold other covariates at typical values.
- Do not extrapolate outside the data.

## Large data

`bam(..., method = "fREML", discrete = TRUE, nthreads = n)` for tens of thousands of rows or more. Use `gam()` for smaller data; `bam()` smoothing selection differs slightly. Under `discrete = TRUE`, `select = TRUE` and some families behave differently; check `?bam`. For `method = "NCV"` (model comparison, cheap refits at fixed smoothing parameters, failure reporting, checking `select = TRUE`) see [references/ncv-and-bam-notes.md](references/ncv-and-bam-notes.md). On clusters, set `nthreads` from the job allocation (see the `hpc-r-code` skill).

## Reporting

State family and link, smoother types and k, estimation method, the diagnostics checked (and any remaining concerns), edf per smooth, and plots of partial effects with intervals. Be proportionate: a wiggly smooth with wide intervals is not evidence of a real feature. Report the unresolved issues (low k-index, concurvity, dependence) rather than hiding them.

## Resources

Load [references/resources.md](references/resources.md) for the curated list. Short version, check these first:

- gratia docs and changelog: https://gavinsimpson.github.io/gratia/ (repo: https://github.com/gavinsimpson/gratia)
- Gavin Simpson's blog: https://fromthebottomoftheheap.net/
- Gavin Simpson's GitHub (courses, `naboer`, other packages): https://github.com/gavinsimpson
- mgcv help: `?gam`, `?choose.k`, `?gam.check`, `?mgcv.FAQ`

## Related skills

- `mixed-models-glmm`: linear or generalized mixed models without smooth terms (random intercepts and slopes, zero inflation, repeatability).
- `gam-interpretation`: plotting and cautiously interpreting a fitted GAM.
- `hpc-r-code`: running large `bam()` or many GAM fits on a cluster.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were done or not done: why this method, setting or tool was chosen, which alternative was rejected and why, which check or step was skipped, and which assumptions were made. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a package version or API differs from what it states, or it lacks guidance the task needs, record a generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
