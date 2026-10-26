# Multiple-comparison correction

No package gap here: base R and `emmeans` already cover this. The decision that matters is which correction,
not which function.

## Within a family of post hoc contrasts

`emmeans` already adjusts within a family of pairwise contrasts, defaulting to Tukey:

```r
pairs(emmeans(m, ~ group))                       # Tukey by default
pairs(emmeans(m, ~ group), adjust = "fdr")        # Benjamini-Hochberg instead
```

This is the convention already used in `mixed-models-glmm` — do not re-derive it differently here.

## Across a family of separate tests or outcome variables

```r
p.adjust(p_values, method = "holm")   # or "bonferroni", "hochberg", "hommel", "BH"/"fdr", "BY"
```

## Decision rule (state it, don't default silently)

- **Family-wise control** (Bonferroni, Holm, Hochberg, Hommel): appropriate when a single false positive
  anywhere in the family would be costly (e.g. a small set of pre-registered primary endpoints). Holm is
  uniformly more powerful than Bonferroni for the same guarantee — prefer Holm over plain Bonferroni unless a
  journal specifically asks for Bonferroni.
- **False discovery rate** (Benjamini-Hochberg "BH"/"fdr", Benjamini-Yekutieli "BY" for dependent tests):
  appropriate when screening many outcomes (e.g. many syllables, many genes, many ROIs) where some false
  positives are tolerable as long as most flagged results are real. This is standard practice in ecology when
  testing many species-by-predictor relationships.
- State the chosen method and the family it was applied over (which tests were grouped together) explicitly —
  an unstated correction family is as uninformative as no correction.

## Niche alternative

`FDRestimation::p.fdr()` computes an actual FDR estimate (distinct from a BH-adjusted p-value) and allows
assumptions `p.adjust()` fixes — worth knowing about for a reviewer who specifically asks for this
distinction, but not a default recommendation; not tested here.

## What this does not own

Pseudoreplication — whether rows are actually independent before any test is run — is a design question
owned by `mixed-models-glmm` (step 1, "identify the unit of replication"). This file only covers correcting
p-values across an already-correctly-specified family of tests.
