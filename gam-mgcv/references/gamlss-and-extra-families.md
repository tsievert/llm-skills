# Beyond mgcv families: gamlss2 and inlaws

Load this when the response distribution needs covariate-dependent scale or shape that mgcv's own families do not offer (for example a negative binomial with seasonal dispersion), or a family mgcv lacks (ordered beta, zero-inflated negative binomial, Conway-Maxwell-Poisson, generalized Pareto). Check mgcv's own list first (`?family.mgcv`: `gaulss()`, `gammals()`, `gumbls()`, `gevlss()`, `shash()`, `ziplss()`, `twlss()`, ...).

Both packages below are **not on CRAN** (checked 2026-10-28). Installing them needs the user's explicit permission (project rule for non-CRAN sources). Tested 2026-10-28 with R 4.6.0, mgcv 1.9.4, gratia 0.11.2.64, gamlss2 0.1-0, topmodels 0.3-0, inlaws 0.0.0.9000. Research notes: `research/gam-distributional-and-extra-families-ledger.md` in the llm-skills repo.

## gamlss2 (GAMLSS, authors Stasinopoulos, Rigby, Zeileis, Umlauf and others)

Fresh reimplementation of the `gamlss` framework: every parameter of the response distribution gets its own additive predictor, mgcv smooth terms (`s(x, bs = "cc")`, ...) work directly, and families come from `gamlss.dist`. Documentation: https://gamlss-dev.github.io/gamlss2/ . Background: Merder, Rigby, Stasinopoulos et al. (2026), Nat Rev Methods Primers 6:49 (only the abstract has been read, not the guidelines).

```r
install.packages(c("gamlss2", "gamlss.dist"),
                 repos = c("https://gamlss-dev.R-universe.dev", "https://cloud.R-project.org"))
install.packages("topmodels", repos = c("https://zeileis.R-universe.dev", "https://cloud.R-project.org"))
install.packages("gamlss")   # CRAN; gamlss2 0.1-0 failed at fit time without it

library(gamlss2)
m <- gamlss2(bikes ~ s(yday, bs = "cc", k = 20) | .,   # mu | sigma; "." reuses the mu predictor
             data = d, family = NBI, trace = FALSE)
predict(m, newdata = nd, type = "parameter")             # data frame of mu, sigma (NBI: sigma = 1/theta of mgcv nb())
predict(m, newdata = nd)                                 # distributions3 object: cdf(), quantile(), ...
```

- Formula: right-hand sides separated by `|` map to family parameters in displayed order. `y ~ x` gives `mu` a predictor and the rest intercepts; `y ~ x | z`; `y ~ x | .`.
- `predict()`: pass `newdata =` by name. `predict(m, nd)` fails with `invalid subscript type 'list'`.
- Diagnostics: normalized randomized quantile residuals (`set.seed()` first for discrete responses), `plot(m, which = "resid")`, and from topmodels `rootogram()`, `pithist()`, `qqrplot()`, `wormplot()`, `procast()`, `proscore()` (smaller is better; compare within a score). Loading gratia after topmodels masks `rootogram`; call `topmodels::rootogram()`.
- The authors' own cautions, worth repeating when reporting: these diagnostics are in-sample and do not show out-of-sample or subgroup calibration; central response quantile bands describe response variation, not uncertainty of the mean; do not exponentiate a fitted log-mean to get the mean (quantiles do transform); training scores favour flexible models, so score held-out data (time-ordered for forecasting).
- Bayesian version: `bamlss2()` and `mcmc()`; credible intervals from `predict()` are pointwise and not prediction intervals; check trace and autocorrelation plots.
- `AIC()`/`BIC()` work, but mgcv and gamlss2 count effective degrees of freedom differently, so compare roughly across packages and prefer held-out scores.
- Random effects, two routes (`?random`): `s(g, bs = "re")` (mgcv, simple random intercept or slope, fitted inside the backfitting) and `re(~ 1 | g)` / `re(~ xc | g)` (nlme `lme()` specials, so needs `nlme`, covers correlated slopes and `correlation =`; transform variables beforehand, `I()` is not supported). Tested 2026-10-28 on simulated overdispersed counts (25 groups x 40): `s(x, by = f) + f + s(g, bs = "re")` fitted with `NBI` and matched the same mgcv `nb()` model (AIC 5272.1 vs 5273.3, predictions within 0.3%, random-intercept sd 0.466 from `1/sqrt(lambda)` vs mgcv 0.481, simulated 0.474); `re(~1|g)` gave similar fits (predictions within 4%). Random effects in a second parameter (`| s(g, bs = "re")`), `by = f` smooths in sigma, `bs = "fs"` and `bs = "sz"` all fitted without error (accuracy of those not checked); a sigma random effect absent from the simulation shrank to edf 0.
- Random-effect extraction: `fit$fitted.specials$mu[["s(g)"]]` holds `coefficients`, `lambdas`, `edf`, `vcov`. `summary()` does not print a random-effect sd.
- Prediction with random effects: a new factor level errors (`factor g has new level ...`), unlike mgcv. Population-level prediction: `predict(m, newdata = nd, parameter = "mu", type = "terms")`, then sum the columns except `s(g)` (matched mgcv `exclude = "s(g)"` up to a constant shift of 0.03 on the link scale, centring differences), supplying an existing level in `nd`. Wald intervals: `predict(..., parameter = "mu", type = "link", se.fit = TRUE, interval = "wald")`; the argument is `parameter =`, not `model =` (that gave NaN, no error).
- Correlated random slopes need `re(~ xc | g)`; two `s(g, bs = "re") + s(g, xc, bs = "re")` terms give independent intercept and slope. Tested 2026-10-28 on simulated overdispersed counts (40 groups x 30; simulated sd 0.5 and 0.8, correlation 0.6, realised 0.63) against `glmmTMB(y ~ xc + (1 + xc | g), family = nbinom2)`: `re(~ xc | g)` gave sd 0.545 and 0.888 with correlation 0.647 (glmmTMB 0.545, 0.917, 0.671); intercept and slope BLUPs correlated 0.999 and 0.994 with glmmTMB's; link-scale predictions correlated 0.998 (median absolute difference 0.02, maximum 0.26); fixed effects 1.644 and 0.752 vs 1.642 and 0.717; NB size 3.86 vs 3.51. The mgcv independent-slope model gave sd 0.559 and 0.935. With only 8 of those groups, gamlss2 gave slope sd 1.36 and glmmTMB 1.45 (both far above the simulated 0.8, so few groups overestimate slopes in both).
- Read the variance components from the nlme fit: `nlme::VarCorr(fit$fitted.specials$mu[[1]]$model)`; BLUPs are `fit$fitted.specials$mu[[1]]$coefficients` (a `ranef.lme` data frame). The reported "Residual" sd is that of the working response of the backfitting, not a count-scale quantity.
- `re()` with a random slope reports edf = number of random-effect coefficients (80 for 40 groups x 2; 50 for 25 groups x 2), so its AIC is charged the full count. AIC also differs in kind from glmmTMB's marginal-likelihood AIC (6419 vs 6341 for the same model here), and from the mgcv `s(bs = "re")` fits; do not compare AICs across these without saying so.
- `re(~ xc | g, correlation = corAR1(form = ~ t | g))` is accepted and passed to `lme()` (phi estimated about 0 where none was simulated), but the correlation structure acts on the working response of the backfitting, not on the counts, so do not interpret it as autocorrelation of the NB response. For real temporal or spatial dependence prefer a smooth of time, `bam(rho = )` in mgcv, or glmmTMB covariance structures. Not tested with simulated autocorrelation.
- A new group level in `newdata` errors for `re()` terms too.
- Other specials in 0.1-0: `lo()`, `tree()`, `ct()`, `cf()`, `n()`, `lin()`/`ridge()`, `gnet()`, `la()`; custom ones via `special_fit()`/`special_predict()` methods (`?special_terms`). Family extensions: `truncate_family()`, `censor_family()`, `round_family()`, `inflate_family()`, `hurdle_family()`; custom families need `family`, `names`, `links`, `pdf()` in a `gamlss2.family` list; `family(distributions3_dist, links = ...)` bridges a distributions3 distribution.
- Not tested: other families, `re()` with several grouping levels or `correlation =` under real autocorrelation, gratia plotting of gamlss2 fits (gratia does not support them), `bamlss2()`, the extension and special-term constructors above beyond what is quoted from the documentation.

## inlaws (experimental extra families for mgcv)

https://github.com/gam-mafia/inlaws (unrelated to R-INLA). Install needs permission: `remotes::install_github("gam-mafia/inlaws", upgrade = "never")`. The README calls it highly experimental and largely untested. It names no authors; MIGRATION.md says the families were extracted from `mgcvUtils` (MIT source, David L Miller), and local paths suggest Gavin Simpson did the migration (inferred, not confirmed). Treat it as a gap-filler to validate, never a default.

```r
library(mgcv); library(inlaws)
m <- gam(list(bikes ~ s(yday, bs = "cc", k = 20),   # mean
              ~ s(yday, bs = "cc", k = 20)),         # theta (size)
         data = d, family = nbls(), method = "REML", knots = list(yday = c(0, 365)))
predict(m, nd, type = "response")                    # unnamed matrix: column 1 = mu, column 2 = theta
```

- Families include `nbls()`, `zinb()`/`zanb()`, `cmp()`/`cmpls()`, `gpoisson()`, `pig()`, `betals()`, `ordbeta()`, `zoibetals()`, `scatlss()`, `gpd()`, `dirichlet()`, `cumulative_link()`; see the README table and each family's help.
- `bam()` works only for `cgamma`, `clognormal`, `cmp`, `gpoisson`, `pig`, `log_logistic`, `cumulative_link`. `bam()` with `nbls()` errors ("general families not supported by bam").
- General families (location-scale, zero-inflated) are `gam()` REML only: ML is silently converted to REML and NCV can silently revert to REML with a warning, so check `fit$method`. No inlaws family works with `gamm()`.
- Needs mgcv >= 1.9-3 (1.9-4 for discrete NCV). Use `scale = 1` for absolute likelihood comparison with the four extended families.
- `gratia::appraise()` and `gratia::quantile_residuals()` ran on an `nbls` fit (functions run; residual quality not judged). `zoibetals()` deviance residuals are undefined; use response, Pearson or quantile residuals. Censored families need `censoring_process()` for simulated reference lines.

## Worked comparison (HarzTraffic motorcycle counts, n = 1057, 21% zeros, overdispersed)

`s(yday, bs = "cc", k = 20)` for the mean.

| Model | AIC | BIC |
|---|---|---|
| mgcv `nb()` (constant theta) | 10498.7 | 10588.5 |
| inlaws `nbls()` (smooth theta) | 10155.9 | 10273.5 |
| gamlss2 `NBI`, constant sigma | 10501.4 | 10583.2 |
| gamlss2 `NBI`, smooth sigma | 10155.8 | 10262.6 |

Both location-scale fits agree closely (dispersion curves correlate at 1.00, mean curves differ by a median of 0.7% and at most 19.5% where the mean is below 1). A single chronological hold-out gave log scores of -1713.0 (`nb()`), -1645.5 (`nbls()`) and -1644.8 (gamlss2). One dataset and one split, so this shows the packages run and agree, not that they are generally reliable.

## Which to use

mgcv's own families first (best documented, `bam()`, gratia support). `inlaws` when the family exists only there and you can validate it (against brms, glmmTMB or gamlss2). `gamlss2` when several distribution parameters need predictors, or when you want its scoring and calibration tools. Say which package was used and its version in the report.
