# Smooths, families and common pitfalls

## Contents
- Smooth types
- Interactions
- Families
- Common mistakes
- Spatial and temporal notes

## Smooth types

| `bs` | Name | Notes |
|---|---|---|
| `"tp"` | thin plate (default) | good general default, costly for large n; `"ts"` adds shrinkage to zero |
| `"cr"` / `"cs"` | cubic regression | cheaper; `"cs"` shrinks |
| `"cc"` | cyclic cubic | ends must match; supply `knots` for the cycle range |
| `"ps"` / `"cp"` | P-spline / cyclic P-spline | allows different penalty orders |
| `"bs"` | B-spline | flexible penalties, better-behaved extrapolation |
| `"ad"` | adaptive | varying wiggliness; needs plenty of data |
| `"ds"` | Duchon | generalises tprs |
| `"gp"` | Gaussian process | |
| `"sos"` | spline on sphere | lon/lat data |
| `"mrf"` | Markov random field | discrete spatial units; needs neighbour structure |
| `"re"` | random effect | factor, or `s(g, x, bs = "re")` for slopes |
| `"fs"` | factor smooth interaction | group-level smooths with shared smoothing parameter |
| `"sz"` | sum-to-zero factor smooth | models group deviations from a global smooth |

See `?smooth.terms` for the full list and `?choose.k` for basis dimension guidance.

## Interactions

- `s(x, z)`: one isotropic smooth, use only when x and z are on the same scale (e.g. coordinates).
- `te(x, z)`: tensor product, scale invariant. Use `ti(x, z)` for the interaction only, with `s(x) + s(z)` as main effects.
- `s(x, by = f)`: separate smooth per level; add `f` to the model. With an ordered factor `of`, `s(x) + s(x, by = of)` estimates differences from the reference level directly.
- `s(x, by = z)` with numeric `z`: varying-coefficient model; `z` main effect is not identified inside a centred smooth, so include it separately where appropriate.
- Check `summary()` and `draw()` for each term; a `by` smooth with ordered factors drops the reference level.

## New in mgcv 1.9-5: `bs = "bt"` and `options()` defaults

Tested 2026-11-04 on mgcv 1.9-5 with simulated data (`gamSim(2)`, n = 400); help pages `?smooth.construct.bt.smooth.spec` and `?options.mgcv`.

- **`bs = "bt"`**: tensor product of B-spline bases with derivative-based penalties (Wood 2017, Stat Comput 27:985). It is meant for unevenly distributed data: basis functions with no data in their span are dropped, so the basis can be smaller than `k^d` (the help example shows this; in my test the data covered the unit square and nothing was dropped: `k = c(6, 6)` gave 36 coefficients, the default gave 100). Fitted and summarised normally with `gam(..., method = "REML")`; a 1-D `s(x, bs = "bt", k = 8)` also works. Penalty and spline order are set through `m`, and the help page warns that order is specified in an unusual way (`m = 3` is cubic, penalty order `m - 1`); read the `?` page before choosing `m`. Not compared against `te()` here, so do not claim it is better for a given data set; treat it as an option when `te()` or `s(x, z)` struggles with gaps in the covariate space.
- **`options(mgcv.*)` defaults** (`?options.mgcv`; the topic is help-only, not an object): `mgcv.gam.method`, `mgcv.gam.optimizer`, `mgcv.bam.discrete`, `mgcv.s.bs`, `mgcv.te.bs`, `mgcv.te.np`, `mgcv.xt`, `mgcv.ti.mc`, `mgcv.plot.scheme`. Verified: `options(mgcv.gam.method = "REML", mgcv.bam.discrete = TRUE)` made `gam()` report `"REML"` and `bam()` use `"fREML"` with discretisation; after resetting, `gam()` returned to `"GCV"`. `options(mgcv.s.bs = c("cr", "tp"))` changed the default `s(x)` basis to `cr`. Risk: a session-wide option silently changes results for code that omits `method` or `bs`, so for reproducibility still write `method = "REML"` (and `discrete`, `bs`) explicitly in the model call, and report any options set.

## Families

| Data | Family |
|---|---|
| Continuous, symmetric | `gaussian()`, heavy tails: `scat()` |
| Positive, skewed | `Gamma(link = "log")`, `inverse.gaussian`, `lognormal` via `log(y)` plus Gaussian (mind bias on back-transform) |
| Counts | `poisson`, `nb()` (estimated theta), `quasipoisson` if only overdispersion matters |
| Counts with zero mass | `ziP()`, hurdle-style two-model approach, or glmmTMB |
| Non-negative with exact zeros | `tw()` Tweedie |
| Proportions in (0, 1) | `betar()`, `binomial` with weights |
| Binary / successes | `binomial` with `logit` or `cloglog` |
| Ordered categories | `ocat(R = k)` |
| Unordered categories | `multinom(K = k - 1)` (list of formulae) |
| Location-scale | `gaulss()`, `gammals()`, `gumbls()`, `gevlss()`, `shash()`, ... (list of formulae) |

Always follow with a family-appropriate residual check; `gam.check()` for non-Gaussian families uses deviance residuals, which can look odd. Prefer quantile residuals, `gratia::appraise()`, `gratia::rootogram()` or `DHARMa`.

## Common mistakes

- Using GCV (the default) rather than REML.
- Character variables where factors are needed.
- Interpreting `s()` plots as response-scale effects; they are centred partial effects on the link scale.
- Taking an edf near 1 as "linear is fine" without a look at the plot, or an edf near `k'` as "complex relationship" without checking k.
- Increasing `k` to chase a low k-index when the real issue is dependence, a missing covariate or the wrong family.
- Using an isotropic `s(x, z)` with variables on different units.
- Forgetting the factor main effect when using `s(x, by = f)`.
- Predicting from `newdata` with missing variables, or levels not seen in fitting.
- Wald-style confidence intervals on the response scale; instead compute on the link scale and transform.
- Treating `summary()` smooth p-values as exact, or reporting them for terms that are shrunk to ~0 edf as meaningful.
- Using AIC across models fitted by REML with different fixed effects.
- Comparing smooth significance across groups by looking at overlapping pointwise intervals; use `difference_smooths()`.

## Cumulative or power-law outcomes

For an outcome that accumulates from zero (random-walk-like, log link), a time smooth at its edf ceiling (`k-1`) in every fit often signals a covariate-scale problem, not too small a `k`. Reproduced 2026-11-06 (synthetic Gamma(log) cumulative curves, 30 animals x 60 times, mgcv 1.9-5): `s(t, k = 10)` gave edf 8.86 and an RMSE of group means of 0.96, while `s(log(t), k = 10)` gave edf 1.97 and RMSE 0.55. Not reproduced, one project only: raising `k`, `m = 3` penalties, fixed `sp` on raw time and `offset(log(t))` did not help (fixed `sp` raised RMSE 2 to 3 times, so the curvature was real). `s(log(t))` also allowed the global smooth to be forced linear. Overlay raw group means on fitted means before penalising or raising `k`. Dependent observations also make the independence likelihood overstate evidence for curvature, so edf at the ceiling with large n is not necessarily overfitting. The time-scale choice changed some factor contrasts (one changed sign), so report which scale was used.

## Spatial and temporal notes

- Space: for lon/lat over large areas use `bs = "sos"`; for local areas project to metres and use `s(x, y)` or `bs = "ds"`. Gratia has an article on choosing a smooth for the spatial question.
- Space-time: `ti(x, y, time)` plus main smooths, or `te(x, y, time, d = c(2, 1))`.
- Time series: smooths of time are not a substitute for an autocorrelation structure; check residual ACF. A smooth of time absorbs trend but can interact with an AR1 term in `bam(rho = )`.
- Seasonal plus trend: `s(doy, bs = "cc") + s(year)`, optionally `ti(doy, year, bs = c("cc", "tp"))`.
- Neighbourhood cross-validation (NCV) in mgcv can handle dependence in smoothness selection; see Simpson's `naboer` package for building neighbourhoods and `?mgcv::NCV` if available in the installed version.
