# gam-mgcv / gam-interpretation: GAMLSS, gamlss2, inlaws research ledger

## Requirements

| # | Requirement | Date |
|---|---|---|
| 1 | Research gamlss2 site and the Nature Reviews Methods Primers GAMLSS article for the GAM skills; treat their authors (Stasinopoulos, Rigby, Zeileis, Umlauf, Kneib, Mayr, Heller, De Bastiani, Stauffer, Merder, Logothetis) as authoritative on GAM-related topics | 2026-10-28 |
| 2 | Investigate https://github.com/gam-mafia/inlaws as a potential resource | 2026-10-28 |

## Sources

| Source | Status | Note |
|---|---|---|
| https://gamlss-dev.github.io/gamlss2/ (index) | read | |
| gamlss2 vignettes: firststeps, topmodels, bayesian | read | |
| gamlss2 vignettes: prediction (.html and .qmd) | blocked | both 404 via fetch; linked from site nav as `prediction.qmd` |
| gamlss2 vignettes: families, family_extensions, specials | not researched | |
| gamlss2 NEWS | read | only "0.1-0", fresh reimplementation of gamlss |
| https://www.nature.com/articles/s43586-026-00498-z | blocked | bot wall ("Client Challenge") for both normal and raw fetch; only abstract/metadata via search |
| Nature article metadata (search) | read | see facts |
| https://github.com/gam-mafia/inlaws (README, raw README) | read | |
| https://gam-mafia.github.io/inlaws/articles/family-compatibility.html | read | |
| https://raw.githubusercontent.com/gam-mafia/inlaws/main/MIGRATION.md | read | provenance (from the parallel research round, merged 2026-10-28) |
| gam-mafia org page, inlaws NEWS/DESCRIPTION/inst/validation, AGENTS.md | not researched | authors not named on the pages read |
| gamlss2 CITATION | not researched | |
| Stasinopoulos and Rigby slides (gamlss.com visualTools.pdf, Model-Selection.pdf) | search | hits only, not read; model cycle and GAIC-based selection |
| topmodels (R-Forge/Zeileis R-universe) docs | partial | only via the gamlss2 vignette |
| gamlss2 CRAN/R-universe status | partial | CRAN page 404; `available.packages()` (cran.rstudio.com) lists gamlss, gamlss.dist 6.1-11, bamlss 1.2-5, distributions3 0.3.0, but NOT gamlss2, topmodels, inlaws |

## Facts

### Nature Reviews Methods Primers (https://www.nature.com/articles/s43586-026-00498-z)

- "Distributional regression using generalized additive models for location, scale and shape", Nat Rev Methods Primers 6, article 49 (2026), published 9 Jul 2026. First author Julian Merder, with Robert A. Rigby, Dimitrios M. (Mikis) Stasinopoulos; the first author's own post lists further co-authors Andreas Mayr, Gillian Heller, Thomas Kneib, Nikolaus Umlauf, Fernanda De Bastiani, Reto Stauffer, Nikos Logothetis, Achim Zeileis.
- Search snippets of the parallel round also listed "Tonkin" among authors (list was truncated; unverified, and not in the author list above). Rigby and Stasinopoulos created GAMLSS; Umlauf, Stauffer, Kneib and Zeileis are behind gamlss2, topmodels and bamlss (the latter attribution is from memory of the packages, not checked on a page).
- Abstract-level content only: GAMLSS extends LM/GLM/GAM by modelling mean, variance, skewness and tail behaviour as functions of covariates; the Primer covers theory, practical implementation guidelines, model checking, case studies, and future directions with machine learning. Body text (the actual guidelines) was NOT read.
- Open: obtain full text (user could paste it, or a preprint/open-access PDF) before writing any rules from it.

### gamlss2 (https://gamlss-dev.github.io/gamlss2/)

- Fresh, more modular reimplementation of `gamlss`; faster; supports all `mgcv` smooth terms directly (`s()`, `bs = "cc"`, etc.); more than four distribution parameters; other estimators (boosting, Bayesian, trees/forests) pluggable; custom families and "special" terms (e.g. neural nets).
- Install: development version from R-universe (`repos = c("https://gamlss-dev.R-universe.dev", "https://cloud.R-project.org")`). Not on CRAN per this machine's `available.packages()` (2026-10-28). GPL-2/3. Installing from R-universe needs explicit user permission under the project rules.
- Formula syntax: right-hand sides separated by `|` map to family parameters in displayed order. `y ~ x` models mu only (rest intercept-only); `y ~ x | z` models mu and sigma; `y ~ x | .` reuses the first predictor for all parameters. Default optimiser `RS()`.
- Families come from `gamlss.dist` (e.g. `NBI`, `SN2`); `predict()` returns `distributions3` objects by default, `type = "parameter"` gives raw parameters; probabilities via `cdf()`, quantiles via `quantile()`.
- Diagnostics: normalized randomized quantile residuals (set a seed for discrete families); `plot(m, which = "resid")`. Via `topmodels`: `rootogram()`, `pithist()`, `qqrplot()`, `wormplot()`, `procast()`; scoring via `proscore()` (logs, crps, mae, mse, dss; smaller is better, compare within a score).
- Authors' own caveats worth copying: diagnostics are in-sample and do not show out-of-sample or subgroup calibration; response quantile bands are NOT confidence intervals for the mean/median; exponentiating a fitted mean log value does not give the mean count (quantiles do transform); training scores favour flexible models, so use held-out (time-ordered for forecasting) scoring.
- Bayesian: `bamlss2()` (MCMC from scratch) and `mcmc()` (from a gamlss2 fit), BAMLSS framework (Umlauf et al. 2018). Intervals from `predict()` are pointwise for distribution parameters, not simultaneous and not prediction intervals; check trace/autocorrelation plots; example iteration counts are not a convergence rule.
- Mapping to current skills: gam-mgcv already lists mgcv location-scale families (`gaulss()`, `gammals()`) and brms; there is no mention of GAMLSS/gamlss2/`bamlss`. Natural fit: a short "when the response distribution needs covariate-dependent scale/shape beyond mgcv's families" section pointing to gamlss2 (R-universe, flagged non-CRAN), with mgcv `gaulss()`/`gammals()`/`twlss()`/`gevlss()`/`shash()`/`gumbls()` (check `?family.mgcv`) first.

### inlaws (https://github.com/gam-mafia/inlaws)

- R package adding extra families to `mgcv::gam()`/`bam()` (not related to R-INLA despite the name). Lifecycle: experimental; README says "highly experimental and largely untested", results may be incorrect, validate independently. Version 0.0.0.9000 per the check command. Authors/license type not stated on the pages read (a LICENSE file exists); provenance in `MIGRATION.md` (not read).
- Families (README table): betals, betabinomial, cgamma/cgammals, log_logistic(ls), gen_gammalss, scatlss (Student-t location/scale/df), cgen_gammalss, clognormal(ls), cmp/cmpls (Conway-Maxwell-Poisson), hyper_poissonls, cumulative_link, dirichlet, dirmult, gpoisson, pig/pigls, nbls, ordbeta, zoibetals, zinb/zanb, gpd.
- Usage: multi-formula lists in `gam()`, e.g. `gam(list(y ~ s(x, k = 6), ~ 1), family = nbls(), method = "REML")`. Requires mgcv >= 1.9-3; discrete `bam()` NCV needs >= 1.9-4. Local mgcv is 1.9.4.
- `bam()` support only for cgamma, clognormal, cmp, gpoisson, pig, log_logistic, cumulative_link (compatibility vignette); other families `gam()` only. Use `scale = 1` for absolute likelihood comparisons with the four extended families (mgcv 1.9-4 can mislabel a fixed external scale).
- Each family ships a `gratia_diagnostics()` callback; `zoibetals()` deviance diagnostics undefined (use response, Pearson or quantile residuals); censored families need `censoring_process()` for simulated QQ references. `ordbeta()` predict returns 5 columns (mu, p0, pI, p1, mean).
- Install instructions: none on the pages read. Not on CRAN (not in `available.packages()`). GitHub install requires user permission; not installed, not tested.
- Provenance (MIGRATION.md, read in the parallel round): extracted from `mgcvUtils` branches (source licence MIT, David L Miller, 2020); local paths suggest the migration was done by Gavin Simpson (gratia author) using codex worktrees. The README itself names no authors, so treat authorship as inferred, not confirmed. 0 stars, 37 commits at the time.
- Division of labour: simulation/quantile/CDF fixers live in gratia (`fix_family_rd/qf/cdf`); inlaws only supplies families and callbacks.
- Fitting-method caveat (compatibility vignette): "general" families (location-scale, zero-inflated, multi-predictor) are `gam()` REML only. ML is silently converted to REML, and NCV silently reverts to REML with a warning when a family has no NCV callback, so check `fit$method`. No family works with `gamm()`. mgcv 1.9-4 has bugs with `nei` plus omitted rows; remove incomplete rows first.
- Assessment: potentially useful gap-filler for ordinal-beta/zero-one-inflated beta, zero-inflated NB, Conway-Maxwell-Poisson, generalized Pareto within mgcv, but maturity is explicitly low. If linked from gam-mgcv, do so as "experimental, validate against brms/glmmTMB/gamlss2", never as a default.

## Implications for skills

Applied 2026-10-28: `gam-mgcv` has a short "Beyond mgcv families: gamlss2 and inlaws" section plus `references/gamlss-and-extra-families.md` (and a pointer in `references/resources.md`). Proposals not applied:

1. `gam-mgcv` reference: add the silent ML/NCV-to-REML switch note for inlaws general families (done in the reference file the same day).
2. `gam-interpretation`: for multi-parameter models, effects are per distribution parameter on the link scale; point to `gratia_diagnostics()` and topmodels PIT for calibration. Not tested (gratia does not draw gamlss2 fits).
3. `stats-reporting-and-review`: report which distribution parameters depend on covariates and a calibration check (PIT/quantile residuals); no boilerplate prose.
4. Do not recommend inlaws as a default (its own README says untested).

## Open research items

1. Full text of the Nature Primer (guidelines on distribution choice, GAIC/BIC selection, model checking, pitfalls). Needs user to supply text/PDF or an accessible preprint.
2. gamlss2 vignettes `prediction`, `families`, `family_extensions`, `specials`; `?gamlss2` for GAIC/model selection helpers and random-effect terms; whether `gamlss2` supports `bs = "re"` and `by =`.
3. inlaws: authors, license, NEWS, MIGRATION.md, `inst/validation`; whether it plays with gratia `appraise()`.
4. Local tests (needs permission to install gamlss2, topmodels, inlaws from R-universe/GitHub): fit a count GAMLSS and compare to mgcv `nb()`/`gaulss()`; run `inlaws::nbls()` example; check gratia 0.11.2.64 handles inlaws callbacks.
5. Check mgcv's own location-scale/shape families list (`?family.mgcv`) to define the hand-off boundary between mgcv and gamlss2.

## Local tests, 2026-10-28 (user approved R-universe/GitHub installs)

Installed: gamlss2 0.1-0, gamlss.dist 6.1-12 (R-universe), topmodels 0.3-0 (zeileis R-universe), distributions3 0.3.0 (CRAN), inlaws 0.0.0.9000 (`remotes::install_github("gam-mafia/inlaws", upgrade = "never")`, built fine on Windows without vignettes), gamlss 5.5-5 (CRAN). R 4.6.0, mgcv 1.9.4, gratia 0.11.2.64. Packages built under R 4.6.1 give a harmless warning on 4.6.0.

Data: `gamlss2::HarzTraffic$bikes` (daily motorcycle counts, n = 1057, mean 203, variance 86,785, 21% zeros), `s(yday, bs = "cc", k = 20)`, REML in mgcv.

| Model | AIC | BIC | logLik | Time (s) |
|---|---|---|---|---|
| mgcv `nb()` (constant theta) | 10498.7 | 10588.5 | -5231.2 | 0.06 |
| inlaws `nbls()` (smooth theta) | 10155.9 | 10273.5 | -5054.2 | 1.0 |
| gamlss2 `NBI`, constant sigma | 10501.4 | 10583.2 | -5234.2 | 0.3 |
| gamlss2 `NBI`, smooth sigma (`\| .`) | 10155.8 | 10262.6 | -5056.4 | 0.2 |

- Allowing dispersion to vary seasonally improves AIC by about 340 in both routes; the two location-scale fits agree closely: theta (nbls) vs 1/sigma (NBI) correlation 1.000, max relative difference 5%; mean curves: median relative difference 0.7%, 90th percentile 8.9%, max 19.5% (day 335, mu < 1, winter near-zero counts). Edfs: nbls 14.1 (mean) and 6.1 (theta); gamlss2 13.6 and 6.0. Constant-theta `nb()` has theta 0.69, and its mean curve differs from the NBI mean by up to 55% where mu is small, so the dispersion model matters here.
- Held-out log score (train days 1-740, test days 741-1057, chronological; the split leaves the last part of a year, so seasonality coverage in test is partial): nb() -1713.0, nbls() -1645.5, gamlss2 NBI -1644.8. Single split, no uncertainty; only indicative.
- mgcv has no native negative binomial location-scale family (its location-scale set is gaulss, gammals, twlss, ziplss, etc.); `inlaws::nbls()` fills that gap in the mgcv framework.
- Diagnostics: `topmodels::rootogram/pithist/qqrplot/wormplot` ran on the gamlss2 fit; PIT histogram roughly uniform, worm plot within bands except the lower tail, rootogram is hard to read with counts into the thousands. `gratia::appraise()` and `gratia::quantile_residuals()` ran on the inlaws `nbls` fit (quantile residuals spanned 0.003-0.999, as uniform quantiles expected). Not tested: whether residual QQ for nbls looked good, only that functions run.

### Gotchas found

1. `gamlss2` fit failed with "there is no package called 'gamlss'" until `gamlss` (CRAN) was installed: gamlss2 uses gamlss/gamlss.dist family code at fit time but does not pull it in (a dependency seems undeclared in 0.1-0).
2. `predict.gamlss2(m, nd)`: second positional argument is not `newdata`; call `predict(m, newdata = nd, type = "parameter")`. The failure message was `invalid subscript type 'list'`.
3. `type = "parameter"` returns a data frame, `type` default returns a `distributions3` vector. NBI `sigma` = 1/theta (mgcv `nb()` size).
4. `inlaws::nbls()` predict(type = "response") returns an unnamed matrix (column 1 mu, column 2 theta); `bam()` errors "general families not supported by bam" (as documented).
5. Loading gratia after topmodels masks `topmodels::rootogram` with `gratia::rootogram`; call `topmodels::rootogram()` explicitly.
6. gamlss2 `AIC()`/`BIC()`/`logLik()` work and agree in scale with mgcv's `AIC`, but mgcv's AIC accounts for penalised edf differently, so only compare roughly across packages.
7. Open ledger items 1-3 above (Nature full text, other gamlss2 vignettes, inlaws authors/license) are still open; item 4 is partly done (nbls and NBI compared; gratia appraise ran; no brms or glmmTMB cross-check); item 5 (`?family.mgcv`) only partly checked from memory, not read.

## Log

- 2026-10-28: fetched gamlss2 index, firststeps, topmodels, bayesian, NEWS; inlaws README and compatibility vignette; Nature article blocked (metadata via search). No installs, no local tests. No skill files changed.
- 2026-10-28 (later): installed gamlss2, topmodels, inlaws (+ gamlss from CRAN) with user approval; compared mgcv nb(), inlaws nbls(), gamlss2 NBI on HarzTraffic bikes; results and gotchas above. No skill files changed.
- 2026-10-28 (merge): folded `gam-distributional-resources-ledger.md` (parallel session, same research, no installs) into this file: added MIGRATION.md provenance, fitting-method caveat, division of labour with gratia, Tonkin author note, implications list. That file was deleted. `gam-mgcv` skill section and reference added and checked (lint, links, clashes, skills-ref validate, version claims).

## Round 2, 2026-10-28 (vignettes and random-effect/by tests)

Sources: gamlss2 vignettes `families` (read), `specials` (read), `family_extensions` (read), `prediction` (blocked again, 404 for .html and .qmd; still unread). Local help pages `?special_terms`, `?random`, `?lin` read via `tools::Rd_db`.

Facts: families can be bridged from `distributions3` (`family(Normal(), links = ...)`) or hand-written lists of class `gamlss2.family` (required: `family`, `names`, `links`, `pdf`; optional `cdf`, `quantile`, `random`, `support`, `score`, `hessian`, ...). The families vignette does not mention gamlss.dist, but the first-steps vignette uses its families. Built-in specials: `lo()`, `tree()`, `ct()`, `cf()`, `n()`, `lin()`, `re()`, `random()`, `gnet()`, `la()`, plus mgcv `s()`, `te()`, `ti()`, `t2()`; special terms are refitted from the working response and weights each backfitting iteration and centred. Extensions: `truncate_family()`, `censor_family()`, `round_family()` (order matters), `inflate_family()` (adds point masses, log-odds link), `hurdle_family()`. Random effects: `s(g, bs = "re")` via mgcv or `re(random, correlation)` wrapping nlme `lme()` (`?random`).

Tests (simulated NB counts, 25 groups x 40 obs, 3-level factor with by-smooths, seed 6153; mgcv 1.9.4, gamlss2 0.1-0):

| Model (`NBI`) | AIC | Result |
|---|---|---|
| mgcv `nb()` reference: `s(x, by = f) + f + s(g, bs = "re")` | 5273.3 | |
| gamlss2 same formula | 5272.1 | predictions within 0.3% of mgcv; RE sd 0.466 vs mgcv 0.481 (simulated 0.474) |
| gamlss2 `re(~1 \| g)` instead | 5274.3 | predictions within 3.8% |
| plus `s(g, bs = "re")` in sigma | 5272.1 | fitted; sigma RE edf 0 (none simulated) |
| `s(x, f, bs = "fs") + s(g, bs = "re")` | 5278.6 | fitted |
| `s(x) + s(f, x, bs = "sz") + s(g, bs = "re")` | 5278.8 | fitted (sz not checked for correctness) |
| by-smooths and `f` also in sigma | 5279.3 | fitted |
| `re(~ xc \| g)` random slope | 5304.5 | fitted; edf reported as 50 (all coefficients), AIC penalised accordingly |

Gotchas: new factor level in `newdata` errors (mgcv `exclude` has no equivalent argument; use `type = "terms"` and drop the `s(g)` column, up to a constant centring shift); `predict(..., model = "mu", se.fit = TRUE)` silently returned NaN, the argument is `parameter =`; `summary()` shows no RE sd (use `fitted.specials[[par]][[term]]$lambdas`, sd approx 1/sqrt(lambda) for unit-scale NBI). Not tested: `bamlss2()`, custom specials/families, other families, held-out comparison, correlated random slopes with `correlation =`.

Open items remaining: Primer full text; `prediction` vignette; inlaws authors/licence/NEWS; brms or glmmTMB cross-check.
