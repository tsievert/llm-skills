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
- Dependence
- Sensitivity checks

Sources used: gratia articles (smooth effects, prediction comparisons, posterior simulation, model checking, variance components, data slices), Marra and Wood (2012, Scand J Stat 39:53-74), Wood (2013 p-values), the mgcv help pages. Statements on gratia behaviour were read from the gratia 0.11.2-66 documentation in October 2026; verify against the installed version.

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
- gratia: `interval = "simultaneous"` in `fitted_values()`, `difference_smooths()`; `confint(m, parm = "s(x)", type = "simultaneous")` (verified in 0.11.2.10 and 0.11.2.73); in `confint()` the number of simulations is `nsim` (`n_sim` errors in 0.11.2.73, so check the installed formals); check the stability of the limits across `seed` and the number of simulations. The gratia authors recommend increasing the draws and confirming that conclusions near an interval limit are stable.

## Conditional vs unconditional

By default intervals are conditional on the estimated smoothing parameters. `unconditional = TRUE` (in `predict.gam`, `gratia` functions) adds a correction for smoothing-parameter uncertainty when available (REML/ML); it typically widens intervals slightly. Prefer it for reported intervals when feasible, and state which was used. `frequentist = TRUE` in several gratia functions switches to the covariance of the penalized estimator itself (sampling variability) instead of the posterior covariance; do not mix the two in one report without saying so.

## Link vs response scale

- Smooth plots show contributions on the link scale (log, logit, etc.). They are not effects on the response.
- Compute intervals on the link scale and transform the limits; do not add or subtract standard errors on the response scale.
- Differences on the response scale are nonlinear functions of coefficients; the delta method is an approximation, and simulation can better describe asymmetric uncertainty (gratia's `conditional_differences(uncertainty = "delta" | "simulation")`).
- Interpret back-transformed quantities for the family at hand. For example, in a log-link model, exponentiating a link-scale prediction gives the conditional mean for a Gamma or Poisson model, whereas for a Gaussian model fitted to `log(y)` it is closer to a conditional median of `y`, not the arithmetic mean.
- Ratios and differences are different questions: "twice as many" (link-scale difference in a log model) vs "five more per unit" (response-scale difference).

## Partial effects vs predictions

- A partial effect (one `s()` term) is centred (sums to zero over the data) and excludes the intercept and other terms. In gratia, parametric-effect intervals by default now include intercept uncertainty (a change in recent versions), and covariates are plotted as evaluated in the model (use `back_transform = TRUE` for original units).
- For interactions, random effects, and nonlinear links, a partial effect "need not show the expected response" (gratia, Read smooth effects article). Compose terms before making claims about expected values.
- Subtracting interval endpoints from separate partial-effect plots is not a valid comparison.

## Random effects and held-fixed covariates

- Setting a random effect to zero (via `exclude = "s(g)"` and a dummy level) gives predictions for a typical (zero-deviation) group. With a nonlinear link this is not the population-average response. Say "typical group".
- Excluding or zeroing a covariate smooth that is nearly collinear with a group factor shifts predictions for the groups unequally. Because the smooth is additive on the link scale, the group contrast at an equal covariate value is unaffected, and the distortion is a constant link-scale shift f(x_B) - f(x_A) across all other covariates. Report that shift, and the contrast under group-specific covariate values, as a sensitivity check. It does not fix identifiability: when covariate and group are confounded the contrast is not identified by the data (see concurvity below). Reported from one project, algebra only.
- Prediction bands for expected values exclude observation noise; prediction intervals for new observations need `posterior_samples()` or simulation including response noise.
- Choose held-fixed values deliberately (mean/mode defaults in `data_slice()` are conventions). Results for interacting terms depend on them.
- `data_slice()` fills unspecified covariates with typical values; for derived or interaction factors, set them explicitly. `data_slice(.by = )` restricts each covariate's marginal range per group but not the joint support across several continuous covariates.
- gratia's `fitted_values()` warns when prediction rows contain factor-level combinations absent from the fitting data; treat that as a prompt to check the design, not noise.

## Group comparisons

Two distinct questions:

1. Do the whole expected responses differ? Contrast whole-model predictions (including parametric group effects). gratia: `conditional_differences()` where installed; otherwise a linear-combination contrast from the `lpmatrix` with the joint coefficient covariance (see the `sz_difference()` helper in `gam-mgcv/references/sz-smooths.md`).
2. Do the centred smooth shapes differ? `difference_smooths()` compares smooths with parametric effects omitted by default (`group_means = TRUE` adds the group means). A clear difference in expected response need not mean a clear difference in smooth shape, and vice versa (gratia prediction-comparisons article).

Rules:
- Overlap of two prediction bands does not test their difference; their errors are correlated.
- Check the direction (level order determines subtraction).
- If more than two groups, decide whether the claim concerns each pair separately or any pair, and calibrate accordingly (`simultaneous_scope = "contrast"` vs `"all"` in gratia's `conditional_differences()`).
- For smooths built with `bs = "sz"` or `fs`, see the dedicated notes in `gam-mgcv`.
- With few groups or sparse data per group, intervals may be wide; say so.

## Derivatives and rates of change

- `derivatives()` (smooth contributions, link scale), `response_derivatives()` (complete fitted response, response scale), `partial_derivatives()` (multivariate smooths), `derivative_samples()` (posterior draws).
- Intervals are pointwise unless stated; "SiZer"-style indicators of significant change (`add_sizer()`) inherit that limitation.
- The default finite-difference step `eps = NULL` chooses a step from the covariate range, derivative order and method; it is a heuristic. Near boundaries or with unusual scales, supply a step and check stability.
- Derivative of a smooth on the link scale is not the derivative of the expected response; use `response_derivatives()` for the latter. With transformed covariates, check the units: the derivative with respect to `log(x)` differs from that with respect to `x` by the chain rule.
- Splines can have local decreases or plateaus the data do not support; intervals that include zero indicate an unresolved direction, not zero slope.

## Posterior simulation: which function answers which question

| Function | Answers | Includes |
|---|---|---|
| `smooth_samples()` | uncertainty in one smooth | coefficient uncertainty for that smooth |
| `fitted_samples(quantity = "expectation")` | uncertainty in the expected response | coefficient uncertainty |
| `predicted_samples()` / `simulate()` | what new responses could look like at fitted coefficients | response noise only |
| `posterior_samples()` | prediction intervals including both | coefficient uncertainty plus noise |
| `derivative_samples()` | uncertainty in derivatives of the expectation | coefficient uncertainty, dependence preserved |

- Draws are conditional on smoothing parameters unless `unconditional = TRUE`; neither Gaussian nor Metropolis-Hastings samplers in gratia sample smoothing parameters.
- Default sampler is the Gaussian approximation; `method = "mh"` is available for cases where it is poor (for example binomial with many zeros). Inspect chain diagnostics when using MH.
- Use enough draws for the quantity being estimated; tail quantities and prediction intervals need many more than smooth plots. Re-run with a larger number of draws and a different seed to check stability.
- Recent gratia versions renamed arguments (`n_draws`, `n_grid`; older `n`, `n_sim`, `n_vals`, `freq`, `newdata`); check the sampling-migration article if older code errors.

## p-values, edf, and variance components

- `summary(m)` smooth p-values (Wood 2013 approach) test whether the term is zero; they are approximate, conditional on the smoothing parameters, and say nothing about size or shape. Terms shrunk to near-zero edf can still have p-values; do not read much into them.
- edf: effective degrees of freedom under the penalty; larger means more flexible, not "more significant". `edf` close to `k'` can indicate a basis restriction (check `k.check`), but not by itself.
- `variance_comp()` (gratia) summarizes penalty variances and (with `type = "terms"`) the shares of linear-predictor variance by term. Shares need not sum as expected term-by-term; with correlated terms shares can exceed 1 or be negative; they describe the fitted model on this sample, not importance in general. Check `?variance_comp` for the installed version's output: in 0.11.2.10 and 0.11.2-64 a call with `type = "terms"` returned the same table as `type = "penalty"` for a simple Gaussian GAM (no proportion columns), contrary to the site's description. In 0.11.2.73 it returns the term table with `.proportion` columns and a `total` row (checked on one simulated Gaussian GAM), so older notes about missing shares no longer apply there. Still verify what you get, and do not report term shares unless the output actually contains them.

## Concurvity and identifiability

- `mgcv::concurvity(m, full = TRUE)` (or `gratia::model_concurvity()`): the "worst" case is a upper bound-ish diagnostic; "observed" and "estimate" are alternatives. High values mean one smooth can be approximated by the others; individual smooths may be unreliable and confidence intervals optimistic.
- Do not interpret individual curves of heavily concurve terms as separate effects; report the combined fit or the sensitivity to dropping/adding a term.
- Interaction `ti()` terms with their main effects can be fragile; check.

## Dependence

Residual autocorrelation or clustering makes intervals too narrow. gratia's model-checking article notes: residual correlation plots have no built-in significance bands; lags count observation positions not elapsed time, so ordering and irregular spacing matter; some joint simulation checks are unsupported for correlated BAM and some PQL fits. State remaining dependence as a limitation, and prefer a generative model with a justified correlation structure when joint predictive simulation is needed.

## Sensitivity checks that make an interpretation more honest

- Refit with larger `k` and a different basis (`tp` vs `cr`; `ps` or `bs` for extrapolation-sensitive questions); compare the plotted curves.
- Refit with `select = TRUE`; check whether the conclusion for weak terms persists.
- Compare with a simpler parametric model (linear, polynomial) if the claim is about non-linearity.
- Refit with `unconditional = TRUE` intervals.
- Leave out a block of data (site, year) and check that the curve is stable.
- For bam, compare `discrete = TRUE` against exact fits for a subsample.
