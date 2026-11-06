# Workflow notes: testing choices and running long fits

Evidence labels: "Reproduced" items were re-run on synthetic data (date given); anything marked "reported" or "not reproduced" is a hypothesis.

## Contents

- Cumulative or autocorrelated outcomes and `select`
- Unit and session random terms
- Timing before queueing expensive fits
- Background fits with callr
- Location-scale families

## Cumulative or autocorrelated outcomes and `select`

Reproduced 2026-11-06 (synthetic Gamma(log) random-walk-like cumulative curves, 30 animals x 60 times, mgcv 1.9-5): `s(t, k = 10)` ended at edf 8.86 (ceiling 9) with `select = FALSE` and at 8.85 with `select = TRUE`, so `select = TRUE` did not prevent saturation here. The original report blamed `select = FALSE`; that part is not supported. See the cumulative-outcome note in [smooths-and-families.md](smooths-and-families.md) for the time-scale fix.

## Unit and session random terms

Reproduced 2026-11-06 (synthetic, mgcv 1.9-5): with one session per unit, `s(u, bs = "re") + s(s, bs = "re")` fit the same rows twice. The two standard deviations came out identical (0.83 each) with intervals of 0 to Inf, so only their sum is identified. With 3 sessions per unit they separated (1.09 and 1.09, intervals about 0.8 to 1.6). Before including both terms, tabulate how many units have repeated sessions and which factor levels co-occur within a unit: contrasts that exist only between units depend on how variance is split.

## Timing before queueing expensive fits

Before queueing several expensive fits, time one:

1. Run a 2 to 3 step row ladder (for example 640, 1,280, 2,560 rows) with a short guard (`callr` timeout).
2. Extrapolate to the full data.
3. Queue larger fits only then, and kill queued background fits when the first one times out.

Cost depends on the design (levels of grouping factors, `k`, family), so do not borrow timings from another project. Reproduced 2026-11-06 in a small design (20 animals, 4 levels, `k = 8`): `gam()` with `bs = "fs"` took 0.11, 0.39 and 0.63 s at 640, 1,280 and 2,560 rows; with `sz` 0.45, 0.90 and 2.36 s; `bam(discrete = TRUE)` with `fs` about 0.05 s throughout. An earlier report of 100 s at 640 rows (one project, many more levels) was not reproduced; only the ordering (`sz` and `fs` in `gam()` slower than `bam(discrete = TRUE)`) held. Changing an `fs` covariate (for example to its log) once changed `bam` time several-fold in that project, which is another reason to time one variant first.

## Background fits with callr

- Check the log within the first minute and save results per variant, or every N replicates, so the job is resumable.
- Earlier advice was to start `callr::r_bg()` fits at top level because jobs reportedly died inside `local()` or a returning function. Not reproduced (callr 3.8.0, Windows, R 4.6.0, 2026-11-06: results returned from top-level, `local()` and function-wrapped calls, also after `gc()`). It stays a precaution, not a rule; if a job dies silently, send `stdout`/`stderr` to a log file.

## Location-scale families

Location-scale and other general families are `gam()` only (see [gamlss-and-extra-families.md](gamlss-and-extra-families.md)). Probe scale models on a lean mean model (random intercept and slope instead of `fs` terms), or consider two-stage variance weights in `bam()`.
