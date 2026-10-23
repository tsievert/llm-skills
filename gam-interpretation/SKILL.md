---
name: gam-interpretation
description: Visualizes and cautiously interprets fitted generalized additive models (mgcv GAMs, GAMMs, bam) using gratia, ggplot2 and related tools. Covers partial-effect plots, partial residuals, response-scale predictions, surfaces, group comparisons, derivatives, simultaneous intervals, posterior simulation, and calibrated wording for reporting uncertain results. Use when the user asks to plot, explain, interpret, report, or write up what a GAM shows, or asks whether a smooth effect is real, significant, linear, or different between groups. Checks the installed gratia version and recent developments before suggesting functions.
license: MIT
metadata:
  author: tsievert
  version: "1.0"
---

# Visualizing and interpreting GAMs

Companion to `gam-mgcv` (fitting and checking). Use this skill once a model exists, or when the user wants to explain or report it.

**Core stance.** A GAM gives a penalized estimate of a curve or surface, conditional on a model, a chosen basis, and estimated smoothing parameters. Plots and intervals summarize that estimate; they do not prove a shape, a threshold, or a mechanism. Write accordingly (see [references/phrasing.md](references/phrasing.md)). When in doubt, say less and state what the data cannot resolve.

## Step 0: currency check (do this first)

gratia changes quickly; code from memory is often outdated. Before writing code:

1. `packageVersion("gratia"); packageVersion("mgcv")`.
2. Test which functions exist, rather than assuming:
   `sapply(c("conditional_differences", "conditional_values", "response_derivatives", "ale", "gratia_theme_set"), \(f) f %in% getNamespaceExports("gratia"))`
3. If a function is missing or an argument errors, read the gratia changelog and reference index (https://gavinsimpson.github.io/gratia/news/index.html, https://gavinsimpson.github.io/gratia/reference/index.html) and, if relevant, Gavin Simpson's blog (https://fromthebottomoftheheap.net/). Do not guess argument names.
4. Consult [references/recent-developments.md](references/recent-developments.md) for what was new when this skill was written and how to re-check.

## Workflow

1. **Confirm the model is fit to interpret.** Diagnostics from `gam-mgcv` (k-index, residuals, concurvity, dependence) done, and unresolved problems noted. Interpretation of a poorly checked model gets caveats up front.
2. **Decide the question**, because different outputs answer different questions:

| Question | Output | Notes |
|---|---|---|
| What does one term contribute? | `draw(m)`, `smooth_estimates()` + `add_confint()` | Centred partial effect on the link scale; not the expected response |
| What does the model predict for specific covariate values? | `fitted_values()`, `conditional_values()`, `data_slice()`, or `predict(se.fit = TRUE)` | Combines all terms; state what is held fixed and which random effects are excluded |
| Do groups differ? | `conditional_differences()` where available, or a linear-combination contrast; `difference_smooths()` for centred smooth shapes | Never judge by overlap of two bands |
| Where is the rate of change non-zero? | `derivatives()`, `response_derivatives()`, `derivative_samples()` | Pointwise unless stated; heuristic finite differences |
| How uncertain is a derived quantity (peak location, area, threshold)? | posterior simulation: `smooth_samples()`, `fitted_samples()`, `posterior_samples()` | Conditional on smoothing parameters unless `unconditional = TRUE` |
| How much variation does each term carry? | `variance_comp()` | Proportions can exceed 1 or be negative |

3. **Check support.** Show data (rug, partial residuals, or points). Mask or flag regions with little data (`too_far()`, `data_slice(.by = )`, `dist =`). Do not interpret wiggles, plateaus or edge behaviour where there is little or no data.
4. **Choose the interval type** (pointwise, simultaneous, across-the-function; link vs response scale) and label it on the figure or in the caption.
5. **Write the result** with calibrated language. Report the estimate, its uncertainty, the scale, and what is held fixed; separate what is estimated from what is speculated.

## Visualization rules

- Plot against the original covariate scale with `back_transform = TRUE` where covariates are transformed; the vertical axis stays on the link scale.
- State the scale on the y-axis label: "partial effect on log odds", "centred contribution to log expected count", "expected count (response scale)".
- Always show the rug or partial residuals so readers see where data exist.
- Label intervals (95% Bayesian credible/confidence, pointwise or simultaneous) in the caption.
- Use a common y-range across panels only when comparing effect sizes; otherwise note differing scales.
- Plotting recipes, theming (new theme-based API in recent gratia), surfaces, group comparisons and common pitfalls: [references/visualisation.md](references/visualisation.md).

## Interpretation rules (short form)

- Smooth terms are centred; they show shape relative to the model's other terms, not the expected response.
- Intervals are approximate and conditional on the model and, by default, on the estimated smoothing parameters. Pointwise 95% intervals are not simultaneous bands over the whole curve.
- A smooth's p-value in `summary()` tests whether that term is exactly zero (approximate); it does not tell you the effect is large, linear, or the shape is right.
- edf is a measure of fitted flexibility under the penalty, not a count of turning points or a significance measure. edf near 1 suggests an approximately linear term, but check the plot.
- A band that contains zero does not demonstrate "no effect"; a band that excludes zero does not demonstrate importance or causation.
- Non-overlapping or overlapping bands are not tests of difference; compare through a contrast that carries the covariance.
- Predictions outside the observed support, or at covariate combinations absent from the data, are extrapolations.
- Associations in observational data are not causal effects. Avoid "effect of X on Y" phrasing unless the design supports it.

Details and rationale: [references/uncertainty-and-inference.md](references/uncertainty-and-inference.md).

## Reporting checklist

State: family and link; smooth bases and `k`; estimation method; diagnostics and unresolved concerns (k-index, dependence, concurvity); what each figure shows (term vs prediction, scale, held-fixed values, excluded random effects); interval type and nominal level; the number of simulation draws and seed for any simulation-based result; and sample size and support. Mention approximations (delta method, Gaussian posterior approximation) where used.

## When the user asks for a definitive statement

If the user asks "is the relationship non-linear?", "is there a threshold?", or "is group A different from B?", answer with what the model supports, the uncertainty, and what would change the answer (more data, different basis, different smoothing choices). Offer a sensitivity check (different `k`, basis, `select = TRUE`, or a simpler parametric comparison) rather than a categorical verdict.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were done or not done: why this method, setting or tool was chosen, which alternative was rejected and why, which check or step was skipped, and which assumptions were made. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a package version or API differs from what it states, or it lacks guidance the task needs, record a generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
