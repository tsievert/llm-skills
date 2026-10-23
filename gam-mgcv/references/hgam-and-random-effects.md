# Hierarchical GAMs and random effects

## Contents
- HGAM model types
- Random intercepts and slopes
- Ordered factor differences
- Choosing between mgcv, gamm4, glmmTMB and brms
- Practical tips

Source: Pedersen et al. (2019), PeerJ 7:e6876, https://peerj.com/articles/6876/ . Gavin Simpson also has a blog post on random effects in GAMs with mgcv (https://fromthebottomoftheheap.net/2021/02/02/random-effects-in-gams/). Verify syntax against the paper or the post when it matters.

## HGAM model types

With response `y`, covariate `x`, grouping factor `g` (a factor):

| Model | Idea | Formula sketch |
|---|---|---|
| G | one global smooth, no group differences | `y ~ s(x) + s(g, bs = "re")` |
| GS | global smooth plus group smooths sharing one smoothing parameter | `y ~ s(x, k = k1) + s(x, g, bs = "fs", k = k2)` |
| GI | global smooth plus group smooths with their own smoothing parameters | `y ~ s(x) + s(x, by = g, m = 1) + s(g, bs = "re")` |
| S | group smooths with shared smoothing parameter, no global smooth | `y ~ s(x, g, bs = "fs")` |
| I | group smooths with separate smoothing parameters, no global smooth | `y ~ g + s(x, by = g)` |

Notes:
- `m = 1` (first-derivative penalty) in the group-level smooth of GI reduces confounding with the global smooth.
- In model GS the group deviations shrink toward the global smooth; with `bs = "sz"` the group smooths are sum-to-zero deviations from it, which can make interpretation cleaner.
- Models with both global and group smooths can have estimation issues (concurvity); check it.
- Use `method = "REML"`. Use `bs = "cc"` for cyclic covariates.

## Random intercepts and slopes

```r
s(g, bs = "re")              # random intercept
s(g, x, bs = "re")           # random slope (uncorrelated with intercept)
s(g1, g2, bs = "re")         # interaction random effect
```

- `bs = "re"` does not estimate intercept-slope correlation. Use `gamm4`, `glmmTMB` or `brms` if that is required, or consider `s(x, g, bs = "fs")`.
- The grouping variable must be a factor; unseen levels in prediction need `exclude` or new data with an existing level and the term excluded.
- Crossed random effects work: add several `s(., bs = "re")` terms. For large numbers of levels, `bam(discrete = TRUE)` is much faster.

## Ordered factor differences

For direct tests of group difference from a reference level:

```r
df$of <- ordered(df$f)
m <- gam(y ~ of + s(x) + s(x, by = of), data = df, method = "REML")
```

The `by = of` smooths are differences from the reference smooth. For all pairwise comparisons, use unordered factor-by smooths and `gratia::difference_smooths()`.

## Choosing between mgcv, gamm4, glmmTMB and brms

| Need | Tool |
|---|---|
| Standard GAM with random effects, REML | `mgcv::gam()` / `bam()` |
| Correlated random slopes, lme4-style formulas | `gamm4::gamm4()` |
| AR(1) or other `nlme` correlation, heteroscedasticity | `mgcv::gamm()` or `bam(rho = )` |
| Zero inflation, many families, TMB speed, smooths in a mixed model | `glmmTMB` with `s()` (gratia has `draw()`/`smooth_estimates()` methods) |
| Spatial models using SPDE | `sdmTMB` (gratia has methods) |
| Full Bayesian inference, priors | `brms` with `s()` / `t2()` |

`gamm()` and `gamm4()` return a list with `$gam` and `$mer`/`$lme`; check and plot `$gam`, and inspect the mixed-model component separately.

## Practical tips

- Start simple (model G or GS), add complexity only when diagnostics or the question call for it.
- Few levels per group (< 5) or few observations per group: random effects and factor smooths are poorly estimated; treat the group as fixed.
- Report between-group variability using `gratia::variance_comp()`.
- For prediction at a new level of the grouping factor, simulate group-level effects with `gratia::random_effect_samples()` rather than setting the effect to zero if you want population-level uncertainty.
