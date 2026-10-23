# Calibrated phrasing for GAM results

## Contents
- Principles
- Words to avoid and alternatives
- Templates
- Region-specific statements
- Group comparisons
- Derivatives and turning points
- Model-level statements
- Limitations paragraph
- Pre-send checklist

## Principles

1. Describe the fitted curve, then the uncertainty, then (separately) any biological or substantive reading.
2. Attribute claims to the model: "the fitted model suggests", "the estimated curve", "conditional on this model".
3. Quantify when possible, with the scale and interval type.
4. Keep "no evidence of" separate from "evidence of no".
5. Reserve strong words (clear, strong, striking, demonstrates, proves) for results that are robust to checks. Prefer "suggests", "is consistent with", "indicates" with a limitation attached.
6. Never describe detail in sparsely observed regions as a feature.
7. Do not turn a smooth shape into a mechanism ("threshold", "tipping point", "optimum") without a targeted analysis and its uncertainty.

## Words to avoid and alternatives

| Avoid | Prefer |
|---|---|
| "X significantly affects Y" | "The fitted smooth of X deviates from a constant (approximate p = ...), and the estimated change in Y over the observed range is ..." |
| "X has no effect" | "The data provide little information about an effect of X; the interval includes zero across the observed range." |
| "The relationship is non-linear" | "The fitted curve is non-linear (edf = ...), with the departure from a straight line concentrated at ..., though intervals are wide there." |
| "The effect peaks at x = ..." | "The fitted curve is highest near x = ... (posterior range ... to ...); the curve is flat enough that other values are also plausible." |
| "A threshold at ..." | "The estimated slope changes from positive to near zero around ...; the location is uncertain (interval ...)." |
| "Group A is higher than B" | "The estimated difference A - B is ... (95% simultaneous interval ... to ...) at x = ...; the interval includes zero for x > ..." |
| "The model proves / confirms" | "The model is consistent with ..." |
| "Strong / clear relationship" | Give the estimated change and interval; avoid adjectives or justify them with the numbers |
| "Controlling for Z" | "Holding Z at [value] in the model" (and add that this is a modelling assumption, not an experimental control) |
| "Causes / drives / leads to" | "is associated with" unless the design supports causal language |
| "Random effects were removed" | "Predictions are for the typical group (random effects set to zero), not the population average on the response scale." |

## Templates

Single smooth, link scale:

> The fitted smooth of [x] [rises/falls/is non-monotonic] over [range]. Relative to the model's other terms, the estimated partial effect changes by about [value] on the [link] scale between [x1] and [x2] ([interval type], [level]). The approximate test of the smooth against zero gives p = [..], which indicates the term differs from a constant but does not describe its size or exact shape. Uncertainty is largest where data are sparse ([range]).

Response-scale prediction:

> Holding [covariates] at [values] and excluding [random effects], the model-estimated expected [response] at [x] is [value] ([interval type] [level] interval [lo, hi]). This is a model-based estimate of the conditional mean; it is not a prediction interval for a new observation.

Weak or ambiguous result:

> The estimated curve suggests [direction], but the interval includes [a flat / no-change curve] throughout, so the data do not distinguish a modest effect from none. The conclusion is sensitive to [k / smoothing / basis / dependence] (see sensitivity analysis).

## Region-specific statements

- Name regions by data coverage: "Between [a] and [b], where most observations lie, ...; beyond [b] there are few observations and the estimate is driven largely by the penalty and the basis."
- At boundaries: "behaviour near the boundaries is poorly constrained."
- For extrapolation: state it is extrapolation and give no point estimate beyond the data range unless asked, and then with a prominent caveat.

## Group comparisons

- Compare through a contrast with its own interval (see references/uncertainty-and-inference.md), not by eyeballing two bands.
- Say what is compared: whole expected responses (includes group intercept differences and other terms) or centred smooth shapes only.
- With several comparisons or many x values, state whether intervals are pointwise or simultaneous, and over what set.
- "The data do not resolve a difference between ... at ..." rather than "no difference".

## Derivatives and turning points

- Derivative intervals from the standard tools are pointwise unless stated otherwise: a region where the interval excludes zero is "where the data suggest a non-zero slope", not a proven region of increase.
- A spline can show local decreases or plateaus that are not supported by data; no monotonicity constraint is imposed unless a shape-constrained model (`scam`, `scasm`) was used.
- For peaks and thresholds, use posterior simulation of the curve (draws), compute the quantity per draw, and report its distribution; do not read the maximum off the point estimate alone.

## Model-level statements

- edf: "the term uses about [edf] effective degrees of freedom" (not "[edf] bends").
- Deviance explained / R-sq: descriptive of fit to this dataset; does not validate the shape.
- Model comparison by AIC or REML: "AIC favours ... by [Δ]; AIC with smoothing-parameter uncertainty is approximate".

## Limitations paragraph (adapt)

> Smooth shapes are penalized estimates conditional on the chosen basis dimension and estimated smoothing parameters. Intervals are approximate Bayesian credible intervals with across-the-function rather than pointwise frequentist coverage, and (unless noted) do not account for smoothing-parameter uncertainty. Results in regions with few observations are weakly supported. [Dependence / concurvity / unmodelled grouping] remain concerns because [..]. Associations should not be read as causal.

## Pre-send checklist

- Every claim names the scale and what is held fixed.
- No "significant" without specifying the test and what it tests.
- No "no effect" where only "inconclusive" is supported.
- Intervals labelled (pointwise/simultaneous; link/response).
- Sparse regions flagged.
- Remaining model problems stated.
- No causal wording unless justified.
