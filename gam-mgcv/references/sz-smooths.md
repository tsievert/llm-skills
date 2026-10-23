# Sum-to-zero factor smooths (`bs = "sz"`)

Newer mgcv basis (Simon Wood, with input from Matteo Fasiolo), still thinly documented. This file collects the documented behaviour (mgcv 1.9-4 help pages `?factor.smooth` and `?smooth.construct.sz.smooth.spec`), gratia issue history, and behaviour verified by running code (mgcv 1.9-4, gratia 0.11.2.10, October 2026). Items marked "verified" were observed; anything else is from the docs. Re-check against the installed versions before relying on edge cases.

## Contents
- What it does
- Syntax
- Smoothing parameters and `id`
- Rules and traps
- sz vs by, ordered-by, fs
- Checking and plotting
- Group-specific curves and differences between levels
- gratia support and known issues
- Large data and other fitters
- Worked example

## What it does

`s(fac, x, bs = "sz")` makes one smooth of `x` per factor level, constrained so that the level smooths represent deviations from a main-effect smooth: for each spline coefficient the sum across levels is zero. This makes the model

$$g(\mu_i) = f(x_i) + f_{k(i)}(x_i)$$

identifiable, with `f` the global (reference) smooth and `f_k` the level-specific deviation. The help pages call this often more natural than the ordered-factor `by` construction.

Multiple factors are allowed; a smooth is produced for each combination of levels, excluding main effects and lower-order interactions. The smooth covariate can be 1D (documented plotting in mgcv is 1D only), and the basis is chosen with `xt = list(bs = "cr")` (default `"tp"`).

## Syntax

```r
# one factor: global smooth + level deviations
y ~ s(x) + s(fac, x, bs = "sz")

# one shared smoothing parameter for all level deviations
y ~ s(x) + s(fac, x, bs = "sz", id = 1)

# different underlying basis
y ~ s(x, bs = "cr") + s(fac, x, bs = "sz", xt = list(bs = "cr"), k = 8)

# two factors: main-effect deviations plus their interaction
y ~ s(x) + s(f1, x, bs = "sz") + s(f2, x, bs = "sz") + s(f1, f2, x, bs = "sz", id = 1)
```

- Put the factor(s) first, then the continuous covariate, as in the docs. Verified: `s(x, fac, bs = "sz")` also fits and gives near-identical smoothing parameters, and gratia since issue #208 accepts any order and several factors, but stick to the documented order.
- Always include the global `s(x)`. Without it the level smooths contain no shared component and the sum-to-zero constraint forces a sum of deviations, not level curves.
- The `s(x)` main smooth must use compatible basis and `k` choices with the deviation term; set `k` on both deliberately.

## Smoothing parameters and `id`

- Default: **one smoothing parameter per level smooth** (verified: with a 3-level factor the model had `s(fac,x2)1`, `s(fac,x2)2`, `s(fac,x2)3` in `m$sp`). Analogous to a `by` smooth: each level gets its own wiggliness, so levels with little data can be poorly estimated, and a level can be shrunk to nearly linear/flat independently.
- `id = 1` (any shared id) forces a single smoothing parameter across levels (verified: one entry `s(fac,x2)`). Prefer this when levels have comparable data and similar expected wiggliness, when there are many levels, or when you want hierarchical-style shrinkage of deviations. This is the `sz` analogue of `bs = "fs"` behaviour.
- Use the same `id` on several `sz` terms only if you want them to share one parameter; it is a modelling choice, not a default.

## Rules and traps

1. **Factor must be a `factor`, not character.** Verified: a character grouping variable fails with the obscure error `'names' attribute [2] must be the same length as the vector [1]`. Convert with `factor()` first. This error text does not mention factors.
2. **Do not add the factor as a parametric main effect.** Per the help, the level smooths are not individually centred and already contain the factor main effects, so adding `fac` or factor interactions makes the model rank deficient. Verified: adding `+ fac` returned zero coefficients for the extra dummy terms (aliased). Group intercept differences are therefore part of the `sz` term, and the `draw()` of the term shows deviations that include level means.
3. **Do not use `s(x, by = fac)` and an `sz` term for the same covariate/factor.**
4. **`k.check()`/`gam.check()` give no k-index for the sz term** (verified: `NA` for k-index and p-value; `k'` is reported, edf given). Judge adequacy of `k` by the edf relative to `k'`, residuals against the covariate by level, sensitivity to a larger `k`, and by comparing with an equivalent `by` fit if needed. Do not report a clean k-index for the term.
5. **New levels in `predict()`:** an unseen factor level yields `NA` with a warning (verified: "factor levels ... not in original fit"). Levels cannot be extrapolated, unlike `bs = "re"`/`fs` with `exclude`.
6. **Interpretation:** the plotted `sz` term is the deviation from the main smooth, not a level-specific curve. The level curve is the intercept plus `s(x)` plus the level's deviation (plus other terms). See below.
7. Sparse levels: a level with few observations across the range of `x` still gets a smooth; with a separate smoothing parameter it can overfit. Use `id`, lower `k`, or `select = TRUE` / `bs = "ts"` style shrinkage via `xt = list(bs = "ts")` (untested; check the fit).
8. With several factors, interpret terms in order: main-effect deviations first, then interaction deviations. Check concurvity.
9. `gam.check()` residual panels work; the non-Gaussian caveats from the main skill still apply.

## sz vs by, ordered-by, fs

| Approach | Main smooth | Level terms | Smoothing parameters | Notes |
|---|---|---|---|---|
| `s(x, by = fac)` + `fac` | none | each level's full curve (centred) | one per level, or `id` | no shared component; needs parametric `fac` |
| `ofac + s(x) + s(x, by = ofac)` | reference level's curve | differences to reference level | per difference smooth | results depend on the reference level; reference has no deviation term |
| `s(x) + s(fac, x, bs = "sz")` | average across levels | deviations from average, sum to zero | per level, or `id` | symmetric treatment of levels; no reference level to choose |
| `s(x) + s(x, fac, bs = "fs")` | shared | fully random curves, one smoothing parameter | one | the main effect is not forced to carry as much as possible (doc statement); `fs` is efficient with `gamm` |
| `t2(x, fac, bs = c("tp", "re"), full = TRUE)` | | | | mgcv docs say this is exactly equivalent to `fs`, but slower |

Practical guidance:
- Use `sz` when comparing all levels symmetrically and when the factor is treated as fixed or has a moderate number of levels. Use `fs` for many levels treated as random draws and when a single smoothing parameter is wanted by design (also `gamm`).
- With few levels, `sz` and an ordered-`by` model fit very similarly; in a simulated check the AICs were within a few units (2117 vs 2113). The choice is about interpretation.
- `sz` with `id` is the closest to a "global smooth plus group deviations that share wiggliness" model (HGAM model GS in `hgam-and-random-effects.md`). `bs = "sz"` is an option for the group-level term there.

## Checking and plotting

- `gratia::draw(m)` works for `sz` terms; level deviations overlay in one panel with a colour per level (verified). With more than about three levels the panel gets crowded (gratia issue #244). Facet by hand using `smooth_estimates()` output:

```r
sm <- smooth_estimates(m, select = "s(fac,x2)") |> add_confint()
ggplot(sm, aes(x2, .estimate, ymin = .lower_ci, ymax = .upper_ci)) +
  geom_ribbon(alpha = 0.2) + geom_line() + facet_wrap(~ fac)
```

- `mgcv::plot(m, pages = 1)` also works; `scheme = 1` gives black and white (1D smooths only).
- `appraise(m)` and `gam.check(m)` work for the model as a whole.
- Concurvity: check `concurvity(m, full = FALSE)`; the main `s(x)` and the deviations can share structure when levels are similar.

## Group-specific curves and differences between levels

**Level curves.** Use whole-model predictions, not the term alone:

```r
grid <- data_slice(m, x2 = evenly(x2, 100), fac = all_levels(fac))
fv <- fitted_values(m, data = grid)       # link or response scale; check ?fitted_values
# or: predict(m, grid, se.fit = TRUE) and back-transform on the link scale
```

Hold other covariates at typical values (`data_slice` does this) and exclude random effects as needed.

**Pairwise differences between levels.** `difference_smooths()` **fails on an `sz` term** (`subscript out of bounds`; verified in gratia 0.11.2.10 and again in 0.11.2-64), and its documentation describes factor-`by` smooths only. `gratia::conditional_differences()` (whole-model contrasts; absent in 0.11.2.10, present in 0.11.2-64) **works on `sz` models**: with `by = "fac"`, `condition = "x2"` it returned all pairwise contrasts, and on the link scale with `uncertainty = "delta"` its estimates and standard errors matched the linear-combination helper below to about 1e-15 (verified on one simulated model). Use it when installed (`exists("conditional_differences", asNamespace("gratia"))`); otherwise use the explicit linear-combination approach below.

For `sz`, the level-a minus level-b difference equals the difference of the two deviation smooths (the main smooth cancels). This helper computes it with pointwise and simultaneous intervals (verified to reproduce differences of `smooth_estimates()` to machine precision):

```r
sz_difference <- function(model, newdata1, newdata2, term, n_sim = 10000, level = 0.95) {
  sm <- Filter(function(s) s$label == term, model$smooth)[[1]]
  cols <- sm$first.para:sm$last.para
  D <- (predict(model, newdata1, type = "lpmatrix") -
          predict(model, newdata2, type = "lpmatrix"))[, cols, drop = FALSE]
  V <- vcov(model, unconditional = TRUE)[cols, cols]
  est <- drop(D %*% coef(model)[cols])
  se <- sqrt(rowSums((D %*% V) * D))
  sims <- mgcv::rmvn(n_sim, rep(0, length(cols)), V)
  crit <- quantile(apply(abs(sims %*% t(D)) / rep(se, each = n_sim), 1, max), level)
  cbind(newdata1, diff = est, se = se,
        lower = est - crit * se, upper = est + crit * se)   # simultaneous band
}

grid <- data_slice(m, x2 = evenly(x2, 100))
nd1 <- transform(grid, fac = factor("1", levels = levels(dat$fac)))
nd2 <- transform(grid, fac = factor("2", levels = levels(dat$fac)))
sz_difference(m, nd1, nd2, "s(fac,x2)")
```

Notes: this compares the smooth-shape part only. If the model also has other terms that differ by level (for example interactions of the factor with other smooths), include those columns (drop the `cols` restriction) to get the whole-model difference. Use `set.seed()` before calling for reproducible bands. For the difference in expected response, compute on the link scale and transform, or use `gratia::conditional_differences()` where available.

**Derivatives.** `gratia::derivatives(m, select = "s(fac,x2)")` ran in 0.11.2.10 (verified; it returned a tibble). Issue #362 had reported failures on `s(Year, Site, bs = "sz")` (closed); re-check on your version for multi-factor terms.

**Posterior sampling.** `gratia::smooth_samples(m, select = "s(fac,x2)", n_draws = ..., seed = ...)` ran (verified, 0.11.2.10). Remember the sampling-argument renames in newer gratia (`n_draws`, see the gratia sampling-migration article).

## gratia support and known issues

Search these before assuming a limitation. Issues in https://github.com/gavinsimpson/gratia (state as returned by the GitHub search API, October 2026):

| # | Topic | State |
|---|---|---|
| 202 | handle the new `sz` smooths in `smooth_estimates()` and `draw()` | closed |
| 208 | `sz` smooths with n factors and any term order | closed |
| 244 | plot `sz` deviations in separate panels | closed |
| 249 | `draw()` fails for 2D smooths with `bs = "sz"` or `"fs"` | closed |
| 356 | `partial_derivatives()`: `select`/`focal` and the fact that `sz` is treated as one smooth, not one per level | closed |
| 362 | `derivatives()` on `s(Year, Site, bs = "sz")` | closed |

Search again for newer ones: `https://github.com/gavinsimpson/gratia/issues?q=sz` or the API `https://api.github.com/search/issues?q=repo:gavinsimpson/gratia+sz`. With the GitHub CLI: `gh search issues "sz" --repo gavinsimpson/gratia`.

Also look at: the gratia changelog, the "Comparing treatments and finding rates of change" and "Read smooth effects, interactions and surfaces" articles, the gratia reference page for `difference_smooths()` and `conditional_differences()`, and Gavin Simpson's blog and course repos (`physalia-gam-course`, `au-viborg-gam-course`) for worked `sz` examples. At the time of writing, none of the pages checked (the gratia prediction-comparison article, the `difference_smooths()` reference page, the course README) mentioned `sz` explicitly.

## Large data and other fitters

- `bam(..., method = "fREML", discrete = TRUE)` handles `sz` (the mgcv help example uses it with 25 levels). Verified: a 3-level fit had a deviance equal to the `gam()` fit to 5 digits.
- `gamm()`/`gamm4()`: not tested. The mgcv docs recommend `bs = "fs"` for `gamm` efficiency (nested estimation in `lme`).
- `glmmTMB` and `brms`: not tested with `sz`; assume unsupported until checked in the package docs.

## Worked example

```r
library(mgcv); library(gratia)
dat <- gamSim(4, n = 500, verbose = FALSE)         # factor `fac` with 3 levels, covariates x0, x2
m <- gam(y ~ s(x2) + s(fac, x2, bs = "sz") + s(x0), data = dat, method = "REML")
m$sp                                               # one smoothing parameter per level
m_id <- update(m, . ~ s(x2) + s(fac, x2, bs = "sz", id = 1) + s(x0))
AIC(m, m_id)                                       # shared vs separate wiggliness
draw(m); appraise(m)
k.check(m)                                         # NA k-index for the sz term
```

State in reports: the basis (`sz`), whether `id` was used (shared vs separate smoothing), `k` for both `s(x)` and the deviation term, that deviation smooths sum to zero across levels, and that the level comparison is of whole curves via the linear-combination or `conditional_differences()` approach.
