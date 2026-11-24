# gam-interpretation / gam-mgcv: gratia re-test ledger

## Requirements

| # | Requirement | Date |
|---|---|---|
| 1 | Install gratia from GitHub (changes not yet on CRAN); re-test notes and update version claims | 2026-10-27 |

## Local tests (gratia 0.11.2.73 from `gavinsimpson/gratia` main, mgcv 1.9-4, R 4.6.0, ggplot2 4.0.3)

| Item | Status | Result |
|---|---|---|
| Install via `remotes::install_github(upgrade = "never")` | read | Worked (earlier load failure did not recur) |
| Exports (conditional_differences, ale, shape_*, residual helpers, get_vcov) | read | present; `simultaneous_bands` and `element_geom` not gratia exports (the latter is ggplot2 4.0) |
| `conditional_differences()` | read | needs both `by` and `condition`; delta, simulation, simultaneous, sz all ran |
| `ale()`, `draw()` | read | ran |
| `smooth_samples(n =)` | read | errors, migration message; `n_draws` works |
| `confint(type = "simultaneous")` | read | `nsim` works; `n_sim` errors (changed vs 0.11.2.10 note) |
| `variance_comp(type = "terms")` | read | now differs from "penalty", has `.proportion*` (changed) |
| `difference_smooths()` on sz | read | still errors |
| `derivatives()`, `smooth_samples()` on sz | read | ran |
| theme customisation, `smooth_col` deprecation | read | as before |
| Not run | not researched | `residual_correlation()`, `get_vcov()`, `shape_intervals()`; outputs of residual helpers not inspected |

## Open items

- `difference_smooths()` on a factor-by model failed with "same prediction grid" when `conc` grids differ per level (CO2); not investigated.
- Gratia changelog not re-read this round.

## Log

- 2026-10-27: re-test run, notes in `gam-interpretation/references/*` and `gam-mgcv/*` updated.

## 2026-11-04: mgcv 1.9-5 ChangeLog check
- Source read (partial, first 90000 of 155399 chars): https://cran.rstudio.com/web/packages/mgcv/ChangeLog. No NEWS file ships in the installed package (`news(package="mgcv")` empty); installed mgcv is 1.9.5, gratia 0.11.2.73.
- 1.9-5: new `bt` smooth (B-spline tensor products with derivative penalties); fixes for censored `cnorm`, `gdiPK` p>n crash, several NCV bugs, `bam` efam scale adjustment, `gumbls` initialisation; `options.mgcv` defaults (`?options.mgcv`); `bandmult`/`bandsolve`; `gamma` works with EFS in `gam`/`scasm`; `ti` never triggers numerical side constraints; tensor penalty scaling changed (fits with `te`/`ti` may differ slightly from 1.9-4); `uniquecombs` no longer adds contrast attribute.
- 1.9-4 (already covered): `scasm`, `bcg`, `plot.gam` derivatives, `bam` reports approximate REML/ML.
- Retests on 1.9-5: NCV without `discrete=TRUE` still warns and resets; small NCV fits 0/30 failed; `twlss` order mean, power, log scale and logLik check still match; `scasm` `sc` k=3 fails, k=4-6 fit; `scasm` `sz` still fails. `options.mgcv` is not an exported object (help topic only, not tested further).
- Skills updated: gam-mgcv/references/ncv-and-bam-notes.md, gamlss-and-extra-families.md. Not changed: gratia notes (dependency mgcv >= 1.9-4 still true).

## 2026-11-06: reproduce-or-drop pass on "reported" claims in gam-mgcv references
All runs on synthetic data, mgcv 1.9-5, callr 3.8.0, R 4.6.0, Windows. Skill files edited: `workflow-and-long-fits.md`, `model-comparison.md`, `smooths-and-families.md`, `ncv-and-bam-notes.md`, `sz-smooths.md`, `gamlss-and-extra-families.md`.

| # | Claim (source) | Status | Result |
|---|---|---|---|
| 1 | Time smooth saturates at k with `select = FALSE` on cumulative outcomes | partly reproduced | Saturation reproduced (edf 8.86/9) but also with `select = TRUE` (8.85); blame on `select = FALSE` dropped |
| 2 | `s(log t)` fixes cumulative-curve saturation, halves RMSE of group means | reproduced | edf 1.97, RMSE 0.55 vs 0.96 |
| 3 | In-sample AIC favours a non-predictive unit-level covariate under working independence | reproduced | AIC preferred it in 52% of 40 data sets, leave-one-animal-out CV in 18% |
| 4 | Unit and session `re` terms only identified from repeated units | reproduced | One session per unit: identical SDs, CI 0 to Inf; 3 sessions: separated |
| 5 | `callr::r_bg()` jobs die inside `local()` or a returning function | not reproduced (second time) | Top-level, `local()`, function-wrapped and after `gc()` all returned results; kept as precaution |
| 6 | `gam()` `fs`/`sz` took 100 s at 640 rows | not reproduced | 0.1 to 0.45 s in a 20-animal design; only the ordering vs `bam(discrete = TRUE)` held; numbers dropped |
| 7 | twlss time ~ rows^2.1, hours at k = 10 | not reproduced | 0.3 to 0.7 s, exponent about 0.5 in a small design; numbers dropped |
| 8 | `select = TRUE` terms with edf < 0.01 have all sp > 1e7 | reproduced (sp > 1e6 up to 2.6e8) | |
| 9 | `summary()` prints p = 0 for edf-near-zero terms | not reproduced | p = 0.50 and 0.85; reworded |
| 10 | sz k-stability halves (k = 6 sign flip, k >= 10 agree) and 0.2 to 1.6 link-unit contrast movement | not testable (data-specific) | numbers dropped, method kept |
| 11 | max-t critical value flip B = 200 vs 100 | not testable (data-specific) | anecdote dropped, mechanism kept |
| 12 | Tweedie/Gamma fREML anchors reproduced after upgrade | not testable | sentence dropped |
| 13 | NCV intermittent failures, parallel `R_Calloc` errors, clustered-sandwich coverage simulation, `scasm` fs/sc timing, sz 2x2 recipe, twlss scale-RE oscillation | not retested this round | left labelled "reported" (NCV 0/30 and sandwich identity already re-run 2026-11-04/05) |

## 2026-11-09: k.check() and `sz` terms, online check (triage follow-up)

Requirement 2 (2026-11-09, user): the triage fix for the "k audit when `k.check()` has no k-index for `sz`" entry must be backed by an online search, not only a local test.

| Source | Status | Finding |
|---|---|---|
| https://stat.ethz.ch/R-manual/R-devel/library/mgcv/html/k.check.html (mgcv 1.9-4 help) | read | Smooths of factor variables are not supported and give an NA p-value. k-index = differencing residual-variance estimate over residual variance, from near neighbours in the numeric covariates; p-value by reshuffling (`n.rep`); models above `subsample` (5000) rows are tested on a random subsample; p-values vary between replicates. "Doubling a suspect k and re-fitting is sensible: if edf increases substantially ..." |
| https://rdrr.io/cran/mgcv/man/k.check.html | read (search snippet) | Same text for the NA statement and edf close to k'. |
| gam.check help (rdocumentation 1.9-4) | read (search snippet) | Same test via `k.sample`/`k.rep`. |
| `?choose.k` text (CRAN manual) | read (search snippet) | Costlier alternative: increase k and refit; no statistically important change means k was large enough; change in smoothness selection criterion and edf are the numerical measures. |
| https://arxiv.org/pdf/1602.06696 (Pya and Wood 2016) | read (abstract) | Origin of the differencing test and of an edf-of-residual-smooth approach; only the abstract was read. |
| mgcv GitHub issues/forums for an `sz`-specific k-index | not researched | Search returned nothing `sz`-specific; whether the NA is intended or only unimplemented for `sz` is not documented beyond the factor-smooth sentence. |

Facts: the k-doubling refit in the skill is documented behaviour, not an invention of the reporting project. Added to the skill: the fREML-score change, the 5,000-row subsample and p-value variability. The bootstrap-SD scale for contrasts stays labelled as one project's addition. Local re-check (mgcv 1.9-5, synthetic bam, `select = TRUE`): NA for the `sz` row; global-smooth edf 6.7 of k' 7 rose to 9.9 at k = 16.

Open: whether the differencing k-index could be computed by hand for `sz` terms (residuals ordered by the numeric covariate within level); not tried.

## 2026-11-24: gratia 0.12.1 (CRAN) changelog read and retest

Requirement 3 (2026-11-24, user): gratia was updated from CRAN; read the changelog and update all skills relying on it holistically, not by one-line fixes.

| Source | Status | Finding |
|---|---|---|
| `utils::news(package = "gratia")` for the installed 0.12.1 (top section read in full, about 1,100 lines; 0.11.x sections not re-read) | read | Large release: 0.12.0 never released, folded into 0.12.1. Breaking: `fixef()` re-export removed, sampling argument rework (`n_draws`, `n_grid`), `fitted_samples()` returns all parameters by default, parametric panels and intercept-inclusive intervals in `draw()`, `back_transform`, `grouped`/`show_ci`, theme API, dependencies (R >= 4.4.0, mgcv >= 1.9-4, ggplot2 >= 4.0.3, patchwork >= 1.3.2). New: simultaneous bands (single smooths, tube), `compare_smooths()`, `random_effect_samples()`, `marginalise`, moments, ALE, residual toolkit, glmmTMB/sdmTMB/gamm4/GJRM/SCAM support, 3D/tile/polar plots. |
| https://gavinsimpson.github.io/gratia/articles/sampling-migration.html | read (via fetch summary) | General old-to-new table only; does not give per-function names for `fitted_values()`, `confint()`, `difference_smooths()`, `derivatives()`, `draw()`, `smooth_estimates()`; says `response_derivatives()` and `conditional_differences()` keep their own arguments. |

Local tests (fresh `callr::rscript` process, gratia 0.12.1, mgcv 1.9.5, R 4.6.0, synthetic `data_sim("eg1")` and `CO2`; scripts were in the scratch directory and are not kept):

| Item | Result |
|---|---|
| Exports | `fixef` and `simultaneous_bands` not exported; `fixed_effects`, `compare_smooths`, `random_effect_samples`, `fitted_moments`, `conditional_moments`, `shape_intervals`, `residuals_covariate_plot`, `draw_label_control`, `family_parameters`, `dharma_residuals`, `add_sizer`, `evaluate_smooth` (defunct) exported; `marginalise` is an argument, not a function |
| `draw()` panel count | 5 default vs 3 with `parametric = FALSE` on `Type + Treatment` + 2 smooths |
| `fitted_values(interval = "simultaneous")` | `n_sim` changes band width (2.64 at 50, 2.71 at 5,000 draws); `n_draws` silently ignored (identical to no setting) |
| `response_derivatives()`, `conditional_differences(uncertainty = "simulation")` | `n_sim` works; `n_draws` errors ("matched by multiple actual arguments") |
| `confint(type = "simultaneous")` | `nsim` works; `n_draws` also returned a result (effect not checked) |
| `smooth_samples(n =)` | migration error; `n_draws` works |
| `fitted_samples()` | `.parameter` column present; `quantity = "expectation"` accepted, identical for Gaussian identity-link |
| `variance_comp(type = "terms")` | `.proportion*` columns plus `total`; proportions sum to 1 on one Gaussian GAM |
| `difference_smooths()` factor-by on `CO2` (unequal grids) | now runs (was an open item); simultaneous and `order = 1` run |
| `difference_smooths()` on `sz` | still errors |
| `conditional_differences()`, `derivatives()`, `draw()`, `smooth_samples()` on `sz` | run (one Cholesky-fallback warning for `smooth_samples`) |
| `simultaneous_method = "tube"` | runs for `tp` and `cr`; crit 3.10 / 3.09 (changelog restricts to supported cubic splines; `tp` support not verified) |
| `conditional_values()` with two numeric covariates | 2,500-row grid |
| `marginalise = TRUE`, `random_effect_samples()` | run; numbers not validated against manual integral |
| `compare_smooths()` | runs; `draw(show = "difference")` not run |
| Theme API, `smooth_col` and `grouped_by` deprecations, `parametric_effects(transform =)` deprecation | warnings as documented |
| `back_transform = TRUE` | adds `.gratia_raw_<x>` column for `s(log(x))` |

Not run: polar, 3D and tile plots, moments, shape intervals, surrogate residuals, multi-chain MH, glmmTMB/sdmTMB/gamm4/GJRM/SCAM support, mirai workers, `variance_comp` for `gamm`/`gamm4`.

Skills updated: `gam-interpretation` (SKILL.md v1.1, `recent-developments.md` rewritten around 0.12.1, `visualisation.md`, `uncertainty-and-inference.md`), `gam-mgcv` (SKILL.md, `sz-smooths.md`, `hgam-and-random-effects.md`, `smooths-and-families.md`, `gamlss-and-extra-families.md`, `resources.md`). Not touched: `social-research-search`, `skill-lessons`, `github-skill-maintenance` (gratia appears only as an example or a package name list).

### 2026-11-24 (second round): the features left untested above

Requirement 4 (2026-11-24, user): test polar and 3D plots, `fitted_moments()`, `shape_intervals()`, glmmTMB `draw()` and record the results. Same setup (fresh `callr::rscript`, gratia 0.12.1, mgcv 1.9.5, glmmTMB 1.1.15.2, synthetic data). Installed from CRAN with the project's standing permission: `ggcube` 0.3.0 and `sf` 1.1-3 (and sf's dependencies); `scam`, `sdmTMB`, `loo`, `bayesplot` were not installed, so those methods stay untested. Plots were saved as small PNGs; two (polar, glmmTMB) were looked at, the rest were only checked to be written without error.

| Item | Status | Result |
|---|---|---|
| `draw(cyclic = "polar")`, cyclic `cc` smooth | run, image viewed | Draws: circular axis with 0 at top, radial partial effect, rug outside the ring, ribbon visible. Also ran on a factor-by cyclic smooth (image not viewed). Non-cyclic call on the same smooth ran too |
| `draw(surface = "tile")` | run | PNG written (image not viewed) |
| `draw(surface = "3d")`, `ci_3d = TRUE`, and on a `conditional_values()` surface | run after installing ggcube **and sf** | Without ggcube: error naming ggcube. With ggcube only: error "3D surface support and domain checks requires the optional package 'sf'". Both needed. Images not viewed, so appearance (occlusion, interval surfaces) unchecked |
| `draw(conditional_values(m, condition = list(c("th","x1"))))` | run | Surface plot written |
| `draw_label_control()` | run | `draw(m, label_control = draw_label_control())` ran; effect on labels not inspected |
| `fitted_moments()` | run, values checked | Poisson: mean = variance (2.74), cv = 1/sqrt(mean) ok. Gamma log link: mean equals `predict(type = "response")` (0.807, 1.353) and variance/mean^2 = cv^2 (0.39). `gaulss()`: variance equals (1/tau)^2 from `predict` (0.449 vs 0.670^2; 2.21 vs 1.487^2). `nuisance = "fixed"` runs. Output is long: `.row`, `.parameter` (mean, variance, cv), `.fitted`, `.se`, CI, `.status` |
| `conditional_moments()`, `family_parameters()` | run | Return the same long layout; `family_parameters()` lists parameter, link, predictor index, global vs predictor |
| `fitted_samples()` default vs `quantity = "expectation"` | run on `gaulss()` | Default returns `mean` and `sd` parameters (5 draws each); expectation returns one `expectation` series. Earlier Gaussian note (identical output) holds only for single-parameter models |
| `shape_intervals()` | run on hand-made bands | Signature is `(estimate, lower, upper, data, constraints, interval, level)`: `data` (complete Cartesian grid) and a named `constraints` list (`"m+"`, `"m-"`, `"c+"`, `"c-"`, `"+"`) are required, so calling it on a `smooth_estimates()` tibble alone errors ("argument data is missing"). Monotone: output estimate nondecreasing, band width not larger, a monotone target inside the input band stayed inside. Convex: output second differences >= 0. `lower > upper` errors. Help text: operators preserve whole-grid containment, give no pointwise coverage guarantee, and do not fix bias or a bad initial band |
| `scasm()` + `draw(interval_method = "shape")`, `smooth_estimates(interval_method = "shape")`, `confint(interval_method = "shape")` | run | Each emits the warning that shape enforcement preserves whole-grid containment and gives no guaranteed pointwise calibration; `.crit` column returned. `scasm()` fit with `xt = "m+"` returned class `gam glm lm` |
| `shape_confidence_set()` | formals only | Arguments `X, lower, upper, Ain, bin, C, d, level, interpretation, band_type`; not run |
| glmmTMB: `draw()`, `assemble()`, `smooth_estimates()`, `appraise()` | run, `draw()` image viewed | Gaussian `s(x1) + g + (1 | id)`: 3 panels (smooth with band, random-intercept QQ, factor `g` pointrange). `assemble()` names `s(x1)`, `(1 | id)`, `g`. `smooth_estimates()` 100 rows. `appraise()` plot written. Poisson with a cyclic smooth and a zero-inflation smooth fit also drew. `ranef_lines = TRUE` ran on `(1 + x1 | id)` (image not viewed) |
| glmmTMB `fixed_effects()` | run | Errors "No fixed-effects method for this object": use `glmmTMB::fixef()` for glmmTMB fits |
| Not testable here | not run | sdmTMB, SCAM (`scam` not installed), `loo`/`bayesplot` methods, GJRM, mirai workers, multi-chain MH |

Skill files updated from this round: `gam-interpretation/references/recent-developments.md` (status table), `visualisation.md` (polar, 3D, moments, glmmTMB), `uncertainty-and-inference.md` (moments, `shape_intervals()`).

Open: per-function argument names for the sampling rework (only five functions tested); whether `n_draws` in `confint()` takes effect; `tube` on non-cubic smooths; the 0.11.x changelog sections were not re-read.
