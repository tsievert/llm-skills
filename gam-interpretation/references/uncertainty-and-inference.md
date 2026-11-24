# Uncertainty, inference and what each output means

## Contents
- What the intervals are
- Pointwise, across-the-function and simultaneous
- Conditional vs unconditional
- Link vs response scale
- Partial effects vs predictions
- Random effects and held-fixed covariates
- Group comparisons
- Derivatives and rates of change
- Posterior simulation: which function answers which question
- p-values, edf, and variance components
- Concurvity and identifiability
- Residual checks that feed interpretation
- Dependence
- Sensitivity checks

Sources used: gratia articles (smooth effects, prediction comparisons, posterior simulation, model checking, variance components, data slices), Marra and Wood (2012, Scand J Stat 39:53-74), Wood (2013 p-values), the mgcv help pages. Statements on gratia behaviour were read from the gratia documentation and changelog (0.11.2-66 in October 2026, 0.12.1 on 2026-11-24, where the calls named below were also run); verify against the installed version.

## What the intervals are

mgcv's default intervals for smooths and predictions come from the Bayesian view of penalized splines: a Gaussian approximation to the posterior of the coefficients, with covariance `vcov(m)`. They are called confidence or credible intervals interchangeably.

- Marra and Wood (2012) found these intervals have close to nominal across-the-function frequentist coverage, except when the true function is close to a straight line or plane. The coverage argument assumes the term is not so heavily oversmoothed that bias dominates the sampling variability.
- Across-the-function coverage means about 95% on average over the covariate range; coverage at a particular x can be higher or lower (gratia's posterior-simulation article makes this point explicitly).
- They are approximate, and depend on the model being adequate (family, basis, dependence).

## Pointwise, across-the-function and simultaneous

| Interval | Meaning | Use for |
|---|---|---|
| Pointwise (default) | Approximate interval at each x separately | Reading the estimate at one x |
| Across-the-function (the property of the default Bayesian interval) | Average coverage over the range | Why default intervals are usable at all |
| Simultaneous | Band calibrated so the whole curve (on the evaluated grid) lies inside with the nominal probability | Statements about the shape of the curve or "where does X differ from zero" |

- Simultaneous coverage in gratia is approximate posterior coverage on the evaluated grid; it does not guarantee coverage between grid points or beyond the grid, and the scope of "simultaneous" (one contrast, or all returned contrasts) can matter (gratia's `simultaneous_scope` in `conditional_differences()`).
- gratia: `interval = "simultaneous"` in `fitted_values()`, `difference_smooths()`, `draw()` and `smooth_estimates()` (the last two new in 0.12); `confint(m, parm = "s(x)", type = "simultaneous")` (verified in 0.11.2.10, 0.11.2.73 and 0.12.1). The simulation count argument is `nsim` in `confint()` and `n_sim` in the others (checked in 0.12.1; in `fitted_values()` the effect of `n_sim` was visible in the band width and `n_draws` was silently ignored, so verify by effect, not by the call running). Check the stability of the limits across `seed` and the number of simulations; the gratia authors recommend increasing the draws and confirming that conclusions near an interval limit are stable.
- `simultaneous_method = "tube"` (0.12) gives a continuous-interval Gaussian band for supported one-dimensional cubic splines. The changelog calls it a conservative threshold-crossing bound, so it covers the whole curve between grid points but may be wider than needed. It is Gaussian, conditional on the smoothing parameters, and unlike the grid-based simulation band its coverage claim is about the fitted smooth's posterior, not the true function. Name the method in the caption.
- Shape-constrained fits (`mgcv::scasm()`): gratia's `shape_intervals()` re-shapes interval endpoints (monotone rearrangement, convex or concave envelope); the changelog states this preserves whole-grid containment events but does not establish nominal coverage or preserve the marginal coverage of the pointwise limits. Gaussian draws from constrained fits need not satisfy the fitted shape. Tested in 0.12.1 on hand-made bands: it needs `estimate`, `lower`, `upper`, a complete-grid `data` frame and a named `constraints` list; monotone and convex outputs satisfied the shape and the maximum width did not grow, and a monotone target inside the input band stayed inside. `interval_method = "shape"` on an `scasm()` fit ran and warned that pointwise calibration is not guaranteed. That is a whole-grid statement about the input band: if the input band was badly calibrated or biased, the reshaped band is too. Do not describe it as a "significant" monotone effect.

## Conditional vs unconditional

By default intervals are conditional on the estimated smoothing parameters. `unconditional = TRUE` (in `predict.gam`, `gratia` functions) adds a correction for smoothing-parameter uncertainty when available (REML/ML); it typically widens intervals slightly. Prefer it for reported intervals when feasible, and state which was used. `frequentist = TRUE` in several gratia functions switches to the covariance of the penalized estimator itself (sampling variability) instead of the posterior covariance; do not mix the two in one report without saying so.

## Link vs response scale

- Smooth plots show contributions on the link scale (log, logit, etc.). They are not effects on the response.
- Compute intervals on the link scale and transform the limits; do not add or subtract standard errors on the response scale.
- Differences on the response scale are nonlinear functions of coefficients; the delta method is an approximation, and simulation can better describe asymmetric uncertainty (gratia's `conditional_differences(uncertainty = "delta" | "simulation")`).
- Interpret back-transformed quantities for the family at hand. For example, in a log-link model, exponentiating a link-scale prediction gives the conditional mean for a Gamma or Poisson model, whereas for a Gaussian model fitted to `log(y)` it is closer to a conditional median of `y`, not the arithmetic mean.
- Ratios and differences are different questions: "twice as many" (link-scale difference in a log model) vs "five more per unit" (response-scale difference).

## Partial effects vs predictions

- A partial effect (one `s()` term) is centred (sums to zero over the data) and excludes the intercept and other terms. In gratia 0.12, parametric-effect intervals by default include intercept uncertainty and its covariance with the term (`overall_uncertainty = FALSE` gives term-only intervals; the partial estimates are unchanged), and covariates are plotted as evaluated in the model (use `back_transform = TRUE` for original units). Intervals from older versions are therefore not directly comparable to 0.12 intervals.
- For interactions, random effects, and nonlinear links, a partial effect "need not show the expected response" (gratia, Read smooth effects article). Compose terms before making claims about expected values.
- Subtracting interval endpoints from separate partial-effect plots is not a valid comparison.

## Random effects and held-fixed covariates

- gratia 0.12 adds two tools for the new-group question: `random_effect_samples()` draws new random intercepts, slopes and factor-smooth curves from their estimated Gaussian distribution, and `marginalise = TRUE` in fitted-value and response-simulation functions integrates over that distribution (Gaussian quadrature or Monte Carlo; closed form for identity, log and probit links). Smoothing parameters and dispersion stay at their fitted values, so the result still understates uncertainty from those. The integral is over the fitted random-effect variance, which is itself an estimate (poorly determined with few groups). Both ran on a `bs = "re"` model in 0.12.1; the numbers were not checked against a manual integral. This is the "population-average over groups" answer, in contrast to the typical-group answer below.
- Setting a random effect to zero (via `exclude = "s(g)"` and a dummy level) gives predictions for a typical (zero-deviation) group. With a nonlinear link this is not the population-average response. Say "typical group". Under a log link with skewed or zero-inflated outcomes the typical-group curve can sit several-fold below the group mean (one synthetic test and one real project); overlay raw group means and ask which summary the user wants (typical unit or group mean) before interpreting contrasts.
- Group-mean contrast from a conditional fit with `bs = "re"`/`"fs"` terms: predict every observed unit (or session) at every grid value with its own random effects included, then average per cell (needs `predict()` on units x grid rows). One project (mgcv 1.9-5, Tweedie/Gamma log link, 162 units): this stayed within 0.8 bootstrap SD of the marginal fit, while the typical-unit curve (random terms excluded) was off by up to 5.7 SD. Single report, not re-run here.
- Averaging a group-mean prediction over the observed values of an additive covariate (for example age) under a log link does not need units x grid rows: predict the grid with the covariate at a reference value, then multiply by `mean(exp(eta_i - eta_ref))`, where `eta_i` and `eta_ref` are link-scale predictions of one reference grid row at each unit's covariate value and at the reference value. Valid only for additive terms with no interaction with the covariate. Verified 2026-11-09 on a Poisson bam (mgcv 1.9-5, synthetic): matches brute force to rounding error.
- Excluding or zeroing a covariate smooth that is nearly collinear with a group factor shifts predictions for the groups unequally. Because the smooth is additive on the link scale, the group contrast at an equal covariate value is unaffected, and the distortion is a constant link-scale shift f(x_B) - f(x_A) across all other covariates. Report that shift, and the contrast under group-specific covariate values, as a sensitivity check. It does not fix identifiability: when covariate and group are confounded the contrast is not identified by the data (see concurvity below). Reported from one project, algebra only.
- Prediction bands for expected values exclude observation noise; prediction intervals for new observations need `posterior_samples()` or simulation including response noise.
- Choose held-fixed values deliberately (mean/mode defaults in `data_slice()` are conventions). Results for interacting terms depend on them.
- `data_slice()` fills unspecified covariates with typical values; for derived or interaction factors, set them explicitly. `data_slice(.by = )` restricts each covariate's marginal range per group but not the joint support across several continuous covariates.
- gratia's `fitted_values()` warns when prediction rows contain factor-level combinations absent from the fitting data; treat that as a prompt to check the design, not noise.

## Group comparisons

Two distinct questions:

1. Do the whole expected responses differ? Contrast whole-model predictions (including parametric group effects). gratia: `conditional_differences()` where installed; otherwise a linear-combination contrast from the `lpmatrix` with the joint coefficient covariance (see the `sz_difference()` helper in `gam-mgcv/references/sz-smooths.md`).
2. Do the centred smooth shapes differ? `difference_smooths()` compares smooths with parametric effects omitted by default (`group_means = TRUE` adds the group means). A clear difference in expected response need not mean a clear difference in smooth shape, and vice versa (gratia prediction-comparisons article). Since 0.12 it can also give simultaneous intervals for the differences (`interval = "simultaneous"`, separately for each pair of levels) and differences of derivatives (`order`, `focal`), with intervals that keep the covariance between the two smooths. For the same smooth in two different models, `compare_smooths()` is available; that compares model fits, not groups.

Rules:
- Overlap of two prediction bands does not test their difference; their errors are correlated.
- Check the direction (level order determines subtraction).
- If more than two groups, decide whether the claim concerns each pair separately or any pair, and calibrate accordingly (`simultaneous_scope = "contrast"` vs `"all"` in gratia's `conditional_differences()`).
- For smooths built with `bs = "sz"` or `fs`, see the dedicated notes in `gam-mgcv`.
- With few groups or sparse data per group, intervals may be wide; say so.

## Derivatives and rates of change

- `derivatives()` (smooth contributions, link scale), `response_derivatives()` (complete fitted response, response scale), `partial_derivatives()` (multivariate smooths), `derivative_samples()` (posterior draws).
- Intervals are pointwise unless stated; "SiZer"-style indicators of significant change (`add_sizer()`) inherit that limitation.
- The default finite-difference step `eps = NULL` (automatic since 0.12) chooses a step from the covariate range, derivative order and method, which lowers rounding error in second derivatives; it is a heuristic. Near boundaries or with unusual scales, supply a step and check stability.
- Derivative of a smooth on the link scale is not the derivative of the expected response; use `response_derivatives()` for the latter. With transformed covariates, check the units: the derivative with respect to `log(x)` differs from that with respect to `x` by the chain rule.
- Splines can have local decreases or plateaus the data do not support; intervals that include zero indicate an unresolved direction, not zero slope.

## Posterior simulation: which function answers which question

| Function | Answers | Includes |
|---|---|---|
| `smooth_samples()` | uncertainty in one smooth | coefficient uncertainty for that smooth |
| `fitted_samples(quantity = "expectation")` | uncertainty in the expected response (without `quantity` it returns the distribution parameters, a `.parameter` column) | coefficient uncertainty |
| `predicted_samples()` / `simulate()` | what new responses could look like at fitted coefficients | response noise only |
| `posterior_samples()` | prediction intervals including both | coefficient uncertainty plus noise |
| `derivative_samples()` | uncertainty in derivatives of the expectation | coefficient uncertainty, dependence preserved |

- Draws are conditional on smoothing parameters unless `unconditional = TRUE`; neither Gaussian nor Metropolis-Hastings samplers in gratia sample smoothing parameters.
- Default sampler is the Gaussian approximation; `method = "mh"` is available for cases where it is poor (for example binomial with many zeros). Inspect chain diagnostics when using MH.
- Use enough draws for the quantity being estimated; tail quantities and prediction intervals need many more than smooth plots. Re-run with a larger number of draws and a different seed to check stability.
- gratia 0.12 renamed arguments in the sampling functions (`n_draws`, `n_grid`; older `n`, `n_sim`, `n_vals`, `freq`, `newdata`; sampling controls must be named; `n_threads` and `n_cores` replace `ncores`) and old names error there with a migration message. Functions that wrap sampling internally (`response_derivatives()`, `conditional_differences()`, `fitted_values(interval = "simultaneous")`, `confint()`) kept their own names (`n_sim`, `nsim`), and giving them `n_draws` either errors or is silently ignored. Check `?fn`.
- Distribution-parameter models: `fitted_samples()` defaults to all parameters represented by predictors; Gaussian location-scale models now return the standard deviation (not its reciprocal). `fitted_moments()`/`conditional_moments()` (0.12) give response means, variances, SDs, skewness and kurtosis with delta-method or simulation intervals; the changelog says they propagate covariance between parameters and, for ML/REML fits, global family parameters and dispersion. Run in 0.12.1 for Poisson, Gamma and `gaulss()` fits and checked against analytic values (means, and variance as (1/tau)^2 for `gaulss()`); other families not run.
- Multi-chain Metropolis-Hastings draws (`chains`, `mh_backend`) come with `sampling_diagnostics()`; the default Gaussian sampler needs none. As before, no sampler draws smoothing parameters.

## p-values, edf, and variance components

- `summary(m)` smooth p-values (Wood 2013 approach) test whether the term is zero; they are approximate, conditional on the smoothing parameters, and say nothing about size or shape. Terms shrunk to near-zero edf can still have p-values; do not read much into them.
- edf: effective degrees of freedom under the penalty; larger means more flexible, not "more significant". `edf` close to `k'` can indicate a basis restriction (check `k.check`), but not by itself.
- `variance_comp()` (gratia) summarizes penalty variances and (with `type = "terms"`) the shares of linear-predictor variance by term. Shares need not sum as expected term-by-term; with correlated terms shares can exceed 1 or be negative; they describe the fitted model on this sample, not importance in general. In 0.11.2.10 and 0.11.2-64 a call with `type = "terms"` returned the same table as `type = "penalty"` (no proportion columns). From 0.11.2.73 and in the CRAN 0.12.1 it returns the term table with `.proportion`, `.proportion_lower_ci`, `.proportion_upper_ci` and a `total` row (checked on one simulated Gaussian GAM each time; for that model proportions summed to 1 across terms). The 0.12 changelog adds support for `gam()`, `bam()`, `gamm()` and `gamm4()` fits, intervals that account for covariance between terms, and a `draw()` method; those extensions were not tested here. Do not report term shares unless the output actually contains them, and say which `type` was used.

## Concurvity and identifiability

- `mgcv::concurvity(m, full = TRUE)` (or `gratia::model_concurvity()`): the "worst" case is a upper bound-ish diagnostic; "observed" and "estimate" are alternatives. High values mean one smooth can be approximated by the others; individual smooths may be unreliable and confidence intervals optimistic.
- Do not interpret individual curves of heavily concurve terms as separate effects; report the combined fit or the sensitivity to dropping/adding a term.
- Interaction `ti()` terms with their main effects can be fragile; check.

## Residual checks that feed interpretation

gratia 0.12 widened its residual toolkit (changelog; `dharma_residuals()` was run and returned a numeric vector, the rest not run): quantile (PIT) residuals for many families, simulation-based `dharma_residuals()` without DHARMa, surrogate residuals for `ocat()`/`multinom()` models, `residuals_covariate_plot()` to look for leftover mean structure or changing spread, posterior predictive checks, and diagnostics for glmmTMB, lme4, nlme, sdmTMB and `gamm4` fits. For mixed models the checks can hold fitted random effects fixed (conditional) or average over their distribution (marginal), and the two answer different questions: use the one that matches how the fit will be interpreted. `appraise()` switches to scalable plots from 10,000 observations, and for `tw()`/`Tweedie()` models picks simulation reference bands automatically. Passing diagnostics make a fit usable, not correct, and none of them test the shape or the causal reading.

## Dependence

Residual autocorrelation or clustering makes intervals too narrow. gratia's model-checking article notes: residual correlation plots have no built-in significance bands; lags count observation positions not elapsed time, so ordering and irregular spacing matter; some joint simulation checks are unsupported for correlated BAM and some PQL fits. State remaining dependence as a limitation, and prefer a generative model with a justified correlation structure when joint predictive simulation is needed.

## Sensitivity checks that make an interpretation more honest

- Refit with larger `k` and a different basis (`tp` vs `cr`; `ps` or `bs` for extrapolation-sensitive questions); compare the plotted curves.
- Refit with `select = TRUE`; check whether the conclusion for weak terms persists.
- Compare with a simpler parametric model (linear, polynomial) if the claim is about non-linearity.
- Refit with `unconditional = TRUE` intervals.
- Leave out a block of data (site, year) and check that the curve is stable.
- For bam, compare `discrete = TRUE` against exact fits for a subsample.
- Bootstrap max-t bands for contrasts of cumulative curves: standardised values near the start have tiny SDs, so
  spurious large values can inflate the critical value, and an SD floor can make flags vanish at early times while
  another contrast becomes flagged because the critical value fell (flags move in both directions; reported, low
  confidence). Show the headline and the floored (or grid-restricted, for example a minimum number of contributing
  units) versions side by side with critical values, define the floor or restriction before looking at the contrast,
  and do not word borderline contrasts until B is large.
- Near a max-t threshold, report the Monte Carlo SE of the critical value and each flag's margin in SE units
  (a flag exceeding it by 0.3% with family-wise p about 0.048 is borderline). If two resampling analyses disagree on
  a global max-t p although pointwise estimates agree, compare null SDs per time and leave-one-unit-out estimates,
  and check cumulative outcomes for ties at zero at early times before choosing a story.
- Omnibus bootstrap statistics on a PCA reduction can depend on the retained-variance threshold (one case: p about 0.4
  at 99% and about 0.01 at 99.9%). Pre-declare the threshold, report the number of components, and add a sup-type
  statistic without PCA as a check.
