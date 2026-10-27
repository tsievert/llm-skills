# Visualizing GAMs

## Contents
- Quick start
- Partial effects with partial residuals
- Custom ggplot2 plots
- Predictions on the response scale
- Interactions and surfaces
- Factor smooths and groups
- Group differences
- Rate of change
- Posterior draws
- Theming gratia plots (current API)
- Common pitfalls

Verified against gratia 0.11.2.10 / 0.11.2-64 / 0.11.2.73 (the last re-tested 2026-10-27) with mgcv 1.9-4 where noted; other statements come from the gratia 0.11.2-66 documentation (October 2026). Check function availability first (see SKILL.md step 0).

## Quick start

```r
library(mgcv); library(gratia); library(ggplot2)
m <- gam(y ~ s(x0) + s(x1) + s(x2) + s(x3), data = df, method = "REML")
draw(m)                       # partial effects with intervals
draw(m, residuals = TRUE)     # add partial residuals
appraise(m)                   # diagnostics, not interpretation
```

`draw(m)` returns a patchwork object. In recent gratia versions parametric terms are drawn alongside smooths by default (`parametric = NULL`); use `parametric = FALSE` for the old behaviour. For several panels use `ncol`, `select`, and `p & theme_bw()` (note `&`, not `+`, so the theme is applied to every panel).

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

Add partial residuals with `add_partial_residuals(df, m, select = "s(x2)")`. For transformed covariates use `smooth_estimates(m, back_transform = TRUE)`; the evaluation grid is then even in the raw covariate. If gratia cannot find the data for a transformed term, pass `envir = environment()`.

Simultaneous band (verified in 0.11.2.73 with `nsim`; the 0.11.2.10 note used `n_sim`, which now errors): `confint(m, parm = "s(x2)", type = "simultaneous", shift = TRUE, nsim = 5000)` returns `.lower_ci`/`.upper_ci` and `.crit`; `shift = TRUE` adds the model constant to put the band on the level of the linear predictor. Note the argument semantics in the installed version before use.

## Predictions on the response scale

```r
grid <- data_slice(m, x2 = evenly(x2, n = 100))      # other covariates at typical values
fv <- fitted_values(m, data = grid, interval = "simultaneous", n_sim = 2000, seed = 11)
ggplot(fv, aes(x2, .fitted)) +
  geom_ribbon(aes(ymin = .lower_ci, ymax = .upper_ci), alpha = 0.2) +
  geom_line() + labs(y = "Expected response")
```

- Say which covariates are held fixed and at what values; report the intervals as intervals for the expected response, not for new observations.
- Random effects: `exclude = "s(g)"` and supply a level in `data_slice()`; label as "typical group".
- Use `conditional_values()` (gratia >= 0.10.0) to condition on chosen covariates.
- Restrict to supported combinations, e.g. `data_slice(m, x = evenly(x, 50), .by = group)`. This limits each covariate's marginal range, not the joint support.
- Overlay observed data or binned means only if clearly distinguished from the model fit.

## Interactions and surfaces

- `draw()` shows 2D smooths as contour/raster surfaces (default grid `n_2d = 50`); more numeric dimensions become conditioning slices, factors become facets. `n_3d`, `n_4d` limit the number of conditioning slices (and, per gratia, restrict factor levels to the first levels in fitted order).
- Use the diverging partial-effect palette centred at zero.
- Mask regions far from data with `too_far`-style masks; the `dist` argument in `draw()` for surfaces hides poorly supported areas after scaling axes to the unit square. Support is pooled across facets, so a visible region can still lie outside an individual group's data.
- 3D views (`surface = "3d"`) need the optional ggcube package; viewing angle changes appearance only.
- For `te()`/`ti()`, plot main effects and the interaction separately; the interaction alone is not the response.
- Spatial smooths: choose by geometry (MRF for areal data, soap film for bounded domains, `sos` for global data); penalty plots show basis coefficients, not areas. MRF intervals assume independent errors; inspect residual spatial patterns.

## Factor smooths and groups

- `grouped = c("factor-by", "sz", "fs")` controls which factor smooths share a panel; `show_ci` chooses which show ribbons. (`grouped_by` is deprecated.)
- With many levels, overlaid curves become unreadable (gratia issue #244). Facet by level with `smooth_estimates()` output.
- For `sz` terms the plotted curves are deviations from the main smooth; level curves require whole-model predictions (see `gam-mgcv/references/sz-smooths.md`).
- Random-effect smooths: `re_levels` selects which levels to draw; this does not refit or remove the term from predictions.

## Group differences

- Whole-response contrasts: `conditional_differences()` (verified in 0.11.2-64 and 0.11.2.73, absent in 0.11.2.10; supply both `by` (the factor) and `condition` (the covariate), e.g. `by = "Type", condition = "conc"`). `draw()` on the result shows differences with a zero reference line, faceted by comparison, coloured by the conditioning factor (verified), and the call below also works on `sz` models.

```r
cd <- conditional_differences(m, by = "Treatment", condition = c("conc", "Type"),
  exclude = "s(Plant)", scale = "response", uncertainty = "delta",
  interval = "simultaneous", simultaneous_scope = "contrast",
  n_vals = 60, n_sim = 2000, seed = 2026)
draw(cd)
```

- Accumulated local effects (`ale()`, verified in 0.11.2-64 and 0.11.2.73): `a <- ale(m, focal = "x1"); draw(a)`, with `interval = "simultaneous"`, `scale = "response"` available. ALE combines all terms involving the covariate and averages over the reference data; it is a different quantity from a partial effect or a conditional prediction, so label it "ALE".
- Shape-only: `difference_smooths(m, select = "s(x)", interval = "simultaneous")`.
- Never compare by overlaying bands and eyeballing overlap.

## Rate of change

```r
d <- derivatives(m, select = "s(x2)", data = grid)       # smooth derivative (link scale)
rd <- response_derivatives(m, focal = "x2", data = grid, type = "central",
                           n_sim = 2000, seed = 5)        # response-scale derivative
draw(d)
```

State the scale and that intervals are pointwise unless otherwise noted. Plot with a zero line; avoid colouring regions as "significant increase/decrease" without stating the pointwise caveat.

## Posterior draws

`smooth_samples()` and `draw()` on the result show plausible curves; a spaghetti plot of draws conveys uncertainty about shape better than a band alone. Use `fitted_samples(quantity = "expectation")` for expected responses, `posterior_samples()` for prediction intervals. Compute derived quantities (peak, threshold, area) per draw. Fix a `seed` and report `n_draws`; check stability with more draws.

## Theming gratia plots (current API)

Recent gratia deprecates colour/alpha/linewidth arguments of `draw()` (`smooth_col`, `ci_col`, `ci_alpha`, ...) in favour of ggplot2 theme settings:

```r
p <- draw(m)
p & theme(
  geom.gratia.smooth = element_geom(colour = "navy", linewidth = 0.8),
  geom.gratia.interval = element_geom(fill = "navy"),
  gratia.alpha.interval = 0.15
)
old <- gratia_theme_set(theme(gratia.alpha.interval = 0.1))   # package-wide; restore with gratia_theme_set(old)
```

Palettes: `gratia_palette("tol_banded_16")` with `theme(palette.colour.discrete = ..., palette.fill.discrete = ...)`. Verified in 0.11.2-64: the `&` + `theme(geom.gratia.smooth = element_geom(...), geom.gratia.interval = element_geom(...), gratia.alpha.interval = ...)` call and `gratia_theme_set()` work (the first `gratia_theme_set()` call returned `NULL`, meaning no previous theme was set); the old `smooth_col` argument gives a deprecation warning ("deprecated as of gratia 0.11.3"). If the installed gratia is older, these `theme()` elements may not exist; check `?gratia_theme_get`.

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
