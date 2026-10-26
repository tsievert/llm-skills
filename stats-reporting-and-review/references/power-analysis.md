# Power and sample-size analysis

Tested: `pwr` 1.3.0 (R 4.6.0, Windows, 2026-10-26), `pwr.t.test()`. Not tested this round: `simr`,
`WebPower`, `glmmrBase`.

## Decision rule

| Design | Tool |
|---|---|
| t-test, one-way ANOVA, chi-square, correlation, proportions | `pwr` (closed-form) |
| Designs `pwr` doesn't cover (more complex ANOVA, some proportions tests) | `WebPower` (closed-form; not evaluated in depth here) |
| GLMM / LMM (random effects, repeated measures) | `simr::powerSim()` (simulation-based, needs an `lme4` fit) |
| Cluster-randomized / GLMM via an information-matrix approach instead of simulation | `glmmrBase`/`glmmr` (analytic; not evaluated in depth here) |

Solve for whichever of {n, effect size, significance level, power} is unknown; `pwr` functions take `NULL` for
the one to solve for.

```r
library(pwr)
pwr.t.test(d = 0.5, power = 0.8)                 # n per group needed for d = 0.5
pwr.anova.test(k = 3, f = 0.25, power = 0.8)      # one-way ANOVA
pwr.chisq.test(w = 0.3, df = 2, power = 0.8)
pwr.r.test(r = 0.3, power = 0.8)
```

State the effect size assumption explicitly (from a pilot, a prior study, or a minimum effect of scientific
interest) — power numbers are only as good as that input, and should never be presented without naming its
source.

## GLMM power via `simr`

`simr::powerSim()` runs Monte Carlo simulation from a fitted (or hand-specified) model, and `powerCurve()`
projects power as sample size grows by extending the pilot design (more groups, more observations per group):

```r
library(simr); library(lme4)
# simr needs an lme4 fit, not glmmTMB -- refit the pilot model for this step only
m_pilot <- glmer(count ~ treatment + (1 | animal), family = poisson, data = pilot)
powerSim(m_pilot, nsim = 200)
m_ext <- extend(m_pilot, along = "animal", n = 40)
powerCurve(m_ext, along = "animal")
```

**Flag the refit seam to the user.** `mixed-models-glmm`'s default stack is `glmmTMB` (handles Gamma,
beta-binomial, zero inflation, dispersion models that `lme4` does not). `simr` only works on `lme4::lmer`/
`glmer` objects. For a power analysis, either refit the pilot model in `lme4` for this step alone (fine when
the family is one `lme4` supports) or use an analytic alternative (`glmmrBase`) that works from a model
specification rather than a fitted `lme4` object — do not silently pick one without saying so, since the two
approaches can give different power estimates for the same nominal design.

## A priori vs. post hoc power

Power analysis before data collection (a priori, to plan sample size) is standard practice. Power analysis
computed from the same data already analyzed (post hoc / observed power) is not informative — it is a
deterministic function of the p-value and tells nothing new. If the user asks for "the power of this test" on
completed data, say this and ask whether they mean a CI/effect-size report (section
[effect-sizes.md](effect-sizes.md)) or a true a priori calculation for a follow-up study.
