# Model comparison, upgrade checks and bootstrap bands

Evidence labels: "Reproduced" items were re-run on synthetic data (date given); "reported" means one or two projects and not reproduced here. Treat reported items as hypotheses.

## Contents

- Comparing models
- Dependent data: leave-whole-groups-out CV
- After a package upgrade
- Bootstrap simultaneous (max-t) bands

## Comparing models

- `AIC()` and `anova(m1, m2, test = "F")` are approximate tools.
- REML scores are not comparable across models with different parametric (fixed) terms. Refit with `method = "ML"` for that, or compare predictive performance. fREML has the same limit.
- `summary(m)` p-values for smooths are approximate and conditional on the smoothing parameters; report effect shapes with intervals rather than relying only on p-values.
- For `method = "NCV"` comparison see [ncv-and-bam-notes.md](ncv-and-bam-notes.md).

## Dependent data: leave-whole-groups-out CV

Reproduced 2026-11-06 (synthetic: 30 animals x 20 rows, animal-level random shifts left out of the model, an irrelevant animal-level covariate `z`, 40 data sets, mgcv 1.9-5): in-sample AIC preferred the model with `z` by more than 2 units in 52% of data sets, while leave-one-animal-out CV preferred it in 18%. With repeated animals under working independence, in-sample AIC can favour a covariate term that does not help predict new units.

Decide by leave-whole-groups-out CV:

1. Refit without each group (or each fold of groups).
2. Score the held-out groups with the family deviance residuals.
3. Pair the candidate models per group and take the SE over groups.

Centring a smooth covariate is a no-op (identical fit); centring a linear covariate only moves the intercept, so neither changes the comparison.

## After a package upgrade

Re-run a saved anchor script and record `packageVersion()` in saved results. Fixed-family fREML fits are the stable anchor. Extended families (`tw`, `twlss`) and NCV are the paths changelogs usually touch.

## Bootstrap simultaneous (max-t) bands

- State B and which ranked maximum is the critical value (B = 100 means the 5th largest for a 95% band).
- Call contrasts with t within about 5% of the critical value borderline. With small B the critical value is itself noisy, so a contrast near it can flip between B values (seen in one project; the size of the effect depends on the data).
- Use B of at least 1,000 for a final critical value.
- Studentised (bootstrap-t) bands from a nested bootstrap need a stable inner SD. With few inner draws K the inner SD is noisy, which inflates the simultaneous critical value (heuristic benchmark: compare it with a t quantile on K - 1 df; reported twice in one project, 25 inner draws gave 1.5 to 3 times the plain max-t value, not checked upstream). Before interpreting a large studentised critical value, raise inner K once to see whether it falls. Report the percentile max-t and studentised bands side by side, label the studentised one a sensitivity for thin cells, and do not read a nested coverage check as proof of miscalibration.
