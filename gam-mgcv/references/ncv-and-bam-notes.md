# bam() with method = "NCV": notes for fitting, resampling and review

Contents: what NCV is for, comparing models, fixed-sp refits for resampling, failures, checking
`select = TRUE`. Tested with mgcv 1.9-4 on Windows (synthetic Gaussian data, n = 4000, two smooths and
one `bs = "re"` term). Items marked "reported" come from a real project and were not reproduced here.

## What to know before using it

- `bam(method = "NCV")` needs `discrete = TRUE`; without it mgcv warns "NCV only available with
  discrete=TRUE - resetting" (seen in 1.9-4) and continues, so read the warning rather than the call.
- Cost grows with the number of smoothing parameters, `nei` (neighbourhood definition) and sample size.
  Fewer smoothing parameters (for example `id =` in `sz` terms so factor levels share one) reduces it.
- Compare models by the fitting criterion stored in the object, or by a blocked cross-validation you run
  yourself, not by `AIC()` of NCV fits without thinking about what was optimised. When comparing, keep
  `nei` and any `sample` subset identical across the models.
- `select = TRUE` with `discrete = TRUE` is documented only in general terms in `?bam`; verify the effect
  on the fitted object instead of assuming it (below).

## Resampling or bootstrapping at fixed smoothing parameters

Keeping `method = "NCV"` with `sp = <fitted sp>` skips the sp search but still pays NCV overhead and
returns an empty `$sp`. Measured here: 0.86 s versus 0.05 s for the fREML refit. For a bootstrap or any
refit that only needs coefficients at fixed smoothing parameters, switch method:

```r
m_ncv <- bam(f, data = d, method = "NCV")
m_fix <- bam(f, data = d, method = "fREML", discrete = TRUE, sp = m_ncv$sp)
max(abs(coef(m_ncv) - coef(m_fix)))   # 0 in the test here; NCV only chooses sp
```

Say in the write-up that smoothing parameters were held at the original fit, so the intervals do not
include sp uncertainty.

## Failures to expect and report (reported, not reproduced)

- On small synthetic data about a quarter of NCV fits (20 of 70, same design, different seeds) stopped with
  "infinite or missing values in 'x'" from `eigen(NCV2, ...)`. In a simulation study, count and report the
  failed fits; analysing only the successful ones can select easy data sets.
- Several parallel local workers (four, with two threads each on a 16-thread machine) gave `R_Calloc`
  allocation errors in about 10 percent of fits; the same seeds succeeded when retried with less contention.
  Budget memory per worker, retry allocation errors once, and keep the error text per seed.

## Checking that select = TRUE penalised a term out

```r
m$call$select; m$call$discrete                              # what was actually requested
sapply(m$smooth, function(s) s$null.space.dim)               # 0 means the null space has its own penalty
data.frame(term = vapply(m$smooth, `[[`, "", "label"), edf = summary(m)$s.table[, "edf"])
lapply(m$smooth, function(s) m$sp[s$first.sp:s$last.sp])     # all sps huge (for example > 1e7): fully shrunk
```

Reported: terms with edf below 0.01 had all smoothing parameters above 1e7. `summary()` can print p-values
of exactly 0 for terms with edf near zero (huge F); do not report those, and say "shrunk to near zero"
only after checking the smoothing parameters.
