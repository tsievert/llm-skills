# Stats-reporting-and-review research ledger

Research for the planned `stats-reporting-and-review` skill (effect sizes/uncertainty, power/sample size,
pre-registration, reviewer-response drafting, pseudoreplication/multiple-testing checks, plus a GAM
results-prose convention). First research round; this one also checks for overlap with the just-researched
`manuscript-writing-quarto` skill and with the existing `gam-interpretation`/`mixed-models-glmm` skills, per
the user's request. Read this before searching again.

## 1. Requirements / triggering decisions

| # | Date | Decision | Source |
|---|---|---|---|
| R1 | 2026-10-24 | Original scope set in `AGENTS.md` todo table: effect sizes/uncertainty, power/sample size, pre-registration, reviewer-response drafting, pseudoreplication/multiple-testing checks | user |
| R2 | 2026-10-24 | GAM results-prose convention reported from one project's independent convention (edf bucketed into near-zero/negligible/weak/moderate/pronounced, edf framed as wiggliness not effect size, significant time-window + peak response-scale difference for simultaneous-CI difference curves, never mixing link-scale CIs with response-scale estimates, flag uncorrected multiplicity across narrated contrast curves) — open question whether it lives here or folds into `gam-interpretation` | `AGENTS.md` todo row |
| R3 | 2026-10-26 | User asked explicitly to research this skill for overlap with `manuscript-writing-quarto` and for tools that could benefit both | user (this turn) |

## 2. Sources (status)

| Source | What it covers | Status |
|---|---|---|
| https://easystats.github.io/effectsize/ (CRAN `effectsize`) | Standardized effect sizes (Cohen's d/g, eta²/omega²/epsilon², odds ratios, correlations) with CIs via the noncentrality-parameter method; conversions between test statistics (t/F/chisq/z) and effect sizes; works across `aov`, `lm`, `glm`, mixed models | read (vignette, CRAN PDF, JOSS paper excerpt) |
| https://easystats.github.io/report/ (CRAN `report`) | `report()` generic auto-generates APA-style prose paragraphs describing a fitted model (lm, glm, merMod/glmmTMB, htest, aov, brms, stanreg, survival, lavaan...), plus `report_participants()`, `report_effectsize()`, `report_performance()`, `report_sample()`, an `audience = "ai"` compact mode | read (README, r-universe page, getting-started article, DESCRIPTION) |
| https://easystats.github.io/parameters/, `performance`, `insight` | Backing packages `report`/`effectsize` depend on (model-parameter tables, ICC/R2/diagnostics, model introspection) — already in use by `mixed-models-glmm` (`performance::icc()`) | read (dependency lists only, not separately fetched) |
| https://cran.csiro.au/web/packages/EasyStat/EasyStat.pdf | Newer (2026), less-established CRAN package, narrower scope than easystats (t-test/ANOVA/regression/correlation only), outputs to Word via flextable/officer | search excerpt, not evaluated for maturity/citations |
| `pwr` (CRAN, base reference) | Closed-form power/sample-size for t-tests, ANOVA, chi-square, correlation, proportions; solves for any one of {n, effect size, sig.level, power} | read (tutorial + rdrr.io overview) |
| `WebPower` (CRAN) | Broader closed-form power analysis (mentioned alongside pwr/simr in tutorials) for designs pwr doesn't cover | search excerpt only, not fetched directly |
| `simr` (CRAN, Green & MacLeod 2016, Methods in Ecology and Evolution) | Simulation-based power analysis for GLMMs fit with `lme4`: `powerSim()`, `powerCurve()`, `extend()` to project required sample size by adding levels/observations | read (CRAN PDF, paper abstract, tutorial, worked clinical-trial SAP example) |
| `glmmrBase`/`glmmr` packages (arXiv 2303.12657) | Analytic (information-matrix) power calculation for GLMMs/cluster-randomized designs as an alternative to `simr`'s simulation approach; notes "eight different R packages... for calculating cluster trial power" | search excerpt (arXiv abstract/methods only) |
| `preregr` (CRAN/GitLab, rOpenSci-adjacent) | R-native (pre)registration specification: `prereg_initialize()` against a bundled form (OSF Prereg, PRP-QUANT, qualitative, secondary-data-analysis, systematic-review templates), `prereg_specify()`, export to R Markdown/HTML/JSON, human- and machine-readable | read (CRAN page, package docs site, two form vignettes) |
| OSF registration forms wiki (osf.io/zab38) | Canonical OSF Prereg form plus existing R Markdown templates by Frederik Aust and James Bartlett (non-package, just `.Rmd` templates) | search excerpt |
| CRAN `stats::p.adjust` | Base-R multiple-comparison correction: bonferroni, holm, hochberg, hommel, BH/fdr, BY; already the method named in `mixed-models-glmm`'s multiplicity step | read (rdocumentation reference) |
| `FDRestimation` (CRAN, arXiv 2010.04680) | Distinguishes FDR *estimation* from `p.adjust`'s BH-adjusted p-values; adds plotting and assumption flexibility `p.adjust` doesn't expose | search excerpt |
| `sgof` (CRAN, Carvajal-Rodríguez et al. 2009; de Uña-Álvarez 2011/2014/2015) | Alternative multiplicity method (SGoF) with higher power than BH under some conditions — niche, not evaluated for fit with this user's ecology/behaviour work | search excerpt only |
| `emmeans`/Tukey-vs-FDR discussion (benwhalley.github.io "Just Enough R") | Practical worked example contrasting Tukey-family correction (default in `emmeans`/`lsmeans`) with FDR (`adjust = "fdr"`) for pairwise contrasts | read (excerpt) |
| `mixed-models-glmm/SKILL.md`, `gam-interpretation/SKILL.md` (this repo) | Existing skill content and boundaries, read in full to check for duplication | read in full |

## 3. Facts

### Effect sizes / uncertainty — direct overlap with existing skills, strong reuse candidate
- `effectsize` (easystats) computes standardized effect sizes with CIs directly from fitted model objects
  rather than requiring manual entry of test statistics: (cite index="51-4">both MOTE and MBESS... require manual input of F- or t-statistics, degrees of freedom, and sums of squares for the computation the effect sizes, whereas effectsize can automatically extract this information from the provided models</cite>. It
  already lists `lme4`, `lmerTest`, `mgcv`, `emmeans`, `car`, and `pwr` as `Suggests` dependencies — i.e. it is
  designed to sit downstream of exactly the model objects `mixed-models-glmm` and `gam-mgcv` produce.
- A CI on an effect size is presented as the richer complement to a p-value: (cite index="50-5,50-6">Confidence intervals on measures of effect size convey all the information in a hypothesis test ... The 100 (1 - α)% confidence interval contains all of the parameter values for which p > α for the current data and model.</cite> This is the same stance `gam-interpretation`'s reporting checklist already takes for smooth terms (state the estimate, uncertainty, and scale) — a shared principle, not a shared function, since GAM smooths have no single effect-size number the way a parametric term does.
- **Overlap / hand-off risk**: `effectsize` and `report` both operate on `glmmTMB`/`lme4` objects, exactly the
  objects `mixed-models-glmm` fits. If `stats-reporting-and-review` is written to also cover "report a fitted
  mixed model's effect sizes," its description must not re-claim GLMM fitting/diagnosis verbs already owned
  by `mixed-models-glmm` (per `skill-boundaries.md` rule 1: "state the object and the verbs it owns"). The
  natural split: `mixed-models-glmm` fits, diagnoses, and reports *in its own reporting checklist* (already
  present, line "7. Report:..." in its SKILL.md); `stats-reporting-and-review` would own the *cross-cutting*
  effect-size/CI vocabulary and conventions that apply after any model (GLMM, GAM parametric term, t-test) is
  fit, not a second copy of how to fit one.

### `report()` — direct tension with `manuscript-writing-quarto`'s "no autonomous prose" caveat
- `report::report()` is explicitly designed to write manuscript-ready sentences, not just numbers: (cite index="88-1,88-6">The aim of the report package is to bridge the gap between R's output and the formatted results contained in your manuscript... It automatically produces reports of models and data frames according to best practices guidelines (e.g., APA's style)</cite>. Its own worked example
  for a mixed model (cite index="92-17,92-20,92-21">We fitted a linear mixed model (estimated using REML and nloptwrap optimizer) to predict Reaction with Days ... The model's intercept, corresponding to Days = 0, is at 251.41 (95% CI [237.94, 264.87], t(174) = 36.84, p < .001). ... The effect of Days is statistically significant and positive</cite> is literally
  manuscript Results-section prose, auto-written from the model object.
- This is a direct conflict with the `manuscript-writing-quarto` scope decision "no autonomous prose" (R1 in
  that skill's ledger). **Recommendation for when both skills are written**: `stats-reporting-and-review` can
  use `report()`/`effectsize()` output as a *numbers-and-template scaffold* that the user reviews and edits
  line-by-line (consistent with this repo's existing stance in `gam-interpretation`, which hand-writes
  calibrated phrasing rather than templating it) — but should not hand the user `report()`'s full paragraph as
  if it were finished Results text, and should say explicitly that the sentence is machine-generated and
  needs the user's own check of framing, causal language, and context. `manuscript-writing-quarto` should
  likewise flag `report()` output as something to route through the "linting/proofreading only" stance rather
  than paste verbatim. This boundary should be written into both skills' bodies (not just the YAML
  description) once drafted, and is the single clearest cross-skill finding of this round.
- A newer, less-established alternative was found: `EasyStat` (CRAN, 2026, two academic authors, no citation
  history yet) — similar auto-narrative idea but narrower (t-test/ANOVA/regression/correlation only) and
  exports to Word via flextable/officer. Not recommended over `report`/easystats given the latter's maturity
  (rOpenSci-adjacent ecosystem, JOSS paper, used across `effectsize`/`parameters`/`performance`), but worth a
  one-line mention if the user specifically wants direct Word-table output.

### Power / sample size
- No single tool covers every design; the practical hierarchy found across sources is: closed-form `pwr` for
  t-tests/ANOVA/chi-square/correlation (cite index="68-16,68-17,68-18">No. pwr covers a fixed set of closed-form tests. For mixed models, factorial ANOVA, and clustered designs, use simr::powerSim() or Superpower to simula[te]</cite>; `WebPower` for a wider closed-form set;
  simulation-based `simr` for GLMMs built on `lme4` — (cite index="64-5,64-6">The r package simr allows users to calculate power for generalized linear mixed models from the lme4 package. The power calculations are based on Monte Carlo simulations.</cite> `simr::powerCurve()` can project the sample size needed by
  extending a pilot model: (cite index="64-9,64-10">When data collection is costly, the user might want to collect only as much data as are needed to achieve a certain level of statistical power. The powerCurve function in simr can be used to explore trade-offs between sample size and power.</cite>
- **Overlap**: `simr` operates on `lme4::lmer`/`glmer` fits specifically (not `glmmTMB`), while
  `mixed-models-glmm`'s default stack is `glmmTMB`. A power-analysis sub-scope would need either (a) refitting
  a pilot model in `lme4` for the power step only, or (b) using the analytic `glmmrBase` alternative, which
  works from a model specification rather than a fitted `lme4` object. This is a real seam to flag to the user
  when the skill is written, not silently choose one.
- Published study protocols already treat `simr` as the standard tool for GLMM power in applied/clinical
  work: (cite index="65-3,65-4">We calculated the power and sample size using the simr package from R version 4.0.3 for the Poisson mixed-effects model with random intercepts. We used our pilot data from 117 substance users... and an effect size of 0.31... as an estimate of the effect size we will observe in a new study.</cite> — a reasonable worked-example precedent for a priori power write-ups.

### Pre-registration
- `preregr` is an R-native way to fill a (pre)registration form (OSF Prereg, PRP-QUANT, qualitative,
  secondary-data-analysis, systematic-review templates are bundled) and export it machine- and
  human-readably: (cite index="75-1">The preregr package facilitates specifying (pre)registrations in R and exporting them to a human-readable format (using R Markdown partials or exporting to an HTML file) as well as human-readable embedded data (using JSON)</cite>. It can also generate an R Markdown
  scaffold from a chosen form: (cite index="76-3,76-4,76-5">These templates are basically prestructured R Markdown files. This means the user (i.e. you) will only have to add in the (pre)registration content, knitr it, and you have a human- and machine-readable (pre)registration.</cite>
- This is a genuine point of overlap with `manuscript-writing-quarto`'s Quarto-authoring territory: a
  pre-registration document is itself a small manuscript-like artifact. Division of labour if both skills
  exist: `stats-reporting-and-review` would own the *content decisions* (what to pre-specify: primary
  endpoint, planned model, stopping rule, planned corrections for multiplicity), `manuscript-writing-quarto`
  would own turning any resulting document into a rendered `.qmd`/PDF if the user wants it in that format
  (`preregr::form_to_rmd_template()` already targets R Markdown, not Quarto directly — would need checking
  whether it also emits usable `.qmd` YAML, or whether the skill just adapts the Rmd template by hand).
  Not yet checked live.
- The CRAN page flags unresolved CRAN check issues as of the page read: (cite index="73-3">CRAN checks: preregr results [issues need fixing before 2026-07-14]</cite> — worth a live re-check of package health before recommending it in the actual skill.

### Pseudoreplication / multiple-testing
- No gap found: `stats::p.adjust()` is base R and already the method named in `mixed-models-glmm` step 7
  ("Multiplicity"). (cite index="79-7,79-8,79-9">The adjustment methods include the Bonferroni correction ("bonferroni")... Less conservative corrections are also included by Holm (1979) ("holm"), Hochberg (1988) ("hochberg"), Hommel (1988) ("hommel"), Benjamini & Hochberg (1995) ("BH" or its alias "fdr"), and Benjamini & Yekutieli (2001) ("BY")</cite>. `emmeans`'s own
  `adjust = "fdr"` argument already covers correcting a family of post hoc contrasts, which
  `mixed-models-glmm` also already mentions (Tukey default). FDR vs. family-wise framing is worth restating as
  a decision rule rather than new code: (cite index="80-8">Bonferroni is strict, Benjamini-Hochberg balances discovery with error, and Storey's q-value squeezes out more power when real signals are plentiful.</cite>
- A specialized niche tool, `FDRestimation`, was found that computes an actual FDR estimate (distinct from a
  BH-adjusted p-value): (cite index="81-7,81-10,81-11">stats::p.adjust actually reports the adjusted p-values for FDR control, and these are not always the same thing... The stats package function stats::p.adjust is similar in that it will produce multiple-comparison adjusted p-values. However, stats::p.adjust returns the BH adjusted p-value[s]... FDRestimation::p.fdr function allows adjustments of key assumptions that are not adjustable in the stats::p.adjust implementation</cite> — a genuinely new (if niche) tool for the skill to know about, not yet in any
  existing skill here. Ecology-specific prior art exists too: (cite index="82-1,82-2,82-7,82-8">It is common in ecology to search for statistical relationships between species' occurrence and a set of predictor variables. However, when a large number of variables is analysed... false findings may arise due to repeated testing... Garcia (2003) recommended controlling the false discovery rate (FDR; Benjamini & Hochberg 1995) in ecological studies.</cite> matching this
  user's field. Pseudoreplication itself (the design side, not the p-value-correction side) is already owned
  by `mixed-models-glmm` step 1 ("Identify the unit of replication") — `stats-reporting-and-review` should not
  re-claim that, only the multiplicity/correction-method layer across *any* set of tests, including t-tests,
  ANOVAs, and multiple outcome variables, not just GLMM contrasts.

### GAM results-prose convention (R2)
- No new tool surfaced for this sub-item this round; it is a wording/convention decision, not a package gap.
  `gam-interpretation`'s existing "Interpretation rules" section (edf described as "a measure of fitted
  flexibility under the penalty, not a count of turning points or a significance measure") already overlaps
  substantially with the reported independent convention (edf framed as wiggliness, not effect size). The
  specific buckets (near-zero/negligible/weak/moderate/pronounced) and the simultaneous-CI
  significant-time-window-plus-peak-response-scale-difference convention are additions, not contradictions.
  **This strengthens the case to fold R2 into `gam-interpretation` rather than host it in
  `stats-reporting-and-review`**, since it is GAM-specific wording applied at the point a smooth is already
  being interpreted, not a cross-model-type reporting principle — but this is a judgement call for whoever
  writes the skill, not settled here.

## 4. Candidate skill shape (not yet built, for discussion)

- **Effect sizes/CIs**: wrap `effectsize`/`parameters` for parametric effect sizes and CIs; explicitly state
  "report the estimate and its CI, not just a significance label" as the cross-cutting principle (echoing
  `gam-interpretation`'s existing stance for smooths). Hand off model-fitting/diagnosis to `mixed-models-glmm`
  and `gam-mgcv`/`gam-interpretation`.
- **`report()`/narrative scaffolding**: use as a draft scaffold only, always flagged as machine-generated and
  requiring the user's edit — the single sharpest boundary line against `manuscript-writing-quarto`'s
  "no autonomous prose" rule. This should be written once, referenced (not copied) by both skills' bodies.
- **Power/sample size**: `pwr` for closed-form designs, `simr` for GLMMs via `lme4` (flag the `glmmTMB`
  seam), mention `WebPower`/`glmmrBase` as alternatives without full evaluation yet.
- **Pre-registration**: `preregr` as the candidate tool; re-verify its CRAN check health and whether its
  Rmd-template export is adaptable to Quarto before recommending; define the content/format split against
  `manuscript-writing-quarto` if both exist.
- **Multiplicity**: `stats::p.adjust()` plus `emmeans(..., adjust = ...)` as already used in
  `mixed-models-glmm`; mention `FDRestimation` as a specialized alternative; state the decision rule
  (family-wise vs FDR) rather than defaulting silently.
- **Reviewer-response drafting**: no tool found this round (likely a pure drafting/communication task, not an
  R-package gap) — flagged open below.
- **GAM results-prose convention**: recommend folding into `gam-interpretation` rather than duplicating here,
  pending the user's decision (per the open item already recorded in `AGENTS.md`).
- Boundary against `skill-boundaries.md` (not yet added there): must not re-claim GLMM/GAM fitting or
  diagnosis verbs; owns the cross-model-type effect-size/power/multiplicity/pre-registration layer and
  reviewer-response drafting, which no existing skill claims today.

## 5. Open research items

- Whether `preregr::form_to_rmd_template()` output is realistically adaptable to a `.qmd` file, or whether a
  pre-registration artifact should just stay plain R Markdown — not tested.
- `preregr`'s CRAN check status flagged "issues need fixing" at the page read; re-check before recommending.
- `WebPower` and `glmmrBase` were only seen in secondary sources (tutorial list, one arXiv abstract) — no
  direct package page read, no function-level evaluation.
- No tool or convention found yet for "reviewer-response drafting" specifically; this sub-item may end up
  being pure guidance (tone, structure, point-by-point response template) rather than anything R-based —
  worth deciding explicitly when the skill is scoped, including whether it belongs here at all or is closer
  to `manuscript-writing-quarto`'s territory (a response letter is itself a short document).
- `FDRestimation` and `sgof` were found but not tested; no judgement yet on whether either is worth
  recommending over plain `p.adjust()` for this user's typical ecology/behaviour sample sizes.
- Did not check whether `effectsize`/`report` have any known rough edges with `glmmTMB` objects specifically
  (vs. `lme4`/`merMod`, which the documentation examples all use) — `report`'s DESCRIPTION lists `glmmTMB` in
  `Suggests` and the r-universe export list includes `report.glmmTMB`-adjacent methods implicitly via
  `insight`, but this was not run locally.

## 6. Log

- 2026-10-26: Round 1 (this file created), run at the user's explicit request to also check overlap with
  `manuscript-writing-quarto` and shared tooling. Five web searches (effect-size/easystats tooling, power
  analysis for mixed models, pre-registration R packages, multiple-comparison correction in R/ecology,
  easystats `report` package) plus a full re-read of the existing `gam-interpretation` and `mixed-models-glmm`
  SKILL.md files to check for duplication. Key cross-skill finding: `report()`'s auto-generated prose
  directly conflicts with `manuscript-writing-quarto`'s "no autonomous prose" caveat and needs an explicit,
  shared boundary statement when both skills are drafted. No local tests, no skill files written.
