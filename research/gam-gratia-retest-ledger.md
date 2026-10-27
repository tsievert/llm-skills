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
