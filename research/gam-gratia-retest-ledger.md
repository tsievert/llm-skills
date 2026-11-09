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
