# Visualizing GAMs

## Contents
- Quick start
- Partial effects with partial residuals
- Custom ggplot2 plots
- Predictions on the response scale
- Interactions and surfaces
- Factor smooths and groups
- Group differences
- Models with several distribution parameters, and glmmTMB fits
- Rate of change
- Posterior draws
- Theming gratia plots (current API)
- Common pitfalls

Re-tested 2026-11-24 on the CRAN release gratia 0.12.1 (mgcv 1.9-5); earlier checks used the 0.11.2.x development builds, and statements marked "changelog" were read but not run. Check function availability first (see SKILL.md step 0); the status table is in [recent-developments.md](recent-developments.md).

## Quick start

```r
library(mgcv); library(gratia); library(ggplot2)
m <- gam(y ~ s(x0) + s(x1) + s(x2) + s(x3), data = df, method = "REML")
draw(m)                       # partial effects with intervals
draw(m, residuals = TRUE)     # add partial residuals
appraise(m)                   # diagnostics, not interpretation
```

`draw(m)` returns a patchwork object. Since gratia 0.12 parametric terms are drawn alongside smooths by default (`parametric = NULL`; a model with `Type + Treatment` and two smooths returned 5 panels, 3 with `parametric = FALSE`) and their intervals include intercept uncertainty (`overall_uncertainty = FALSE` for term-only intervals). Count panels before assuming a layout, and say in the caption that parametric panels are on the link scale. For several panels use `ncol`, `select`, and `p & theme_bw()` (note `&`, not `+`, so the theme is applied to every panel). `draw(m, wrap = FALSE)` returns a list of plots.

## Partial effects with partial residuals

- Partial residuals show how well the term summarizes the data, and where data exist. Prefer `draw(m, residuals = TRUE)` for exploratory and diagnostic figures. They can be noisy for non-Gaussian families; the point cloud shows scatter, not uncertainty.
- Add a rug when residuals would clutter; `draw()` includes a rug by default.
- Centred partial effect: the y-axis is not the response. Label it.

## Custom ggplot2 plots

```r
sm <- smooth_estimates(m, select = "s(x2)") |>
  add_confint()
ggplot(sm, aes(x2, .estimate)) +
  geom_ribbon(aes(ymin = .lower_ci, ymax = .upper_ci), alpha = 0.2) +
  geom_line() +
  geom_rug(data = df, aes(x = x2, y = NULL), sides = "b", alpha = 0.3) +
  labs(x = "x2", y = "Partial effect (link scale)")
```

Add partial residuals with `add_partial_residuals(df, m, select = "s(x2)")`. For transformed covariates (for example `s(log(x))`) use `smooth_estimates(m, back_transform = TRUE)`; the evaluation grid is then even in the raw covariate and a `.gratia_raw_x` column is added (checked in 0.12.1). `draw()`, `assemble()` and `parametric_effects()` take the same argument; without it, parametric plots use the covariate as evaluated in the model (`log(x)` against `log(x)`). If gratia cannot find the data for a transformed term, pass `envir = environment()`.

Simultaneous band (verified in 0.12.1 with `nsim`): `confint(m, parm = "s(x2)", type = "simultaneous", shift = TRUE, nsim = 5000)` returns `.lower_ci`/`.upper_ci` and `.crit`; `shift = TRUE` adds the model constant to put the band on the level of the linear predictor. Since 0.12, `draw()` and `smooth_estimates()` also take `interval = "simultaneous"` (with `n_sim`, `seed`), so a custom ggplot is not needed just for the band. `simultaneous_method = "tube"` requests continuous-interval Gaussian bands for supported one-dimensional cubic splines (changelog: a conservative bound); it ran for `tp` and `cr` smooths and returned `.crit` (3.10 and 3.09 on one simulated model). Report the method, `nsim` and seed, and check stability across seeds.

## Predictions on the response scale

```r
grid <- data_slice(m, x2 = evenly(x2, n = 100))      # other covariates at typical values
fv <- fitted_values(m, data = grid, interval = "simultaneous", n_sim = 2000, seed = 11)
ggplot(fv, aes(x2, .fitted)) +
  geom_ribbon(aes(ymin = .lower_ci, ymax = .upper_ci), alpha = 0.2) +
  geom_line() + labs(y = "Expected response")
```

- `fitted_values()` and `fitted_samples()` return every distribution parameter represented by a predictor by default (a `.parameter` column); add `quantity = "expectation"` for the expected response. In `fitted_values(interval = "simultaneous")` the simulation count is `n_sim`; in 0.12.1 `n_draws` is silently ignored there (band width unchanged), so a call that runs is not evidence the setting took effect.
- Say which covariates are held fixed and at what values; report the intervals as intervals for the expected response, not for new observations.
- Random effects: `exclude = "s(g)"` and supply a level in `data_slice()`; label as "typical group". For a new, unobserved group, or a group average that integrates over the random effects, gratia 0.12 has `marginalise = TRUE` in `fitted_values()`/`fitted_samples()` (ran on a `bs = "re"` model; not checked against a manual integral) and `random_effect_samples()`. Smoothing parameters and dispersion stay fixed and fits using `min.sp` are rejected. This answers a different question from the typical-group curve; say which one is shown.
- Use `conditional_values()` (gratia >= 0.10.0) to condition on chosen covariates.
- Restrict to supported combinations, e.g. `data_slice(m, x = evenly(x, 50), .by = group)`. This limits each covariate's marginal range, not the joint support.
- Overlay observed data or binned means only if clearly distinguished from the model fit.

## Interactions and surfaces

- `draw()` shows 2D smooths as contour/raster surfaces (default grid `n_2d = 50`); more numeric dimensions become conditioning slices, factors become facets. `n_3d`, `n_4d` limit the number of conditioning slices (and, per gratia, restrict factor levels to the first levels in fitted order).
- Use the diverging partial-effect palette centred at zero.
- Mask regions far from data with `too_far`-style masks; the `dist` argument in `draw()` for surfaces hides poorly supported areas after scaling axes to the unit square. Support is pooled across facets, so a visible region can still lie outside an individual group's data.
- `surface = "tile"` draws vector rectangles (useful for PDF export); `surface = "3d"` needs the optional `ggcube` and `sf` packages (both; the error names one at a time) and `ci_3d = TRUE` adds interval surfaces. Viewing angle changes appearance only. Tile and 3D (with and without `ci_3d`) ran in 0.12.1; the 3D images were not inspected, so check them before use. Rotating a 3D surface is a poor way to compare heights; prefer contours or slices for reporting.
- Two numeric covariates in one `conditional_values()` condition, for example `condition = list(c("x0", "x1"))`, give a prediction surface (50 x 50 grid, checked); `conditional_differences()` does the same for difference surfaces.
- Cyclic smooths: `cyclic = "polar"` draws a polar plot (0.12.1: ran on a `cc` smooth and a factor-by one; the viewed plot put 0 at the top with the rug outside the ring and the radial axis inside the circle). Radial distance is the partial effect, which can include negative values, so the ring's size is not an effect size; it can also mislead if the cycle boundary is arbitrary. Keep a Cartesian version beside it, and use `polar_args` for display tweaks.
- For `te()`/`ti()`, plot main effects and the interaction separately; the interaction alone is not the response.
- Spatial smooths: choose by geometry (MRF for areal data, soap film for bounded domains, `sos` for global data); penalty plots show basis coefficients, not areas. MRF intervals assume independent errors; inspect residual spatial patterns.

## Factor smooths and groups

- `grouped` names which of `"factor-by"`, `"sz"`, `"fs"` curves are overlaid (default `c("sz", "fs")`); `show_ci` chooses which show ribbons (default `c("factor-by", "sz")`). `grouped_by` is deprecated and warns (checked in 0.12.1). `grouped = FALSE` separates every factor-related curve.
- With many levels, overlaid curves become unreadable (gratia issue #244; since 0.12 `grouped` can give separate plots). If the result is still crowded, facet by level with `smooth_estimates()` output; `draw_label_control()` wraps long legend and axis labels.
- For `sz` terms the plotted curves are deviations from the main smooth; level curves require whole-model predictions (see `gam-mgcv/references/sz-smooths.md`).
- Random-effect smooths: `re_levels` selects which levels to draw; this does not refit or remove the term from predictions.

## Group differences

- Whole-response contrasts: `conditional_differences()` (verified in 0.11.2-64, 0.11.2.73 and 0.12.1, absent in 0.11.2.10; supply both `by` (the factor) and `condition` (the covariate), e.g. `by = "Type", condition = "conc"`). `draw()` on the result shows differences with a zero reference line, faceted by comparison, coloured by the conditioning factor (verified), and the call below also works on `sz` models.

```r
cd <- conditional_differences(m, by = "Treatment", condition = c("conc", "Type"),
  exclude = "s(Plant)", scale = "response", uncertainty = "delta",
  interval = "simultaneous", simultaneous_scope = "contrast",
  n_vals = 60, n_sim = 2000, seed = 2026)
draw(cd)
```

- Accumulated local effects (`ale()`, verified in 0.11.2-64, 0.11.2.73 and 0.12.1): `a <- ale(m, focal = "x1"); draw(a)`, with `interval = "simultaneous"`, `scale = "response"` available. ALE combines all terms involving the covariate and averages over the reference data; it is a different quantity from a partial effect or a conditional prediction, so label it "ALE".
- Rejoining covariates after `response_derivatives()`: with `uncertainty = "simulation"` a covariate that enters the model only through `sz` smooths is dropped from the output, while `delta` keeps it, so a `left_join()` on `.row` gives `.x`/`.y` columns under one method and none under the other. Restore only the columns that are missing, from the input data by `.row` (for example `nd[x$.row, setdiff(names(nd), names(x)), drop = FALSE]`). Reported from one project (two sessions), not re-run here.
- Sampling-argument names differ per function (reported, check `?fn` for the installed gratia): `fitted_samples(n =)` errors and `n_draws` works; `response_derivatives(n_sim =)` works and `n_draws` errors.
- Shape-only: `difference_smooths(m, select = "s(x)", interval = "simultaneous")` (factor-by smooths; still errors on `sz`). In 0.12.1 it also ran on the `CO2` factor-by model whose levels have different `conc` grids, which failed in 0.11.2.73. `order = 1` returns differences of derivatives (ran; interpretation not checked).
- The same smooth in two models (for example with and without a covariate): `compare_smooths(m1, m2, select = "s(x)")` and `draw(..., show = "difference", pair = ...)` (0.12; `compare_smooths()` ran, drawing not run). Differences between two fits include model-selection effects; do not treat the band as a test.
- Never compare by overlaying bands and eyeballing overlap.

## Models with several distribution parameters, and glmmTMB fits

- `fitted_moments()` and `conditional_moments()` (0.12) return the response mean, variance and coefficient of variation (also SD, skewness, kurtosis where they exist) in long format with delta-method intervals. Checked against analytic values for Poisson, Gamma (log link) and `gaulss()`. Use them when the question is about the response distribution (spread, not only mean) rather than a single smooth. `nuisance = "fixed"` conditions on fitted dispersion and global parameters, which understates uncertainty.
- `fitted_samples()` for `gaulss()` returns `mean` and `sd` by default; ask for `quantity = "expectation"` for one expectation series.
- glmmTMB fits: `draw()` returned smooth panels, a Gaussian QQ panel per random intercept and a pointrange for factor terms; `assemble()` returns the same as a named list; Poisson and zero-inflation smooths also drew. `ranef_lines = TRUE` replaces the QQ panel of a `(1 + x | g)` pair by lines (ran; not inspected). Intervals use the TMB joint covariance; see `?'glmmTMB-methods'` for limits. `gratia::fixed_effects()` does not work for glmmTMB: use `glmmTMB::fixef()`.

## Rate of change

```r
d <- derivatives(m, select = "s(x2)", data = grid)       # smooth derivative (link scale)
rd <- response_derivatives(m, focal = "x2", data = grid, type = "central",
                           n_sim = 2000, seed = 5)        # response-scale derivative
draw(d)
```

State the scale and that intervals are pointwise unless otherwise noted. Since 0.12 the finite-difference step is chosen automatically (`eps = NULL`) and `derivative_samples()` uses a 200-point grid by default (`n_grid = 100` for the old resolution), so results can differ slightly from older runs. `response_derivatives()` takes `uncertainty = "delta"` or simulation (`n_sim`; `n_draws` errors there). Plot with a zero line; avoid colouring regions as "significant increase/decrease" without stating the pointwise caveat.

## Posterior draws

`smooth_samples()` and `draw()` on the result show plausible curves; a spaghetti plot of draws conveys uncertainty about shape better than a band alone. Use `fitted_samples(quantity = "expectation")` for expected responses, `posterior_samples()` for prediction intervals. Compute derived quantities (peak, threshold, area) per draw. Fix a `seed` and report `n_draws`; check stability with more draws. `posterior_samples()` uses separate random-number streams for coefficient and response draws since 0.12, so seeded results from older versions will not reproduce. `smooth_samples()` on a poorly conditioned `sz` model printed a one-time "Cholesky decomposition failed; using mgcv::rmvn()" warning (draws were returned). Multi-chain Metropolis-Hastings draws come with `sampling_diagnostics()` and `as_mcmc_draws()` (changelog, not run).

## Theming gratia plots (current API)

gratia 0.12 deprecates colour/alpha/linewidth arguments of `draw()` (`smooth_col`, `ci_col`, `ci_alpha`, ...) in favour of ggplot2 theme settings; explicit old arguments still work as fixed overrides during the migration (see the "Customising gratia plots" article and `?gratia_theme_get`). It needs ggplot2 >= 4.0.3 and patchwork >= 1.3.2; `element_geom()` comes from ggplot2:

```r
p <- draw(m)
p & theme(
  geom.gratia.smooth = element_geom(colour = "navy", linewidth = 0.8),
  geom.gratia.interval = element_geom(fill = "navy"),
  gratia.alpha.interval = 0.15
)
old <- gratia_theme_set(theme(gratia.alpha.interval = 0.1))   # package-wide; restore with gratia_theme_set(old)
```

Palettes: `gratia_palette("tol_banded_16")` with `theme(palette.colour.discrete = ..., palette.fill.discrete = ...)`. Verified in 0.11.2-64 and 0.12.1 (theme call and `smooth_col` warning): the `&` + `theme(geom.gratia.smooth = element_geom(...), geom.gratia.interval = element_geom(...), gratia.alpha.interval = ...)` call and `gratia_theme_set()` work (the first `gratia_theme_set()` call returned `NULL`, meaning no previous theme was set); the old `smooth_col` argument gives a deprecation warning ("deprecated as of gratia 0.11.3"). If the installed gratia is older, these `theme()` elements may not exist; check `?gratia_theme_get`.

## Common pitfalls

- Reading the centred smooth as the expected response.
- Plotting only the line with no data support (no rug, no residuals).
- Plotting predictions across the full covariate range for every group when some groups have narrower ranges.
- Using pointwise bands for claims about the shape of the whole curve.
- Back-transforming a link-scale curve and presenting it as an "effect" without stating the baseline.
- Colour scales that are not centred at zero for partial-effect surfaces.
- Identical y-axis ranges hiding or exaggerating effect sizes; state the scale.
- Displaying results from a model with unresolved dependence or concurvity without caveat.
- Using `+ theme_x()` on a `draw()` patchwork (applies to the last panel only); use `&`.
- Re-running an old script after upgrading to 0.12 without checking panel count, parametric-term intervals and deprecated arguments; layout and intervals can change without an error.
- Trusting that an argument took effect because the call ran: some functions silently ignore a renamed argument (see `n_draws` in `fitted_values()` above).
