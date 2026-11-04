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
