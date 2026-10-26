# Effect sizes and confidence intervals

Tested: `effectsize` 1.0.3, `report` 0.6.4 (R 4.6.0, Windows, 2026-10-26), on `lm`/`aov` objects. Not tested
on `glmmTMB`, `lme4`, or `gam` objects — `effectsize`'s `Suggests` list includes `lme4`, `lmerTest`, `mgcv`
and `emmeans`, so it is designed to work with them, but verify the output before trusting it on a new model
class.

## Core principle

Report the estimate and its CI, not just a significance label. A CI on an effect size carries strictly more
information than a p-value: it shows which parameter values the data are and are not consistent with, not
just whether zero is one of them. State the scale the effect size is on (raw units, SD units, odds ratio,
proportion of variance) every time — the same discipline `gam-interpretation` already requires for smooth
terms, which lack a single effect-size number but still need a stated scale.

## Standardized effect sizes (`effectsize`)

```r
library(effectsize)

# Two groups
cohens_d(y ~ group, data = d)           # Cohen's d with CI
hedges_g(y ~ group, data = d)           # small-sample-corrected d

# ANOVA / linear model
eta_squared(aov(y ~ group, data = d))        # or partial, with CI
omega_squared(aov(y ~ group, data = d))      # less biased than eta2 for small n

# Odds ratios / standardized logistic coefficients
m <- glm(outcome ~ predictor, family = binomial, data = d)
standardize_parameters(m, exponentiate = TRUE)   # odds ratios with CI

# From a reported test statistic only (no model object available)
t_to_d(t = 2.5, df_error = 38)
F_to_eta2(f = 11.26, df = 1, df_error = 38)
```

`effectsize` extracts the test statistic and degrees of freedom directly from the model object rather than
requiring the user to type them in — this is the main advantage over computing effect sizes by hand from a
reported F or t. Confidence intervals default to the noncentrality-parameter method; state this in the
Methods text if it matters for the target journal.

## Narrative scaffold (`report`) — draft only, never final text

```r
library(report)
report(m)            # full paragraph: model type, fit statistics, each term
report_effectsize(m) # effect-size sentences only
report_parameters(m) # parameter table sentences only
```

`report()` writes a complete APA-style paragraph, including causal-sounding phrasing ("the effect of X is...")
that the model's design may not support. Treat its output the way this repo treats any auto-generated prose:

- Use it to get the numbers right and see a plausible sentence structure, not as something to paste in.
- Check every causal verb against the actual design (observational vs. experimental).
- Re-derive or re-state which scale each number is on (link vs. response, raw vs. standardized) — `report()`
  mixes them in one sentence by convention, which is fine for exploration but needs separating for a
  manuscript.
- Hand the resulting document, once the user has written their own sentences, to `manuscript-writing-quarto`
  for structure and linting — do not have `report()` write the Results section directly.

## Known seams

- `effectsize`'s automatic extraction depends on `insight::get_data()`/`get_parameters()` working for the
  model class; a model fit with unusual weights, offsets, or a custom family may need a manual fallback via
  `t_to_d()`/`F_to_eta2()` with hand-supplied statistics.
- For a GAM's parametric (non-smooth) terms, `effectsize` may work via `insight`'s `mgcv` support, but there is
  no single effect-size number for a smooth term — defer that reporting to `gam-interpretation`'s calibrated
  wording instead of forcing a number onto it.
