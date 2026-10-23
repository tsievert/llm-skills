# Recent developments and how to stay current

Compiled October 2026 from the gratia site (version shown there: 0.11.2-66), the gratia changelog, Gavin Simpson's blog and GitHub, mgcv help pages (1.9-4) and package docs. Features were then re-tested against gratia 0.11.2-64 (R-universe build, installed on 2026-10-23; mgcv 1.9-4, R 4.6.0) after an earlier session with gratia 0.11.2.10. Always test the installed version.

## Contents
- Re-check protocol
- Feature timeline and verification status
- Breaking changes that affect plots and code
- Installing a newer gratia
- Other tools worth knowing
- Where to look for new work

## Re-check protocol

1. Installed versions: `packageVersion("gratia")`, `packageVersion("mgcv")`. Compare with CRAN (0.11.2 in October 2026) and the gratia site (https://gavinsimpson.github.io/gratia/). Note that R prints dev versions like `0.11.2-64` as `0.11.2.64`.
2. Function availability: `getNamespaceExports("gratia")`; check `conditional_differences`, `conditional_values`, `response_derivatives`, `ale`, `gratia_theme_set`.
3. Read the changelog top section: https://gavinsimpson.github.io/gratia/news/index.html . Note breaking changes since the user's version.
4. Check gratia articles relevant to the task (list below).
5. Skim recent posts at https://fromthebottomoftheheap.net/ and recent repositories at https://github.com/gavinsimpson (courses, `naboer`, new papers' code).
6. If the installed version is older, use the older-version-safe pattern (for example `predict(type = "lpmatrix")` contrasts) and tell the user what a newer gratia would offer.
7. Do not upgrade packages without asking.

## Feature timeline and verification status

"Verified" means run successfully in the live session; version columns are the builds actually tested.

| Feature | Introduced (from changelog/docs) | 0.11.2.10 | 0.11.2-64 |
|---|---|---|---|
| `response_derivatives()` | gratia 0.9.0 (March 2024) | present, works | present |
| `conditional_values()` | gratia 0.10.0 (December 2024) | present, works | present |
| `conditional_differences()` (whole-model contrasts; `by`, `condition`, `scale`, `uncertainty = "delta"/"simulation"`, `interval = "simultaneous"`, `simultaneous_scope`) | 0.11.x development series; version not stated in the changelog text read | absent | present; verified for factor-by model (CO2 example), `delta` and `simulation`, and for an `sz` model |
| `ale()` (1D accumulated local effects; `interval = "simultaneous"`) | 0.11.x development series | absent | present; verified (`ale(m, focal = "x1")`, `draw()`, simultaneous interval) |
| Theme-based plot customization (`element_geom`, `gratia_theme_set()`, `gratia.alpha.interval`) | development; deprecation warnings cite gratia 0.11.3 | not tested | verified: `p & theme(geom.gratia.smooth = element_geom(...), ...)` and `gratia_theme_set()` work; `smooth_col` gives a deprecation warning |
| Sampling API rework (`n_draws`, `n_grid`) | development | old args accepted | verified: `n_draws` works; `n =` now errors with "Argument 'n' has been removed. Use n_draws. See vignette('sampling-migration')" |
| `fitted_values(interval = "simultaneous")`, `confint(type = "simultaneous")` | long-standing / documented | works | not re-tested |
| `variance_comp()` | documented | present | present; output for `type = "terms"` was identical to `type = "penalty"` in a Gaussian GAM, differing from the site description, so check before using term shares |
| `difference_smooths()` on `bs = "sz"` terms | not documented for `sz` | errors | still errors |
| `shape_intervals()`, `shape_confidence_set()` (shape-constrained smooths) | documented | not tested | exported; not run |
| `simultaneous_bands` | listed on the reference index as a topic | not exported | not exported as a function (appears to be a documentation topic only) |
| `quantile_residuals()`, `dharma_residuals()`, `posterior_predictive_plot()`, `residual_correlation()`, `model_concurvity()`, `get_vcov()` | documented | partly checked earlier | exported in 0.11.2-64; not run |

Installed versions are development builds; their numbering (0.11.2.x, "0.11.3" in warnings) can drift from the site. Prefer testing functions over trusting version numbers.

## Breaking changes that affect plots and code (from the gratia changelog, development version)

- Sampling arguments: `n_draws` (total draws) and `n_grid` (automatic grid); obsolete names raise migration errors (verified for `n`). `derivative_samples()` takes `model` not `object`; `add_*()` sampling helpers take `data`.
- `fitted_samples()` returns all distribution parameters by default; request `quantity = "expectation"` for expected responses. Gaussian LSS now returns the standard deviation rather than its reciprocal.
- `draw.gam()` draws parametric terms by default (`parametric = NULL`); parametric-term intervals include intercept uncertainty by default (`overall_uncertainty = FALSE` for the old behaviour); parametric covariates are plotted as evaluated in the model (use `back_transform = TRUE` for original units). Formals `parametric`, `overall_uncertainty`, `grouped`, `show_ci`, `back_transform` are present in 0.11.2-64 (verified), and `grouped_by` is still present as a deprecated argument.
- Surface default grid is 50 x 50 (`n_2d`); derivative sampling grid defaults to 200 points.
- `grouped_by` deprecated; use `grouped = "factor-by"` (or c("factor-by", "sz", "fs")).
- Colour, alpha, linewidth arguments deprecated in favour of ggplot2 theme settings.
- Dependencies raised (mgcv >= 1.9-4, recent R, ggplot2, patchwork).

## Installing a newer gratia

Notes from this machine (Windows, R 4.6.0, Rtools45), October 2026:
- `remotes::install_github("gavinsimpson/gratia")` compiled the package's C++ code but failed at the load test ("unable to load shared object ... gratia.dll"); the install then rolled back to the previous version. Adding Rtools to `PATH` did not help.
- The R-universe binary worked after an R restart: `install.packages("gratia", repos = c("https://gavinsimpson.r-universe.dev", getOption("repos")), type = "binary")` gave 0.11.2-64. The GitHub `main` branch was at 0.11.2-66 at the time.
- A running session keeps the old namespace loaded; restart R after installing. Ask the user before installing packages.

## Other tools worth knowing

- `marginaleffects` (`predictions()`, `comparisons()`, `slopes()`, `plot_predictions()`, `plot_slopes()`): works with mgcv GAMs and `bam`; gives contrasts and slopes with a delta-method or simulation-based interface, with `exclude` passed through to `predict.gam`. Useful for response-scale comparisons and average predictions; see https://marginaleffects.com/bonus/gam.html. Averaging over the sample (average marginal effects) answers a different question from predictions at fixed covariate values; state which. Not run in this session.
- `ggeffects`, `modelbased`: alternative prediction and marginal-effect interfaces; check how they treat random effects (population-level vs typical group).
- `mgcViz`: alternative interactive visualization of mgcv fits.
- `DHARMa` and gratia's `dharma_residuals()` for simulation-based residual checks.
- gratia articles for specific tasks (pkgdown "Articles"): model diagnostics; prediction comparisons and rates of change; read smooth effects, interactions and surfaces; variance components; data slices; custom plotting; posterior simulation and the migration guide; spatial smooths; shape-constrained intervals; glmmTMB and sdmTMB support.
- Coverage theory: Marra and Wood (2012, Scand J Stat 39:53-74) on across-the-function coverage of Bayesian intervals; Wood (2013, Biometrika) on p-values for smooth components; Nychka (1988) for the original argument.

## Where to look for new work

- gratia changelog and GitHub issues: https://github.com/gavinsimpson/gratia
- Blog: https://fromthebottomoftheheap.net/ (recent posts as of October 2026 include a methods paper on GAMs in animal science with worked examples, and posts on gratia releases)
- GitHub profile for course materials (physalia, Viborg) and `naboer` for neighbourhood cross-validation
- mgcv NEWS: `news(package = "mgcv")` or the CRAN changelog
- For scholarly literature on GAM interpretation, use the `openalex` skill rather than general web search (this project's standing rule).
