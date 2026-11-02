# Ledger: "population" terminology in model interpretation (gam-interpretation, gam-mgcv, mixed-models-glmm)

Started 2026-11-02 from a lessons-triage question (user-correction entry plus a user remark that the meaning can change a lot).

## Requirements

| # | Requirement | Date |
|---|---|---|
| R1 | Terminology confusion ("population-level", statistical vs ecological population) must be treated carefully in triage; it can change the meaning of results | 2026-11-02 |
| R2 | Source-quality rules apply (no commercial, no LLM-like, no US-tuned sources) | standing |

## Source table

| Source | Status | Finding |
|---|---|---|
| brms `brmsformula` reference, https://paulbuerkner.com/brms/reference/brmsformula.html | read | In brms, "population-level" (or "overall") effects are the fixed effects; "group-level" (varying) effects are the random effects. So "population-level" can mean fixed effects, not a marginal mean over units. |
| Muff et al. 2016, Methods Ecol Evol, doi 10.1111/2041-210x.12623 (abstract via OpenAlex) | partial (abstract only) | Conditional (GLMM) vs marginal (GEE) models differ in interpretation; marginal parameters are marginal only with respect to unaccounted cluster differences and depend on the fixed effects, so they should not be loosely read as population-averaged parameters; with non-normal outcomes no unambiguous marginal model exists in general. Ecology-oriented. |
| Ritz and Spiegelman 2004, Stat Sci, doi 10.1214/088342304000000305 "Conditional and Marginal Models: Another View" | search (title only) | Lead; not read |
| Subject-specific vs population-average tutorial, doi 10.14301/llcs.v4i2.249 | search (title only) | Lead; not read |
| Ecological sense of "population" (a group of interbreeding organisms in an area) | not researched | Needs a non-commercial textbook source before quoting |

## Facts (three senses of "population" seen in practice)

1. Statistical population: the target the estimate refers to; a "population-average" or marginal estimand averages over the distribution of units (animals), usually on the response scale.
2. Ecological/biological population: a real group of organisms (a strain, a colony, a wild population). A statistical population need not equal it: inference from a sample of animals refers to whatever those animals were drawn from.
3. Model-term usage: "population-level effects" = fixed effects (brms, also common in Bayesian and lme4 teaching). Group-level effects = random effects. This says nothing about marginalising over random effects.

Link to the lessons: one user-correction entry shows the assistant read "population-level differences" as sense 1 (marginal over animals) when the user meant group-level contrasts (strain, sex, treatment) of any kind.

## Open research items

- O1: Read Ritz and Spiegelman 2004 and the subject-specific vs population-average tutorial.
- O2: Non-commercial source for the ecological definition of population.
- O3: Check whether gratia/marginaleffects docs use "population" for a specific estimand.

## Log

- 2026-11-02: brms page fetched; OpenAlex search (two queries); Muff 2016 abstract read. Nothing recorded as secret.
