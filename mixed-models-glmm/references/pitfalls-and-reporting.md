# Pitfalls and reporting for mixed models

## Contents
- Pseudoreplication and design
- Fitting problems
- Diagnostics: what DHARMa can and cannot tell
- Inference choices
- Reporting checklist and example wording
- Sources to check for currency

## Pseudoreplication and design

- Group (treatment, sex) varying between animals has effective sample size near the number of animals, not the number of rows or frames. A model with `(1 | animal)` accounts for this; a model without it does not. Aggregating to one value per animal is a valid fallback when the design is simple.
- Sessions nested in animals: `(1 | animal/session)` or `(1 | animal) + (1 | animal:session)`. If one value per session exists, the session term is often not identifiable and gets dropped.
- Cage, litter or arena batch effects: add as random intercept when there are at least ~5 levels; otherwise a fixed covariate.
- Many frames or bouts per recording: model the summary (binomial on counts, Gamma on durations) or use bout-level data with a nested random effect, not frame-level data treated as independent.

## Fitting problems

| Symptom | Likely cause | Action |
|---|---|---|
| Singular fit, variance ~ 0 or correlation +/-1 | Over-parameterised random effects | Remove the correlation or the slope; report that the variance was at the boundary |
| `non-positive-definite Hessian`, huge SEs | Separation, tiny groups, collinearity or too flexible family | Check the data table; simplify the fixed part; rescale covariates |
| `false convergence` or NaN SEs | Scale of predictors, flat likelihood | Centre and scale; try `glmmTMBControl(optimizer = optim, optArgs = list(method = "BFGS"))` as a check, not as a fix |
| Plain binomial with enormous dispersion | Frame-level autocorrelation inside a recording | Beta-binomial or aggregate |
| Dispersion test fine but residuals fan out against fitted | Variance differs between groups | `dispformula = ~ group` |

Run `glmmTMB::diagnose(m)` for glmmTMB convergence details and see `vignette("troubleshooting", package = "glmmTMB")`.

## Diagnostics: what DHARMa can and cannot tell

- DHARMa residuals are simulation-based and uniform under a correct model for any family. Use `plot(sim)`, per-predictor `plotResiduals()`, and the formal tests as a screen, not as proof of fit.
- Tests are power-limited with ~50 observations. Non-significant does not mean absent (zero-inflation example in `scripts/glmm_templates.R`), and with thousands of rows trivially small departures become significant.
- With random effects, the default simulations condition on the fitted random effects. For group-level checks use `recalculateResiduals(sim, group = animal)`.
- Look for outliers in terms of the research question (a pose-tracking failure is a data issue to fix upstream, not a model issue).

## Inference choices

- Wald z from glmmTMB assumes large samples; LRT is preferable for terms with several df. Parametric bootstrap (`pbkrtest`, installed locally, supports lme4 models) is the careful option for small n; not tested here with glmmTMB.
- Do not interpret main effects in the presence of an interaction without stating the level at which they hold.
- AIC comparisons need the same response, data and family; do not compare AIC across families that code the response differently (`log(y)` vs `Gamma` on `y`).
- Avoid `MuMIn::dredge` style all-subsets selection for inference: it inflates false positives. Use it only for prediction or clearly mark exploratory use.
- Post hoc contrasts with `emmeans`: choose the family of comparisons before looking (`pairwise`, `trt.vs.ctrl`), and report the adjustment.

## Issues reported for ecological and behavioural data

Source: OpenAlex searches on 2026-10-23 (works ranked by citations; statements below rest on titles and the abstract text retrieved, not on full-text reading; check the paper before citing a specific result). IDs are OpenAlex work IDs (https://openalex.org/W...).

| Issue | What the literature says | Work |
|---|---|---|
| Random intercepts do not remove pseudoreplication for within-animal effects | If individuals differ in their response, intercept-only models give overconfident estimates; allow random slopes | Schielzeth & Forstmeier 2009, W2146506147 |
| Using BLUPs as data in a second step | Predicted individual random effects carry large error that is not propagated, producing spurious P values | Houslay & Wilson 2017, W2592003945 |
| Variance in the variance (predictability) | Reviews statistical approaches for between-individual variation in within-individual variance; many differ in how well they work. `dispformula` in glmmTMB models dispersion by fixed predictors; whether it covers the individual-level question is not verified here, so consult the paper | Cleasby et al. 2014, W2055156391 |
| General pitfalls and model selection | Overview of typical mistakes, information-theoretic selection and multi-model inference in ecology | Harrison et al. 2018, W2783564415; Silk et al. 2020, W3048859890 |
| Few levels of a grouping factor | Simulations on fixed vs random treatment; one finds fixed-effect estimates unaffected when the grouping is a nuisance | Gomes 2022, W4205871941; Oberpriller et al. 2022, W4286884901 |
| Overdispersion in counts | Ignoring it biases estimates and conclusions; observation-level random effects are one remedy with conditions on when they work | Harrison 2014, W2163861300 |
| Data-driven family choice | Checking for zero inflation/overdispersion and then switching model is a multi-stage procedure with possible selection bias; decide the family from design where possible and report the steps | Campbell 2021, W2982955940 |
| Violated distributional assumptions | Simulation of skewed, bimodal, heteroscedastic random effects and missing random terms; read for which estimates are robust | Schielzeth et al. 2020, W3035663944 |
| Complex random structures | Maximal structures often overfit; parsimonious reduction of random effects | Bates et al. 2015, W1604065854 |
| Spatial autocorrelation | Overlooked in behavioural ecology (home ranges, neighbours, arena positions) | Vâlcu & Kempenaers 2010, W2135539334 |
| Practical GLMM guidance | Standard reference | Bolker et al. 2009, W2155988679 |
| Repeatability software | `rptR` for Gaussian and non-Gaussian data | Stoffel et al. 2017, W2605868587 |

glmmTMB tracker items likely to bite on animal data (titles only, https://github.com/glmmTMB/glmmTMB/issues/N, found via the GitHub search API; keyword match is loose, so relevance is my judgement):

- #536 Kenward-Roger, Satterthwaite or LRT in glmmTMB (open): there is no small-sample df correction, so LRT or bootstrap is the careful choice with few animals.
- #830 and #522 identifiability and rank deficiency of fixed predictors (open): collinear or confounded predictors (e.g. group and cage) may fit without error; check `diagnose(m)` and the design table.
- #888 `re.form` for `simulate()` and `residuals()` (open): DHARMa simulations condition on fitted random effects by default; interpret residual checks with that in mind.
- #744 NaN negative log-likelihood at starting values (open): usually bad scaling or impossible values (e.g. zeros with log link Gamma); see data checks.

Practical consequences already built into the skill: random slopes where the data can support them, no stepwise or BLUP pipelines, family chosen from the response type with checks documented, and LRT/bootstrap over Wald z when animals are few.

## Reporting checklist

- Question and design (n animals, n observations per animal, within/between factors).
- Model: family, link, formula incl. random effects, software and versions (`packageVersion()`).
- Diagnostics performed and decisions taken (family change, dispersion model, simplified random structure).
- Estimates on an interpretable scale with 95% CIs: ratio of means, odds ratio, rate ratio. State averaging (`averaged over day and sex`).
- Variance components or ICC with scale.
- Multiplicity handling and which tests were pre-specified.
- Plain wording such as: "Mean distance in the odourA group was 0.81 times that of controls (95% CI x to y, Wald z, Gamma GLMM with random animal intercepts, 24 animals, 48 sessions)." Describe uncertain results as compatible with a range of effects, not as "no effect".

## Sources to check for currency

- glmmTMB vignettes and NEWS: https://glmmtmb.github.io/glmmTMB/
- DHARMa vignette: https://cran.r-project.org/package=DHARMa/vignettes/DHARMa.html
- emmeans vignettes: https://cran.r-project.org/package=emmeans
- performance docs: https://easystats.github.io/performance/
- GLMM FAQ (Ben Bolker): https://bbolker.github.io/mixedmodels-misc/glmmFAQ.html
- For method literature, use the `openalex` skill (not web search).
