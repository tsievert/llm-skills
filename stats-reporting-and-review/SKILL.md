---
name: stats-reporting-and-review
description: Cross-cutting reporting layer that sits downstream of a fitted model or planned study - standardized effect sizes and CIs (effectsize), power/sample-size analysis (pwr for closed-form designs, simr for GLMMs), pre-registration documents (prereg templates), multiple-comparison correction (p.adjust, emmeans adjust), and drafting a point-by-point reviewer response. Use when the user asks for an effect size, Cohen's d, eta squared, a standardized estimate, power analysis, sample size calculation, a pre-registration document, multiplicity/multiple-testing correction across several tests or outcomes, or help drafting a response to reviewers. Does not fit or diagnose models (use mixed-models-glmm or gam-mgcv/gam-interpretation first) and never hands the user report()'s auto-generated prose as finished manuscript text (manuscript-writing-quarto owns the document).
metadata:
  version: "1.0"
---

# Statistical reporting and review support

A cross-model-type layer: effect sizes and CIs, power/sample size, pre-registration, multiplicity, and
reviewer-response drafting. It assumes a model is already fit (or a study already designed) and does not
re-claim that work.

**Standing rule — `report()` output is a scaffold, never finished text.** `report::report()` auto-writes
APA-style sentences from a fitted model. Use it only as a numbers-and-template starting point the user edits
line by line; never paste its paragraph into a manuscript as-is, and say explicitly that it needs a check of
framing, causal language and context. This mirrors `manuscript-writing-quarto`'s "no autonomous prose" rule —
that skill owns the document; this skill only produces the underlying numbers.

## Workflow

1. **Effect sizes and CIs** — see [references/effect-sizes.md](references/effect-sizes.md). Use `effectsize`
   to compute a standardized effect size with a CI directly from the fitted model (`lm`, `aov`, `glm`,
   `lmerMod`/`glmmTMB`, `htest`) rather than re-deriving one by hand from a test statistic. State the estimate
   and its CI, not just a significance label — the same principle `gam-interpretation` already applies to
   smooth terms, which have no single effect-size number the way a parametric term does.
2. **Power / sample size**, only when the user asks before or after data collection — see
   [references/power-analysis.md](references/power-analysis.md). `pwr` for closed-form designs (t-test, ANOVA,
   chi-square, correlation, proportions); `simr::powerSim()`/`powerCurve()` for GLMMs, which requires an
   `lme4`, not `glmmTMB`, fit — flag that refitting seam to the user rather than silently picking one.
3. **Pre-registration**, if the user wants to lock in a plan before analysis — see
   [references/preregistration.md](references/preregistration.md). Use the `prereg` package's R Markdown
   templates (COS Preregistration Challenge, AsPredicted, van 't Veer & Giner-Sorolla, Brandt Replication
   Recipe, PRP-QUANT); these render to PDF and need pandoc + a TeX distribution (`tinytex::install_tinytex()`
   is the lightweight option).
4. **Multiplicity**, whenever several tests, contrasts, or outcome variables are reported together — see
   [references/multiplicity.md](references/multiplicity.md). `stats::p.adjust()` across a family of
   tests/outcomes; `emmeans(..., adjust = )` within a family of pairwise contrasts (already the convention in
   `mixed-models-glmm`). State the decision rule (family-wise vs. FDR) rather than defaulting silently.
5. **Reviewer-response drafting**, if asked — see [references/reviewer-response.md](references/reviewer-response.md).
   A point-by-point structure and tone guidance, not an automated tool; every substantive response is the
   user's own argument, drafted for their edit.

## What this does not own

- Fitting or diagnosing a mixed model: `mixed-models-glmm`.
- Fitting, checking, or choosing `k`/family for a GAM: `gam-mgcv`.
- Plotting or interpreting a fitted GAM's smooths (including wording for edf, simultaneous intervals, or
  difference curves): `gam-interpretation`.
- Structuring the manuscript document itself, CRediT statements, or spelling/grammar/bibliography linting:
  `manuscript-writing-quarto`.
- Pseudoreplication / unit-of-replication design decisions (as opposed to the p-value correction layer once
  tests are run): `mixed-models-glmm` step 1.

## Known gaps (not yet tested)

- `effectsize`/`report` were tested here on `lm`/`aov` objects only; behaviour on `glmmTMB` objects (as
  produced by `mixed-models-glmm`) and on `gam` objects (parametric terms only — smooths have no single
  effect-size number) is documented upstream but not run locally.
- `simr` was not run locally this round; it requires an `lme4::lmer`/`glmer` fit, so a `glmmTMB` model from
  `mixed-models-glmm` needs refitting for the power step only (see the reference file for why).
- `prereg`'s PDF templates need a working LaTeX installation; not tested end-to-end on this machine.
- `preregr` (a different, R-native (pre)registration package considered during research) was archived from
  CRAN in 2026-07-28 — do not recommend it; `prereg` is the maintained alternative used here.
- No tool was found for reviewer-response drafting; the reference file is guidance, not a package wrapper.

## Related skills

- `mixed-models-glmm`: fits and diagnoses the GLMM/LMM this skill reports effect sizes and power for.
- `gam-mgcv` / `gam-interpretation`: fits, diagnoses, plots and interprets GAMs; smooth-term wording
  (including edf and simultaneous-interval conventions) stays in `gam-interpretation`, not duplicated here.
- `manuscript-writing-quarto`: structures the manuscript document, CRediT statement, and linting; this skill
  only supplies numbers and scaffolded text it reviews, never finished prose.
- `openalex`: literature context for discussing effect sizes or power against prior studies.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly
why things were done or not done: why an effect size came from `effectsize` rather than a hand calculation,
why a power analysis needed a refit in `lme4` instead of the user's `glmmTMB` model, why a `report()` sentence
is offered as a draft rather than final text, why a multiplicity correction was family-wise or FDR, and which
assumptions were made. Keep each explanation to a sentence or two and point to the relevant reference file for
depth.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects
it, a package version or API differs from what it states, or it lacks guidance the task needs, record a
generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it
when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are
hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
