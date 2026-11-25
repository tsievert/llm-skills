# Recent developments and how to stay current

Compiled October 2026 and revised 2026-11-24 for the CRAN release gratia 0.12.1 (the changelog top section was read in full; the tests in the status table below were run on 0.12.1 with mgcv 1.9-5, R 4.6.0, ggplot2 4.0.3 on synthetic data and the `CO2` data). Earlier tests used the development builds 0.11.2.10, 0.11.2-64 and 0.11.2.73 (GitHub `main`). Always test the installed version.

## Contents
- Re-check protocol
- What 0.12.1 changed (changelog, grouped by what it means for work)
- Feature status table (tested)
- Breaking changes that affect plots and code
- Installing gratia
- Other tools worth knowing
- Where to look for new work

## Re-check protocol

1. Installed versions: `packageVersion("gratia")`, `packageVersion("mgcv")`. Compare with CRAN and the gratia site (https://gavinsimpson.github.io/gratia/). R prints dev versions like `0.12.1-3` as `0.12.1.3`. gratia 0.12.1 requires R >= 4.4.0, mgcv >= 1.9-4, ggplot2 >= 4.0.3 and patchwork >= 1.3.2, so an older stack cannot install it.
2. Function availability: `getNamespaceExports("gratia")`; for the current release check at least `conditional_differences`, `conditional_values`, `response_derivatives`, `ale`, `compare_smooths`, `random_effect_samples`, `fixed_effects`, `gratia_theme_set`.
3. Read the changelog top section (`utils::news(package = "gratia")` works offline for the installed version; online: https://gavinsimpson.github.io/gratia/news/index.html). Note breaking changes since the user's version.
4. Check gratia articles relevant to the task (list below), especially the sampling migration guide (https://gavinsimpson.github.io/gratia/articles/sampling-migration.html).
5. Skim recent posts at https://fromthebottomoftheheap.net/ and recent repositories at https://github.com/gavinsimpson.
6. If the installed version is older, use the older-version-safe pattern (for example `predict(type = "lpmatrix")` contrasts) and tell the user what a newer gratia would offer.
7. Do not upgrade packages without asking.
8. Argument names for simulation counts are not uniform across functions (see "Breaking changes"). When code errors or seems to ignore a setting, read `?fn` for the installed version; do not assume `n_draws` everywhere.

## What 0.12.1 changed (changelog, grouped)

Version 0.12.0 was never released; 0.12.1 contains its changes. Items below are from the changelog; the status table says what was run.

Plotting and layout
- `draw()`/`assemble()` draw parametric terms by default (`parametric = NULL`); parametric intervals include intercept uncertainty (`overall_uncertainty = FALSE` restores term-only intervals).
- `grouped` (which of "factor-by", "sz", "fs" curves are overlaid) and `show_ci` replace `grouped_by`; `sz` and `fs` curves can be drawn in separate plots (issue #244).
- Colour, alpha and linewidth arguments are deprecated in favour of ggplot2 theme components (`theme(geom.gratia.smooth = element_geom(...), gratia.alpha.interval = ...)`, `gratia_theme_get()/set()/update()`, `gratia_palette()`).
- `draw_label_control()` for wrapping and staggering labels; `surface = "tile"` and optional `surface = "3d"` (ggcube) for surfaces, `ci_3d = TRUE` for interval surfaces; `cyclic = "polar"` for polar plots of cyclic smooths; `back_transform = TRUE` for original covariate scales; `variables` to choose the axes and facet order; `appraise()` switches to scalable plots from 10,000 observations.
- `assemble()` now handles `gamm()`, glmmTMB and `GJRM::gamlss()` fits; `draw()`/`smooth_estimates()` support glmmTMB, sdmTMB, gamm4 and GJRM models; SCAM models and all `scam` constructors are supported.

Inference and comparison
- Simultaneous bands for single smooths (`draw()`, `smooth_estimates()` with `interval = "simultaneous"`), for `difference_smooths()` and `fitted_values()`; continuous-interval Gaussian bands for supported one-dimensional cubic splines via `simultaneous_method = "tube"` (described as a conservative threshold-crossing bound).
- `conditional_differences()` and `conditional_values()` can grid two numeric covariates for difference or prediction surfaces.
- `compare_smooths()` compares smooths of two models at common locations; `draw(show = "difference", pair = ...)` plots one model's smooth minus another's.
- `difference_smooths()` gains derivatives of differences (`order`, `focal`) and works across 3D/4D smooths as faceted surfaces.
- `response_derivatives(uncertainty = "delta")`; derivative step size is chosen automatically when `eps = NULL`.
- `variance_comp(type = "terms")` returns term variances and proportions of total variance with intervals, with a `draw()` method; supported for `gam()`, `bam()`, `gamm()`, `gamm4()`.
- `random_effect_samples()` and the `marginalise` option of fitted-value and response-simulation functions integrate over new-group random effects (Gaussian quadrature or Monte Carlo; fits using `min.sp` are rejected).
- `fitted_moments()`/`conditional_moments()` (means, variances, SDs, skewness, kurtosis of the response distribution), `family_parameters()`, `ale()`.

Diagnostics
- Probability-integral-transform (quantile) residuals, `dharma_residuals()` (simulation-based, no DHARMa needed), surrogate residuals for `ocat()`/`multinom()`, scalable plots, `residuals_covariate_plot()`, `residual_correlation()`, posterior predictive checks (`posterior_predictive_plot()`, `appraise(ppcheck = TRUE)`), and diagnostics for glmmTMB, lme4, nlme, sdmTMB, GJRM and `gamm4` fits. For `tw()`/`Tweedie()` models `appraise()` selects simulation reference bands automatically.
- `log_lik()`, `loo::loo()`, `loo::waic()` and `bayesplot::pp_check()` methods for independent GAM/BAM fits; multi-chain Metropolis-Hastings sampling with `sampling_diagnostics()`.

Housekeeping
- `fixef()` re-export removed: use `gratia::fixed_effects()` (or `nlme::fixef()` / `lme4::fixef()` / `glmmTMB::fixef()` for fits from those packages; `fixed_effects()` errors on glmmTMB fits).
- mgcv B-spline tensor products (`bs = "bt"`, mgcv >= 1.9-5) are supported; `mirai::daemons()` workers speed up derivatives, smooth sampling and ALE.
- glmmTMB support needs the released glmmTMB 1.1.15.2 or later.

## Feature status table (tested)

"Run" means the call executed in a fresh R session; output was checked only where a result is named.

| Feature | 0.11.2.73 (dev) | 0.12.1 (CRAN) |
|---|---|---|
| `response_derivatives()` | works | works; simulation count is `n_sim` (`n_draws` errors: "matched by multiple actual arguments"); `uncertainty = "delta"` runs |
| `conditional_values()` | works | works; two numeric covariates in one condition give a 50 x 50 grid |
| `conditional_differences()` (`by` and `condition` both required) | verified, incl. `sz` | verified on a factor-by and an `sz` model; `n_sim` works, `n_draws` errors |
| `ale()`, `draw()` | works | works (41-row result for a one-covariate call) |
| `fitted_values(interval = "simultaneous")` | works with `n_sim` | `n_sim` changes the band (mean width 2.64 at 50 draws vs 2.71 at 5,000); `n_draws` is **silently ignored** (result identical to no setting) |
| `confint(type = "simultaneous")` | `nsim` | `nsim` works; `n_draws` also accepted and returned a result (not checked whether it takes effect); do not rely on it |
| `smooth_samples(n =)` | errors with migration message | same message; `n_draws` works |
| `fitted_samples()` | `quantity` not documented | returns a `.parameter` column; `quantity = "expectation"` accepted (identical for a Gaussian identity-link model, where location is the expectation) |
| `derivative_samples(n_draws =)` | not tested | runs; default grid 200 |
| `variance_comp(type = "terms")` | has `.proportion*` and a `total` row | same; `.proportion` columns with intervals confirmed on a simulated Gaussian GAM |
| `difference_smooths()` on factor-by (`CO2`, unequal `conc` grids per level) | errored ("same prediction grid") | runs (100 rows); `interval = "simultaneous"` and `order = 1` also run |
| `difference_smooths()` on `bs = "sz"` | errors | **still errors** (`subscript out of bounds`) |
| `derivatives()`, `smooth_samples()`, `draw()` on `sz` | work | work (`smooth_samples` printed a Cholesky fallback warning to `mgcv::rmvn()` once) |
| `simultaneous_method = "tube"` in `derivatives()`, `smooth_estimates()` | not present | runs for `tp` and `cr` smooths of one covariate and returns `.crit`; the changelog restricts it to supported one-dimensional cubic splines; the `tp` result was not checked against the documentation's supported list |
| `compare_smooths()` | not present | runs (2 rows x 5 columns for one smooth); not plotted |
| `random_effect_samples()` | not present | runs on a model with `s(Plant, bs = "re")` |
| `marginalise = TRUE` in `fitted_values()`, `fitted_samples()` | not present | runs on a `bs = "re"` model; numbers not checked against a manual integral |
| `fixef()` | exported | **removed**; `fixed_effects()` returns the named coefficient vector |
| `dharma_residuals()` | ran | returns a plain numeric vector |
| theme API (`geom.gratia.smooth = element_geom(...)`); `smooth_col` deprecation | works | works; `smooth_col` still warns (deprecated as of 0.11.3) |
| `grouped_by` | present | deprecated; warns and points to `grouped` |
| `parametric_effects(transform =)` | accepted | deprecated; use `back_transform = !transform` |
| `evaluate_smooth()` | exported, defunct | exported, errors ("defunct", use `smooth_estimates()`) |
| `draw()` default panels | smooths only | smooths plus parametric terms (5 panels vs 3 with `parametric = FALSE` for a model with `Type + Treatment` and two smooths) |
| `draw(cyclic = "polar")` | not present | runs on a `cc` smooth (image viewed: 0 at top, rug outside the ring) and on a factor-by cyclic smooth |
| `draw(surface = "tile")`; `surface = "3d"` with `ci_3d = TRUE` | not present | tile runs. 3D needs **both** `ggcube` and `sf` (errors name them one at a time); with both installed it ran for an `s(x, z)` surface and a `conditional_values()` surface, images not viewed |
| `draw_label_control()` | not present | runs; effect on labels not inspected |
| `fitted_moments()`, `conditional_moments()`, `family_parameters()` | not present | run; long format (`.parameter` = mean, variance, cv). Checked against analytic values for Poisson, Gamma (log link; mean equals `predict(type = "response")`) and `gaulss()` (variance equals (1/tau)^2 from `predict`) |
| `fitted_samples()` on `gaulss()` | not tested | default returns `mean` and `sd`; `quantity = "expectation"` returns one `expectation` series |
| `shape_intervals()` | not tested | needs `estimate`, `lower`, `upper`, `data` (complete grid) and a named `constraints` list; on hand-made bands monotone and convex outputs satisfied the shape and the band width did not grow. Not callable on a `smooth_estimates()` tibble alone |
| `draw()`/`smooth_estimates()`/`confint()` with `interval_method = "shape"` on an `scasm()` fit | not tested | run, each with the warning that pointwise calibration is not guaranteed |
| glmmTMB: `draw()`, `assemble()`, `smooth_estimates()`, `appraise()` | not tested | run (smooth, random-intercept QQ and factor panels; Poisson and zero-inflation smooths also drew). `fixed_effects()` errors for glmmTMB: use `glmmTMB::fixef()` |
| `shape_confidence_set()`, `surrogate_residuals()`, `residuals_covariate_plot()` | not tested | exported; not run |
| sdmTMB, SCAM, `loo`/`bayesplot` methods, GJRM, mirai workers | not tested | not run (packages not installed or not exercised) |
| `simultaneous_bands` | not a function | not a function |

## Breaking changes that affect plots and code

- Sampling arguments: `n_draws` (total draws) and `n_grid` (automatic grid) for the `*_samples()` family and `add_*()` helpers; obsolete names (`n`, `n_sim`, `n_vals`, `freq`, `newdata`, `ncores`) raise migration errors there. `derivative_samples()` takes `model` not `object`; the `add_*()` helpers take `data`. Simulation arguments must be named.
- Exceptions that matter: `response_derivatives()`, `conditional_differences()`, `fitted_values(interval = "simultaneous")`, `difference_smooths()` and `draw()`/`smooth_estimates()` bands still take `n_sim` in 0.12.1 (tested above). Passing the wrong name either errors or is silently ignored depending on the function, so check the effect (for example, the band width), not just that the call runs.
- `fitted_samples()` and `fitted_values()` return all distribution parameters represented by predictors by default; request `quantity = "expectation"` for expected responses (response scale only). Gaussian location-scale models now return the standard deviation, not its reciprocal.
- Derivative sampling grid defaults to 200 points (`n_grid = 100` for the old resolution); surface grids default to 50 x 50 (`n_2d`).
- `draw.gam()` draws parametric terms by default and with intercept uncertainty; with `back_transform = FALSE` parametric plots use covariates as evaluated in the model (`log(x)` against `log(x)`).
- `draw.basis()` draws contour lines by default (`contour = FALSE` to restore).
- Native `mgcv::scasm()` smooths default to `overall_uncertainty = FALSE`.
- `posterior_samples()` uses separate random-number streams for coefficients and responses, so seeded response draws differ from older releases.
- `fixef()` removed (above). `grouped_by`, colour/alpha arguments, `transform` in `parametric_effects()` deprecated.
- Dependencies raised (above). `tweedie` is now optional (needed only for `fallback = TRUE`); `ggokabeito` is no longer required; default colours are unchanged.

## Installing gratia

- 0.12.1 is on CRAN. A plain `install.packages("gratia")` is enough; the GitHub and R-universe routes that were needed for 0.11.2-x features are no longer necessary. Installs from GitHub or other non-CRAN sources still need the user's explicit permission (project rule).
- It needs R >= 4.4.0, mgcv >= 1.9-4, ggplot2 >= 4.0.3 and patchwork >= 1.3.2; updating these first may be needed.
- Historical note (October 2026, Windows, R 4.6.0, Rtools45): `remotes::install_github("gavinsimpson/gratia")` once compiled but failed the load test with "unable to load shared object ... gratia.dll" and rolled back; a later attempt succeeded, and the R-universe binary also worked. If a dev build fails to load, fall back to CRAN.
- A running session keeps the old namespace loaded; restart R (or `unloadNamespace("gratia")`) after installing. Ask the user before installing packages. To test the installed build rather than the loaded one, run the check in a fresh process, for example `callr::rscript()`.

## Other tools worth knowing

- `marginaleffects` (`predictions()`, `comparisons()`, `slopes()`, `plot_predictions()`, `plot_slopes()`): works with mgcv GAMs and `bam`; gives contrasts and slopes with a delta-method or simulation-based interface, with `exclude` passed through to `predict.gam`. Useful for response-scale comparisons and average predictions; see https://marginaleffects.com/bonus/gam.html. Averaging over the sample (average marginal effects) answers a different question from predictions at fixed covariate values; state which. Not run in this session.
- `ggeffects`, `modelbased`: alternative prediction and marginal-effect interfaces; check how they treat random effects (population-level vs typical group).
- `mgcViz`: alternative interactive visualization of mgcv fits.
- `DHARMa` and gratia's `dharma_residuals()` (no DHARMa dependency) for simulation-based residual checks.
- `compare_smooths()` and `difference_smooths()` for comparing smooths across models or levels; `random_effect_samples()` and `marginalise` for new-group uncertainty (previously done by hand).
- gratia articles for specific tasks (pkgdown "Articles"): model diagnostics; prediction comparisons and rates of change; read smooth effects, interactions and surfaces; variance components; data slices; custom plotting and the Customising gratia plots (theme migration) article; posterior simulation and the sampling migration guide; transformed covariates; spatial smooths; shape-constrained intervals; SCAM, glmmTMB and sdmTMB support.
- Coverage theory: Marra and Wood (2012, Scand J Stat 39:53-74) on across-the-function coverage of Bayesian intervals; Wood (2013, Biometrika) on p-values for smooth components; Nychka (1988) for the original argument.

## Where to look for new work

- gratia changelog and GitHub issues: https://github.com/gavinsimpson/gratia
- Blog: https://fromthebottomoftheheap.net/
- GitHub profile for course materials (physalia, Viborg) and `naboer` for neighbourhood cross-validation
- mgcv NEWS: `news(package = "mgcv")` or the CRAN changelog
- For scholarly literature on GAM interpretation, use the `openalex` skill rather than general web search (this project's standing rule).
