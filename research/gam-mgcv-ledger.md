# gam-mgcv research ledger

Generic wording only (public repo). Created 2026-11-17 for maintenance review task 7. Append new rounds as dated sections.

## Section index

1. Requirements
2. Round 2026-11-17: baseline covariates in marginal GAMs (sources, facts, gaps, proposal)
3. Open research items
4. Log

## 1. Requirements

| # | Requirement | Date |
|---|---|---|
| R1 | Research before any skill text; OpenAlex for the literature (standing rule), mgcv/gratia docs for the software. | 2026-11-17 |
| R2 | Questions: baseline as covariate vs change score; `s(time, by = baseline)`; repeated or noisy baselines; standardising group-mean predictions; leave-animals-out CV. | 2026-11-17 |
| R3 | Outcome: decide whether a short reference section is justified; default is park (one report, confidence low). | 2026-11-17 |

## 2. Round 2026-11-17: baseline covariates in marginal GAMs

Route: OpenAlex via httr2 with the key passed explicitly (MCP tools not in this session). Searches used `title.search` with one
parenthesised boolean expression (loose `title_and_abstract.search` returned unrelated clinical papers). Hit lists are noisy; only
rows below were kept. Only abstracts (reconstructed from the inverted index) were read, not full texts.

### Sources

| Source | Status | Relevance |
|---|---|---|
| Vickers & Altman 2001, BMJ, [10.1136/bmj.323.7321.1123](https://doi.org/10.1136/bmj.323.7321.1123) (W2061623382) | partial (abstract opening only) | Compares follow-up score, change score, ANCOVA for trials with baseline; standard citation for "adjust, do not difference". |
| Senn 2006, Stat Med, [10.1002/sim.2682](https://doi.org/10.1002/sim.2682) (W2060873901) | partial (abstract) | ANCOVA unbiased for the treatment effect without equal baselines; change-score analysis is rarely unbiased where ANCOVA is biased. Linear setting. |
| van Breukelen 2006, J Clin Epidemiol, [10.1016/j.jclinepi.2006.02.007](https://doi.org/10.1016/j.jclinepi.2006.02.007) (W2159684207) | partial (title only, no abstract in OpenAlex) | Title: ANCOVA has more power in randomized studies, more bias in nonrandomized ones. |
| Egbewale et al. 2014, BMC Med Res Methodol, [10.1186/1471-2288-14-49](https://doi.org/10.1186/1471-2288-14-49) (W2020480331) | partial (abstract) | Simulation: ANOVA, change score, ANCOVA under baseline imbalance; Gaussian. |
| Kahan & Jairath 2014, Trials, [10.1186/1745-6215-15-139](https://doi.org/10.1186/1745-6215-15-139) (W2166091513) | partial (abstract) | Adjusting for prognostic covariates raised power (median 80 to 92.6 percent in the simulation); also assesses non-prognostic covariates. |
| Pocock & Assmann 2002, Stat Med, [10.1002/sim.1296](https://doi.org/10.1002/sim.1296) (W2035655846) | partial (abstract) | Reporting practice for covariate adjustment and baseline comparisons. Context only. |
| White & Thompson 2004, Stat Med, [10.1002/sim.1981](https://doi.org/10.1002/sim.1981) (W1983722797) | partial (abstract) | Partly missing baselines: deterministic mean imputation or joint modelling; not about noisy baselines. |
| Chan & Macaskill 2004, Control Clin Trials, [10.1016/j.cct.2004.06.001](https://doi.org/10.1016/j.cct.2004.06.001) (W1986949593) | title only | Title: adjusting for baseline measurement error induces bias. Not read; the noisy-baseline claim is unverified. |
| Lydersen 2022, Tidsskr Nor Legeforen, [10.4045/tidsskr.21.0824](https://doi.org/10.4045/tidsskr.21.0824) (W4223551150) | skipped: not read (Norwegian, short note) | Longitudinal randomised trials with baseline adjustment; possible lead for repeated outcomes. |
| mgcv help `?linear.functional.terms` (mgcv 1.9-5 in the session; `by` and matrix-argument smooths) | read (first 45 lines) | Matrix covariates in `s()`/`te()` give summation terms, so a functional baseline (curve) can enter a bam. |
| gratia, `?gratia::data_slice`, `?gratia::fitted_values` | not researched | Needed for standardised (averaged over observed baselines) predictions. |
| Searches for marginal standardisation, g-computation, collapsibility, functional covariates in GAMs | search, no usable hit | Hits were unrelated (spirometry, causal-inference books, one scalar-on-function paper, Selecting the derivative..., 2022, not read). |

### Facts supported so far

- For randomised comparisons with one pre-treatment measurement of a continuous outcome, entering the baseline as a covariate
  (ANCOVA) is preferred to the change score or the follow-up score alone, on power and bias grounds (Vickers & Altman 2001;
  Senn 2006; Kahan & Jairath 2014; van Breukelen 2006 by title). All of this is Gaussian or linear-model work.
- Adjustment only targets contrasts of factors assigned after the baseline measurement; for a factor that was not randomised
  or that predates the baseline, ANCOVA can be biased (van Breukelen title; Senn 2006 abstract). The gam-mgcv wording
  "adjust only contrasts of factors assigned after baseline" is therefore consistent with the literature as far as read.
- mgcv can carry a baseline as a smooth, a varying coefficient (`s(time, by = baseline)`, numeric `by`), or a curve covariate through matrix terms
  (software doc, not a statistical recommendation).

### Not supported by anything found (do not put in a skill as fact)

- That a log-link Gamma bam should use the log baseline: plausible (multiplicative scale), but no source found; the
  mgcv/log-link covariate-averaging bullet already in gam-interpretation is the only related text.
- That a noisy single-session baseline should be averaged or shrunk: general regression-to-the-mean reasoning; the one
  relevant paper (Chan & Macaskill) was read by title only, and its direction (bias from adjustment) may cut the other way.
- `s(time, by = baseline)` versus a constant baseline slope: no literature found; choose by AIC/REML or leave-animals-out CV,
  which is a design choice, not a result.
- Standardising group-mean predictions over observed baselines: standard g-computation idea; no source read in this round.
- Leave-animals-out CV as the comparison for baseline variants: sensible for clustered data, no source read.

### Proposal (not applied; for the user's decision)

Do not add a gam-mgcv section yet. Evidence is a single report (confidence low), the literature is linear/Gaussian RCT work, and
the log-link, noisy-baseline and standardisation items have no source. Options:

1. Park (default): keep the entry parked, point to this ledger.
2. Add a 6-8 line note to `gam-mgcv/references/` ("Baseline covariates") with only the supported facts above, each labelled as
   extrapolated from linear-model trials, plus the software options and the "re-labelling must recompute the baseline" pointer that
   already exists in `ncv-and-bam-notes.md`. Everything unsupported would be framed as "choose by CV, not assumed".

## 3. Open research items

| # | Item | Status |
|---|---|---|
| O1 | Read full texts of Vickers & Altman, Senn, Chan & Macaskill (use `openalex/scripts/fetch_fulltext.R`; ask the user first, metered). | open |
| O2 | Nonlinear/GLM baseline adjustment (noncollapsibility, marginal standardisation): search for covariate adjustment with GLMs in randomised trials, for example regulator guidance on covariate adjustment. | open |
| O3 | Baseline in repeated-measures / longitudinal outcomes (ANCOVA with a time-varying treatment effect; Frison & Pocock style); Lydersen 2022 as a lead. | open |
| O4 | `?gratia::data_slice` and fitted-value averaging for standardised predictions; a small synthetic bam test of `s(time, by = baseline)`. | open |
| O5 | OpenAlex MCP tools were not available this session; the R path needed an explicit key. | noted |

## 4. Log

- 2026-11-17: ledger created. Ran 11 OpenAlex title searches plus one abstract search and one ID batch fetch (9 works); read the mgcv
  linear.functional.terms help. No skill files edited. Findings: literature supports baseline-as-covariate in linear RCT settings; the
  GAM-specific, log-link, noisy-baseline and standardisation items remain unsourced.

## 5. Round 2026-11-17 (task 8): GAM band-calibration simulation, new-skill suggestion

Decision recorded 2026-11-17 (task 7): the baseline-covariate entry stays parked; no gam-mgcv text added.

### Existing coverage in the repo (grep, 2026-11-17)

| Where | What it already says |
|---|---|
| `gam-mgcv/references/ncv-and-bam-notes.md` | Count and report failed fits in simulations; memory budget per worker, retry once, keep error text per seed; cluster-robust vs bootstrap coverage caution (one design); pilot of 9 data sets overstated calibration, report Monte Carlo SE, avoid conclusions under about 30 replicates. |
| `gam-mgcv/references/model-comparison.md` | Bootstrap max-t bands: B, critical value, nested studentised bands; do not read a nested coverage check as proof of miscalibration. |
| `gam-interpretation/references/uncertainty-and-inference.md` | Across-the-function vs simultaneous coverage; Marra and Wood (2012). |
| `stats-reporting-and-review/SKILL.md` | Power by simulation with `simr` (lme4 fits only). Different goal (power, not band coverage). |

Not covered: the generator-with-closed-form-truth design, replicate driver with per-replicate saved results and resumable seeds, and a pooled-summary template. That is a workflow of roughly one reference page, not a skill: it would only be used with gam-mgcv fits and shares description territory with gam-mgcv/gam-interpretation (clash risk).

### Sources

| Source | Status | Relevance |
|---|---|---|
| Morris, White & Crowther 2019, Stat Med, [10.1002/sim.8086](https://doi.org/10.1002/sim.8086) (W2775363893) | partial (title, citation count; not read) | Standard tutorial for simulation studies (planning, performance measures, Monte Carlo error); lead for an ADEMP-style checklist. |
| Burton et al. 2006, Stat Med, [10.1002/sim.2673](https://doi.org/10.1002/sim.2673) (W2095967516) | partial (title only) | Design of simulation studies in medical statistics. |
| Monks et al. 2019 (STRESS), J Simulation, [10.1080/17477778.2018.1442155](https://doi.org/10.1080/17477778.2018.1442155) (W2792314241) | partial (title only) | Reporting guideline for simulation studies; operations-research flavour, weaker fit. |
| Inbox entry (single report, one project, confidence medium, generality unsure) | read | The suggestion itself. |

Searches with generic Monte Carlo terms returned unrelated engineering and risk papers (skipped: off-topic).

### Proposal (default applied: no new skill)

1. Do not create a skill: one report, ~one page of content, high clash risk with gam-mgcv and gam-interpretation.
2. Optional, if the user wants it: a short `gam-mgcv/references/coverage-simulation.md` with the existing bullets consolidated plus pointers to Morris et al. 2019 (read the full text first; O6) and the driver/seed/shard design. Consolidating would also remove the scatter across ncv-and-bam-notes.md and model-comparison.md.

### Open items

| # | Item | Status |
|---|---|---|
| O6 | Read Morris et al. 2019 in full (OA copy?) before citing its recommendations; check what it says on replicate counts and Monte Carlo SE. | open |
| O7 | Decide whether a consolidated coverage-simulation reference is worth it once a second report arrives. | open |

## 6. Round 2026-11-17 (task 8 follow-up): Morris et al. 2019 read, coverage-simulation reference written

Source status update: Morris, White & Crowther 2019, Stat Med 38:2074-2102, [10.1002/sim.8086](https://doi.org/10.1002/sim.8086) (W2775363893): **read**
(Europe PMC XML PMC6492164 via `fetch_epmc_xml()`; the PMC web page itself is behind a bot wall, the XML route worked). Sections used: ADEMP,
4.1 seeds and states, 4.1.1 streams, 3.x nonconvergence, 5.1 missing estimates, 5.2 Monte Carlo SE (Table 6), 5.3 choosing n_sim.
Extracted text jumbles sub/superscripts; formulas were cross-checked by arithmetic in R.

Facts used: n_sim = c(1-c)/SE_target^2 (1,900 for 95% coverage at 0.5 points; 10,000 worst case); MC SE of coverage sqrt(c(1-c)/n);
MC SE of empirical SE = EmpSE/sqrt(2(n-1)); set the seed once and store the state at the start of each repetition and at the end;
parallelising repetitions within one mechanism is inadvisable under one seed path; bias-eliminated coverage; coverage by tertile of
model SE; nonconvergence changes what "method" is evaluated; continue from the stored end state to add repetitions.
Checked here: `RNGkind("L'Ecuyer-CMRG")` plus `parallel::nextRNGStream()` gives distinct streams (not from the paper).

Changes: new `gam-mgcv/references/coverage-simulation.md`; scattered bullets in `ncv-and-bam-notes.md` replaced by pointers; one pointer in
`gam-mgcv/SKILL.md` "Reporting". The old "fewer than about 30 replicates" rule was replaced by "report the Monte Carlo SE" (no safe count).
Not done: Burton et al. 2006 and STRESS not read; driver-design bullets remain single-report. Checks: lint_skills, check_skill_links clean;
skills-ref validate gam-mgcv valid; check_skill_clashes not rerun (no description change). Open items O6 closed, O7 closed by this change.
