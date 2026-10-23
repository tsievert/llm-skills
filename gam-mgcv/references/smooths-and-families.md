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

## Spatial and temporal notes

- Space: for lon/lat over large areas use `bs = "sos"`; for local areas project to metres and use `s(x, y)` or `bs = "ds"`. Gratia has an article on choosing a smooth for the spatial question.
- Space-time: `ti(x, y, time)` plus main smooths, or `te(x, y, time, d = c(2, 1))`.
- Time series: smooths of time are not a substitute for an autocorrelation structure; check residual ACF. A smooth of time absorbs trend but can interact with an AR1 term in `bam(rho = )`.
- Seasonal plus trend: `s(doy, bs = "cc") + s(year)`, optionally `ti(doy, year, bs = c("cc", "tp"))`.
- Neighbourhood cross-validation (NCV) in mgcv can handle dependence in smoothness selection; see Simpson's `naboer` package for building neighbourhoods and `?mgcv::NCV` if available in the installed version.
