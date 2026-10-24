# llm-skills — Development History

Detailed, dated log of work on this repository: skills built, research done, decisions
made, bugs found and fixed, and what was and wasn't tested. Referenced from
[`AGENTS.md`](AGENTS.md) by a plain path mention (not an `@include`), so it is **not**
loaded into every conversation's context — read it on demand (resuming work on a skill,
checking what was already tried, or `grep`ping for a topic) rather than at session start.

Entries are append-only, in the order they were written (each is dated; the order is
mostly but not strictly chronological — a few research rounds were logged out of
sequence). Each entry starts with `- YYYY-MM-DD:`; search with
`grep -n "^- [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}" HISTORY.md` or use the index below to jump
to a topic by line number in your editor.

When adding an entry: append it here, not to `AGENTS.md`. Keep `AGENTS.md` itself to
current/active state (working rules, open decisions, the todo table).

## Index

1. 2026-10-23 — Sync approach chosen; repo empty of skills
2. 2026-10-23 — `openalex` skill copied in; first commit
3. 2026-10-23 — `scripts/sync-skills.sh` written and tested
4. 2026-10-23 — SessionStart hook + `skills.paths` verified live
5. 2026-10-23 — Added `hpc-cluster-docs`, `hpc-job-scripts`, `hpc-python-code`, `hpc-resource-allocation`
6. 2026-10-23 — Added `hpc-gpu-jobs`, `hpc-r-code`; arrays-and-scratch reference
7. 2026-10-23 — Added `deeplabcut-hpc`
8. 2026-10-23 — Added `gam-mgcv`
9. 2026-10-23 — Added `gam-mgcv` sz-smooths reference, verified live
10. 2026-10-23 — Added `gam-interpretation`
11. 2026-10-23 — Installed newer gratia; re-tested `gam-interpretation` claims
12. 2026-10-23 — Added `social-research-search`
13. 2026-10-23 — Added `animal-behaviour-tracking-analysis` v1 (keypoint-MoSeq)
14. 2026-10-23 — Added DLC basic metrics (v2) to `animal-behaviour-tracking-analysis`
15. 2026-10-23 — Installed `animovement` (R-universe); tested
16. 2026-10-23 — Installed `rhdf5`; animovement/`movement` h5 support tested
17. 2026-10-23 — Added statistical-analysis reference + `stats_demo.R`
18. 2026-10-23 — Added `mixed-models-glmm`
19. 2026-10-23 — Installed `rptR`; added pitfalls-and-reporting issues section
20. 2026-10-23 — Added `github-skill-maintenance`
21. 2026-10-23 — Added `data-repository-readme` (+ Dryad/Cornell/UBC/Borealis follow-ups)
22. 2026-10-23 — Added `manuscript-figures-ggplot` (+ CVD-palette follow-up)
23. 2026-10-23 — Added the lessons-learned feedback loop (`skill-lessons`, `skill-feedback-triage`)
24. 2026-10-23 — Added `job-opportunity-watch` (+ Step 4b social discovery)
25. 2026-10-23 — Cross-skill link audit; `check_skill_links.R`
26. 2026-10-23 — Lessons loop strengthened (use-case entries, `reminders.tsv`)
27. 2026-10-23 — First `skill-feedback-triage` run
28. 2026-10-23 — Skill clash audit; `check_skill_clashes.R` (+ proxy trigger test follow-up)
29. 2026-10-23 — Drafted `python-reproducible-pipeline`
30. 2026-10-23 — Research round 5 for `r-reproducible-pipeline`
31. 2026-10-23 — Added `r-reproducible-pipeline` (+ renv cache incident)
32. 2026-10-24 — Debugged a real skill undertrigger; widened `hpc-job-scripts`/`deeplabcut-hpc` descriptions
33. 2026-10-24 — Built `skill-file-signal-hook.sh` (R2)
34. 2026-10-24 — Built `codebase-map`
35. 2026-10-24 — uv/Python PATH-detection issue investigated
36. 2026-10-24 — Built `web-fetching-r`; refactored jobwatch/recipe-notes/social-search
37. 2026-10-24 — Third `skill-feedback-triage` run
38. 2026-10-23 — Commit audit; `uv.lock` gitignore fix
39. 2026-10-23 — Research round 1 for `reproducible-research-data` / `git-for-research-projects`
40. 2026-10-23 — Research round 2: user decisions recorded; Zenodo sandbox 403
41. 2026-10-23 — Research round 3: Zenodo sandbox test completed
42. 2026-10-23 — Built `git-for-research-projects`
43. 2026-10-23 — Built `reproducible-research-data`
44. 2026-10-23 — Aarhus Dataverse correction; institution-discovery step added
45. 2026-10-23 — Second `skill-feedback-triage` run
46. 2026-10-24 — Built `recipe-notes-formatter`
47. 2026-10-24 — Analysed conversation exports for skill-trigger behaviour; built `skill-trigger-hook.sh` (R1)
48. 2026-10-24 — Audited all skills for the subagent-delegation-rule candidate; added rule to `job-opportunity-watch`

## Entries

- 2026-10-23: Approach chosen (SessionStart hook + `git pull --ff-only`). Repo is
  currently empty of skills.
- 2026-10-23: `openalex` skill copied into the repo; first commit pushed to origin/main.
- 2026-10-23: `scripts/sync-skills.sh` written. Tested against a scratch bare repo with an
  isolated HOME: up to date, throttled, dirty tree (skip + warn), clean fast-forward, local
  ahead (skip + warn), offline (silent). All exit 0.
- 2026-10-23: SessionStart hook and `skills.paths` added to `~/.posit/assistant/settings.json`.
  Verified after RStudio restart: the state file below was created and `openalex` loaded from the repo path. Checked: `/openalex` resolved and
  `~/.posit/state/llm-skills-last-check` was created. Old copy of
  `~/.posit/assistant/skills/openalex` deleted (diffed identical to the repo copy first).
  Not yet observed: a live pull of a real upstream change (only tested in the scratch repo).
- 2026-10-23: Added four HPC skills: `hpc-cluster-docs`, `hpc-job-scripts` (with `scripts/check_sbatch.sh`
  linter), `hpc-python-code` (with `assets/hpc_skeleton.py`), `hpc-resource-allocation`. Linter tested
  on good/bad scripts; skeleton tested via `uv run` on Windows (fresh run, resume, rerun). Not tested:
  signal/requeue path (no SIGUSR1 on Windows) and anything on a real Slurm cluster.
- 2026-10-23: Added `hpc-gpu-jobs` and `hpc-r-code`; added races/node-local-scratch reference
  (`hpc-job-scripts/references/arrays-and-scratch.md`) with `assets/python-scratch-job.sh`; extended the
  linter (shared-file appends in arrays, scratch without trap, GPU/torchrun mismatch, random MASTER_PORT).
  Testing found and fixed a bug: scratch was deleted even when the final sync failed. Tested: linter on all
  templates, scratch template (periodic sync, USR1, restart, failed-sync keeps scratch) with an rsync
  stand-in, R skeleton (non-fork path, resume). Not tested: real rsync on Linux, mclapply fork path, GPU
  templates, torchrun/multi-node patterns, anything on a real cluster.
- 2026-10-23: Added `deeplabcut-hpc` (DLC on HPC). Written from the official docs only, starting at the DLC LLM
  entry point (https://deeplabcut.github.io/DeepLabCut/llms.txt). Covers headless install, PyTorch config keys,
  DLC-specific pitfalls, a training job skeleton, and a troubleshooting section that searches upstream
  issues/PRs/commits via `gh`. States that the assistant runs locally only and cluster-side commands are
  instructions for the user. Not tested: nothing run on a cluster, `gh` commands not run, function signatures
  not hard-coded (lookup in live docs).
- 2026-10-23: Added `gam-mgcv` (GAMs/GAMMs with mgcv, gratia and related packages) with references for
  smooths/families, HGAMs/random effects, and resources. Includes the guideline to check Gavin Simpson's
  gratia docs/changelog, blog and GitHub. Built from the Agent Skills spec, gratia reference index/news
  (v0.11.2-66), Pedersen et al. 2019 and Simpson's repo list. No overlapping built-in skill found. Code
  snippets not executed at first (see later entries); committed and pushed in 72a177f.
- 2026-10-23: Added `gam-mgcv/references/sz-smooths.md` plus an sz section in SKILL.md. Verified by running
  (mgcv 1.9-4, gratia 0.11.2.10): per-level sp vs `id`, char-factor error, aliased `+fac`, NA k-index in
  `k.check`, NA for unseen levels, `difference_smooths()` fails on sz, `conditional_differences()` absent in
  installed version, derivatives/smooth_samples/bam OK, helper `sz_difference()` matches smooth_estimates.
  `gh` is installed but not on PATH in Git Bash/R here, so issue history came from the GitHub search API.
- 2026-10-23: Added `gam-interpretation` (visualisation + cautious interpretation of GAMs) with references
  `phrasing.md`, `uncertainty-and-inference.md`, `visualisation.md`, `recent-developments.md`. Starts with a
  currency check (installed gratia/mgcv versions, function availability) and links the gratia changelog,
  Simpson's blog/GitHub. Built from gratia 0.11.2-66 articles (smooth effects, prediction comparisons,
  posterior simulation, model checking, variance components, data slices, custom plotting), Marra & Wood
  2012, marginaleffects. Verified in the live session (gratia 0.11.2.10): fitted_values simultaneous,
  conditional_values, smooth_estimates+add_confint, confint simultaneous, response_derivatives, variance_comp,
  draw(residuals=TRUE). Absent locally: conditional_differences, ale, simultaneous_bands. Not verified: new
  theme API, sampling-API renames, ale/conditional_differences code. Committed and pushed in 72a177f.
- 2026-10-23: Installed gratia 0.11.2-64 (R-universe binary; GitHub source install failed at DLL load test with
  Rtools45/R 4.6.0). Re-tested: conditional_differences (works, also on sz models, matches the manual sz
  contrast to ~1e-15), ale, theme API, n_draws migration error, draw formals. difference_smooths still fails on sz.
  variance_comp(type="terms") output identical to "penalty" (flagged). Updated recent-developments.md,
  sz-smooths.md, visualisation.md, uncertainty-and-inference.md. Committed and pushed in 72a177f.
- 2026-10-23: Added `social-research-search` (keyless Bluesky `searchPosts` on api.bsky.app + Mastodon hashtag
  timelines; R httr2 helper `scripts/social_search.R`). Tested live on mgcv, gratia, rstats: Bluesky
  `cursor` paging gives 403 without login (helper pages via `until` instead); `public.api.bsky.app` gives 403;
  Mastodon keyless status search returns nothing (hashtags only); bad-host errors become warnings. X/Twitter
  deliberately not covered (no free keyless access; Nitter checked and not viable: archived 2026-10-09 after
  X legal action, instances bot-walled). Optional CRAN packages: `bskyr` (needs free Bluesky login), `rtoot`,
  `vosonSML`; not tested. Committed and pushed.
- 2026-10-23: Added `animal-behaviour-tracking-analysis` v1 (keypoint-MoSeq downstream of DLC; R and Python).
  Files: `scripts/kpms_headless_fit.py` (resumable headless fit, `--prepare-only`), `kpms_summarise_results.py`
  (h5py to bouts/usage/transitions CSV), `kpms_results.R` (hdf5r reader plus the same summaries),
  `assets/kpms_fit.sbatch`, three references. Sources: kpms stable docs (install, modeling, FAQs, advanced, io,
  analysis), PyPI, GitHub releases/issues. Tested on Windows with kpms 0.6.6 (CPU, pandas<3, uv venv) on synthetic
  DLC CSVs: fresh fit, AR- and full-phase resume, two concurrent seed fits, `expected_marginal_likelihoods`,
  R vs Python vs kpms-CSV agreement, nested HDF5 groups, glmmTMB+emmeans per-syllable snippet, igraph snippet,
  sbatch linter. Findings: kpms 0.7.x (PyPI 0.7.1, 2026-10-22) is not installable on Windows (needs Linux-only
  jax-cuda12-pjrt); 0.6.6 with pandas 3 breaks `check_nan_proportions`; `extract_results` has no `overwrite` in
  0.6.6; `setup_project` fails if the folder exists; hdf5r reverses dimension order vs h5py. Installed from CRAN:
  hdf5r, glmmTMB, emmeans, DirichletReg, reticulate. Not tested: kpms 0.7.x, GPU, Slurm, multi-animal DLC, real
  data, apply_model, grid movies. Committed and pushed.
- 2026-10-23: Added basic DLC metrics to `animal-behaviour-tracking-analysis` (v2): `scripts/dlc_metrics.py` (CLI) and
  `dlc_metrics.R` (functions) for likelihood masking, short-gap interpolation, px-to-cm, Savitzky-Golay, distance,
  speed, immobility bouts, ROI occupancy (circle/rect/polygon, entries, latency), time bins; plus
  `references/dlc-basic-metrics.md`. Online sources: `movement` (neuroinformatics-unit, docs v0.17.0), `animovement`
  (R-universe only, NOT installed, needs user permission), DLC2Kinematics, DLCAnalyzer (ETHZ-INS), dlcpr, DeepOF,
  DLCutils (its `time_in_each_roi.py` default assigns every frame to the nearest ROI, contradicting its docstring),
  trajr vignette. Tested on synthetic DLC-format files (single + multi-animal, csv + h5): R == Python to 1e-8, speed
  and length equal `trajr` 1.5.1. Synthetic demo: jitter without smoothing gave 4% immobile vs 50% true, so
  thresholds must be validated. Installed from CRAN: signal, trajr. Not tested: real recordings, camera tilt,
  `movement` package itself.
- 2026-10-23: User gave explicit permission to install `animovement` from R-universe (non-CRAN rule). Installed
  animovement 0.8.0.9002 plus anicore, aniread, anispace, aniprocess, anicheck, animetric, anivis (R-universe dev
  builds) and tested on synthetic DLC CSVs; added a section to `references/dlc-basic-metrics.md`. Findings: distance and
  circular-ROI time match `dlc_metrics`; speed definition differs; `read_deeplabcut` flips y (set `video_height`);
  fps via `set_metadata(sampling_rate=)`; `.h5` needs Bioconductor `rhdf5` and prompts interactively (hangs
  non-interactive sessions); no polygon ROI, entries, latency or immobility functions.
- 2026-10-23: User allowed Bioconductor installs (rule added to Working rules). Installed `rhdf5` 2.56.1 (BiocManager,
  Bioc 3.23): animovement reads pandas-fixed and DLC-style table `.h5`, equal to CSV; added `dlc_from_anipoint()` to
  `dlc_metrics.R` (identical summary to the CSV route). Installed `movement` 0.17.0 (uv, Python 3.12, scratch venv, with
  `tables`) and tested load/filter/interpolate/savgol/speed/path length/PolygonOfInterest on csv and h5: path length and
  ROI time within about 0.2% of the scripts; speed definition differs (central difference, as in animovement); no circle
  ROI, entries or immobility; `compute_region_occupancy` not run. Section added to `references/dlc-basic-metrics.md`.
- 2026-10-23: Added `references/statistical-analysis.md` and `scripts/stats_demo.R` (metrics and kpms usage to statistics).
  Verified from the kpms 0.6.6 source: built-in tests are permutation Kruskal-Wallis per syllable (BH over syllables) plus
  Dunn post hoc, unit = recording, `index.csv` has only `name` and `group`; so it handles more than 2 groups (the user
  remembered 2) but has no covariates, interactions, nesting or effect sizes. Demo (simulated 24 animals x 2 sessions) ran
  clean: Gamma/binomial/beta-binomial/nbinom2 GLMMs, coxme latency, bam time course, per-syllable nbinom2 + BH, PERMANOVA
  with whole-animal permutations, CLR-PCA + lmer, bout-duration lmer, transition binomial GLMM; statsmodels MixedLM and
  Poisson GEE tested in the kpms venv. Findings: plain binomial on frame counts was strongly overdispersed (AIC 4915 vs 763
  beta-binomial); compositional closure produced a spurious "decrease" in a Python simulation. Installed from CRAN: vegan,
  permute, coxme, lmerTest. Not tested: real data, power analysis, DirichletReg/compositions routes.
- 2026-10-23: Added `mixed-models-glmm` (SKILL.md, `references/pitfalls-and-reporting.md`, `scripts/glmm_templates.R`).
  Blocks 1-5 reuse the tested stats_demo.R templates (Gamma, binomial/beta-binomial, nbinom2 offset, emmeans, Holm);
  new tested blocks: zero inflation with emmeans `component` cond/zi/response, dispformula, random intercept vs slope
  (singular fit with corr -1 reproduced), lmerTest Satterthwaite, performance icc/r2/check_singularity. Script ran clean
  with glmmTMB 1.1.15.2, DHARMa 0.5.0, emmeans 2.0.4, lme4 2.0.6, performance 0.19.0. Findings: `testCategorical(plot=FALSE)`
  errors in DHARMa 0.5.0; testZeroInflation p=0.07 while AIC favoured ZI by 37. Checked that `recalculateResiduals(group=)`,
  `ordbeta`, `beta_family`, `diagnose`, `nbinom1` exist. Not tested: real data, rptR (not installed), ar1/exp covariance
  structures, pbkrtest bootstrap with glmmTMB, brms. (Committed in f57ecd1.)
- 2026-10-23: Installed `rptR` 0.9.23 from CRAN; tested Gaussian and Poisson `rpt()` (block 9b in `glmm_templates.R`; full script
  reruns clean, noisy progress bar and singular-fit warnings in bootstraps). Added "Issues reported for ecological and behavioural
  data" to `mixed-models-glmm/references/pitfalls-and-reporting.md` from OpenAlex (R/httr2; authors verified via API, abstracts only,
  no full texts) plus glmmTMB GitHub issue titles (#536, #830, #522, #888, #744, titles only). OpenAlex gotcha: wildcards are
  rejected inside quoted phrases in `title_and_abstract.search.exact` (HTTP 400). Caught one misattribution (W2055156391 is
  Cleasby et al. 2014) by checking authorships.

- 2026-10-23: Added `github-skill-maintenance` (SKILL.md; `scripts/lint_skills.R`, `check_versions.R`, `check_sync_setup.R`;
  `references/sync-and-config-facts.md`, `references/testing-skills.md`; `assets/trigger-queries.template.json`). Built from
  agentskills.io (specification, evaluating skills, optimizing descriptions), the Claude best-practices guide, and the Posit
  Assistant skills/hooks/config docs. CRAN check: no skill-specific package; used `yaml`, `jsonlite`, `gert`, `utils`. PyPI
  `skills-ref` (via `uvx --from skills-ref agentskills validate`; plain `uvx skills-ref` fails) passes all 13 skills. Linter
  findings on the existing skills (all fixed and pushed in e5e6790, 2026-10-23: description now single-quoted, three scripts
  converted to LF, link reworded, TOCs added to the five long reference files; `lint_skills()` then reported no findings for
  14 skills): (1) `hpc-job-scripts` description is truncated at "Covers" because an
  unquoted ` #SBATCH` starts a YAML comment (confirmed with R `yaml` and `skills-ref`); (2) CRLF in the working copy of
  `hpc-job-scripts/scripts/check_sbatch.sh`, `hpc-job-scripts/assets/python-scratch-job.sh` and
  `animal-behaviour-tracking-analysis/scripts/dlc_metrics.py` (index is LF); (3) `mixed-models-glmm/SKILL.md` links to
  `references/statistical-analysis.md`, which only exists in `animal-behaviour-tracking-analysis`; plus info items (reference
  files over 100 lines without a TOC; `hpc-job-scripts` has no "Use when" wording after the truncation). `check_versions()`
  flags only kpms 0.6.6 (latest 0.7.1) and gratia claims (dev builds newer than CRAN 0.11.2); the rest match.
  `check_sync_setup()` tested with synthetic cfg lists and live git state; R was blocked from reading the real
  `~/.posit/assistant/settings.json` (session file guard, not worked around), so that path is untested. Note: the
  `mixed-models-glmm` entry above says "Not yet committed" but it is in commit f57ecd1. Standing rule "Verify before
  reporting ready" added to the working rules.

- 2026-10-23: Added `data-repository-readme` (SKILL.md, `assets/README_template.md`, `references/sources.md` with live
  URLs for Cornell, Dryad, Zenodo, Figshare, UBC/Borealis, Harvard and a "how to look for changes" list,
  `references/content-guide.md`, `scripts/draft_data_dictionary.R`, `scripts/check_readme.R`). The workflow forces a
  currency check against the target repository's live pages. Built from webfetch/search of those pages; not read: the
  Dryad template file itself, go-fair.org (fetch returned nothing), journal policies. Installed `frictionless` 1.3.0 from CRAN
  (infers column types only). Tested both scripts on a synthetic deposit with seeded defects (two bugs found and fixed:
  perl regex for backticked filenames, mixed ISO/non-ISO dates). `lint_skills()` no findings, `skills-ref` valid,
  `check_versions()` OK for frictionless. Not tested: Excel/HDF5 input, real submissions. (Committed.)
  Follow-up same day: read the Dryad template in full (4 sections, no author/license/contact; added
  `assets/README_dryad.md` and `check_readme(profile = "dryad")`). Installed and tested dataspice 1.1.1, codebook 0.10.1,
  skimr 2.2.2, frictionless 1.3.0 (`references/optional-packages.md`): skimr and frictionless useful for QA;
  dataspice wrote given name "T" as `true`, not a README tool; codebook outputs HTML for survey data;
  `compact_codebook()` left a stray `figure/` PDF in the working directory (removed). frictionless infers
  `string` for a column with mixed date formats and only warns when the type is set to `date` explicitly.
  Second follow-up: read Cornell data and software templates (eCommons REST `/server/api/core/bitstreams/<id>/content`
  works with curl; `/bitstreams/<id>/download` gives 405), UBC template and sample, Borealis report PDF (`pdftotext`):
  added tier labels (Borealis minimum 9 / enhanced 13), header "generated/updated" line, two contacts, ancillary and
  not-included data, abbreviations/codes glossary, version section, `assets/README_software.md`, info-level
  enhanced-element checks in `check_readme()`. Not obtained: Borealis xlsx and the 20 example READMEs.

- 2026-10-23: Added `manuscript-figures-ggplot` (SKILL.md; `scripts/figure_helpers.R` with `theme_ms`, `okabe_ito`,
  `journal_width`, `save_figure`, `check_pdf`, `cvd_preview`; `assets/example_figure.R`; references `principles-and-pitfalls`,
  `journal-specs`, `colour`, `ggplot2-and-packages`, `community-notes`). Sources read live: Chenxin Li's FriendsDontLetFriends
  (README, 16 rules, flagged as opinionated; contested points listed), Wilke dataviz (ch. 16, 19, 21, 27), Weissgerber 2015,
  Rougier 2014, Data-to-Viz caveats, ggplot2 4.0.0 release post, N. Rennie's blog, Nature research-figure-guide, Elsevier artwork
  sizing, OUP Behavioral Ecology, Frontiers, a Springer artwork page (search extracts). Social search (Bluesky/Mastodon) gave
  only anecdotal leads (sizing at export, patchwork, ggview, accessible palettes). References verified in OpenAlex. Blocked or
  not read: nature.com final-submission and Nature Methods pages, science.org, Springer Oecologia (403), BE general-instructions
  (404), Crameri 2020 full text. Science, Cell, Nature Communications widths are third-party only. Tested (R 4.6.0, ggplot2
  4.0.3): `save_figure` PDF/PNG/TIFF/SVG (TIFF 600 dpi LZW, 2102 px for 89 mm), `check_pdf` via qpdf on the real PDF stream (text
  sizes 5.6/7/8 pt, fonts embedded, 1 mm linewidth = 2.134 pt), `cvd_preview` (red/green collapse visible), example figure,
  ggplot2 4.0 theme palettes and `panel.widths`. Smoke-tested only: ggdist, scico, ggrastr, ggh4x, ggtext. Installed from CRAN:
  svglite, ggbeeswarm, ggdist, scico, ggtext, ggrastr, ggh4x, tiff (plus dependencies). `lint_skills()` no findings,
  `skills-ref` valid; `check_versions()` only "claim older than latest" for the generic "ggplot2 4.0". Not tested: Linux/macOS,
  cluster fonts, EPS, any journal upload, real data.
- 2026-10-23 (follow-up): `manuscript-figures-ggplot` now prefers CVD-friendly palettes (viridis family and relatives first;
  user request) and has `references/ggplot2-hacks.md`. `theme_ms()` gained `palette = c("viridis","okabe")` (ggplot2 4.0 theme
  palettes; verified vs `viridisLite`, cividis ends) and `element_geom` line defaults (`geom_line_pt`; point `stroke` still ~1.07 pt).
  Sources: sparse clone of nrennie/tidytuesday 2025-26 (idiom counts), tidyverse "ggplot2 styling" article, Posit ggplot2 cheat sheet
  (HTML, 2026-08), contributed cheat-sheet list, a third-party cheat sheet (r-statistics.co; its claim that `scale_x_log10()` leaves
  histogram bins unchanged is wrong, tested), Bluesky/Mastodon trick posts. Tested (render-only): textbox_simple, clip off, identity
  scale, `facet_manual`, `labs(alt)`, `labs(dictionary)`, stretchy colourbar, `element_geom`, geomtextpath, `ggview::canvas`.
  `camcorder` 0.1.0 recorded 0 files under ggplot2 4.0.3. Installed from CRAN: ggview, camcorder, geomtextpath, pdftools.
  Not read: Rennie workshop slides, Posit cheatsheet content pages. (Committed.)

- 2026-10-23: Added the lessons-learned feedback loop. New skills `skill-lessons` (capture protocol, entry format, privacy rules,
  `scripts/lesson_helpers.R`, `references/hook-setup.md`) and `skill-feedback-triage` (`scripts/read_lessons.R`,
  `references/triage-method.md`); `scripts/lessons-hook.sh` (one script for `PostToolUse` matcher `skill` and `Stop`); a
  "Capture lessons" section appended to the other 16 skills; `lint_skills()` now errors when it is missing. Designed from the
  hooks docs (Stop can return `decision: "block"`; `stop_hook_active`; SessionEnd cannot inject and has a 5 s budget; hooks
  additive). Hooks added to global `settings.json` (backup `settings.json.bak-lessons`), data under `~/.posit/lessons/`
  (`inbox/`, `usage.tsv`, `state/`). Tested: hook with synthetic payloads (no-skill Stop silent, non-repo skill ignored, usage
  log, error count, one block per session with valid JSON, turn limit 6, `stop_hook_active`, existing inbox file suppresses,
  Windows `cwd` to project name); live: loading a skill in this session wrote a `usage.tsv` row with the real payload
  (transcript_path is `conversation.json`, tool_response is an object); `lesson_add()` scrub, validation, front matter, fallback
  text when R is blocked; `read_lessons()` overview, dupes, problems on synthetic files; `lint_skills()` no findings for 18
  skills; `skills-ref validate` valid for both new skills. Findings: the assistant's R session cannot write or read outside
  the project (`dir.create` on `~/.posit/lessons` blocked), the `write` tool and bash can, so lesson entries are saved with
  `write` and triage copies the inbox into the project with `cp`; each hook call costs about 0.5 s on Windows (Git Bash
  start-up), so tool-error counting is implemented but not enabled in the matcher. Not tested: the Stop block in a real
  session (whether the model follows the reminder), the `write` tool permission prompt in other workspaces, multi-machine
  collection, `check_sync_setup()` against the new hooks, any real lesson. Follow-up: `usage.tsv` is append-only; triage
  records a watermark line (`- Lessons usage watermark: <ISO time>`, section "Lessons triage state" in this file) via
  `triage_watermark()` / `triage_watermark_set()` and `read_usage(since = )`; tested on scratch files. Committed and pushed.
  Then `check_sync_setup()` gained a lessons-hook audit (PostToolUse `skill` matcher, Stop entry, handler fields, bash prefix,
  timeout, script LF/`bash -n`/`stop_hook_active`, data-folder counts). Tested with synthetic good/bad configs and a synthetic
  lessons folder, and on the user's real `settings.json` pasted as text (R cannot read that file; all ok). Committed and pushed.

- 2026-10-23: Added `job-opportunity-watch` (SKILL.md; `scripts/jobwatch.R`, `run_probe.R`; references `classification`,
  `state-and-files`, `maintaining-links-and-profile`, `portal-quirks`; assets links and profile templates). Design: replaces a
  one-shot Copilot prompt that degraded over time; model-free R steps do parsing, polite probing (httr2/rvest), diff against
  `state/` and a coverage audit, the assistant triages, verifies and classifies A-E, and edits to links file or profile need
  user confirmation (`jw_add_link`/`jw_write_confirmed`, backup + `confirmed = TRUE`). User data lives in an ignored
  `job-watch/` folder (also `tmp-examples/` ignored). Tested on the user's real 104-link list, two runs (1 min each): 85 ok,
  ~10 JS-suspect, 4 blocked, 2-4 errors, 3 search-engine URLs; run 2 diff gave 5-27 new links and 1-2 queue items; link
  insertion, backups, opportunity upsert/expire, headless digest. Bugs found and fixed: invalid-byte pages broke `gsub`,
  `table[["x"]]` on missing names, TSV quoting. `lint_skills()` clean, `skills-ref` valid, no version claims. Not tested:
  Task Scheduler/hook, real vacancy verification by the assistant, non-English title filter quality, other machines.
  Committed with the Step 4b change.
- 2026-10-23: `job-opportunity-watch`: new Step 4b (social discovery) that explicitly uses `social-research-search` and requires a
  ledger of useful hashtags/search terms per platform (`state/social_tags.tsv`; `jw_tags_read/record/review/set_status` in
  `jobwatch.R`; status changes only after user confirmation, backup first, rows never deleted). Tested the helpers on a scratch
  ledger (create, `#` stripping, counts, review suggestions, refusal without `confirmed`). `lint_skills()` clean, `skills-ref`
  valid. Not tested: a real discovery run, how well Bluesky free-text terms fit the ledger. Also added five todo skills
  (`r-reproducible-pipeline`, `manuscript-writing-quarto`, `python-r-interop`, `git-for-research-projects`, `grant-and-cv-support`).

- 2026-10-23: Cross-skill link audit. Added "Related skills" sections (or extended existing ones) in 15 skills (`gam-mgcv`,
  `gam-interpretation`, `mixed-models-glmm`, `deeplabcut-hpc`, `hpc-cluster-docs`, `hpc-gpu-jobs`, `hpc-job-scripts`,
  `hpc-python-code`, `hpc-r-code`, `hpc-resource-allocation`, `animal-behaviour-tracking-analysis`, `data-repository-readme`,
  `openalex`, `social-research-search`, `job-opportunity-watch`). New standing rule "Link skills to each other". New
  `github-skill-maintenance/scripts/check_skill_links.R` (`check_skill_links()`: one-way, unknown-skill, isolated; hubs and
  boilerplate sections ignored) and `references/link-decisions.tsv` (eight reasoned `no-backlink` decisions); workflow step 1b.
  Heuristic is textual (a skill name appearing), not semantic. Not tested: `scope = "all"` on real findings beyond a run.

- 2026-10-23: Lessons loop made stronger: new entry type `use-case` (one short generic summary per session that used a repo
  skill, written even when nothing failed; `usecase_add()` in `skill-lessons/scripts/lesson_helpers.R`, new SKILL.md section).
  `scripts/lessons-hook.sh`: Stop reminder now asks for a use-case entry always plus lessons, pilot `LESSONS_TURN_LIMIT` default 2
  (was 6; raise once capture is shown to work), and every reminder is logged to `~/.posit/lessons/reminders.tsv` so loads
  (`usage.tsv`) vs reminders vs inbox files show where capture fails. `skill-feedback-triage` accepts the type
  (`read_lessons.R`, `triage-method.md`). Tested: hook with synthetic payloads (silent turn 1, one valid block on turn 2,
  reminders row, silent turn 3), `usecase_add()` output, reader/overview on a use-case file, `lint_skills()` clean (19),
  `skills-ref` valid. Not tested: a real session (does the model follow the reminder), R writing to the inbox (blocked, the
  `write` tool is the fallback).


- 2026-10-23: First `skill-feedback-triage` run: 3 inbox files (3 use-case entries, 2 lessons; skills openalex, r-reproducible-pipeline,
  github-skill-maintenance), 10 loads in 5 sessions in `usage.tsv`. Outcomes: (1) openalex 400 on wildcard queries: `fix`, partly
  reproduced (`title.search` + wildcard gives 400 with a readable message; exact+boolean+wildcard and quoted wildcard returned 200, not
  reproduced), note added to `openalex/references/r-workflow.md`; (2) shared-cache truncation: renv rule already present, uv hardlink
  hazard reproduced (truncating a venv file emptied the cache copy), pitfall added to `python-reproducible-pipeline`
  `references/environments-and-pinning.md` and a disposable-copy rule to `github-skill-maintenance/references/testing-skills.md`;
  (3) `lesson_problems()` no longer requires `confidence` for use-case entries (reader, `skill-lessons` text); (4) note in
  `skill-lessons/references/hook-setup.md` that loads are counted only via the `skill` tool. Not verified: whether `title.search.exact`
  accepts wildcards, uv `--link-mode clone`/copy behaviour, Linux/macOS, a second independent report for any issue. Also added the
  openalex full-text retrieval (`scripts/fetch_fulltext.R`, `references/fulltext.md`; committed earlier). Watermark set; processed files
  moved to `~/.posit/lessons/inbox/processed/`.

- 2026-10-23: Skill clash audit (not committed yet). Method: IDF-weighted cosine similarity of the 22 descriptions, then manual reading
  of the Related-skills sections and of the overlapping body sections. Real clashes (score before): `python-`/`r-reproducible-pipeline`
  0.52 (both claimed the tool decision), `gam-mgcv`/`gam-interpretation` 0.24 (gam-mgcv claimed interpreting, plotting and
  glmmTMB; its Interpretation section duplicated gratia advice that only `gam-interpretation` version-checks), HPC family (failure
  words "killed", "out of memory", "how many GPUs" claimed by three skills; `hpc-r-code` claimed "an R pipeline"). Fix: narrowed
  descriptions and added hand-off sentences in 16 skills; slimmed the gam-mgcv section. Accepted overlaps (reason recorded): the two
  language twins, lessons writer/reader, `hpc-cluster-docs` gate. New: `github-skill-maintenance/scripts/check_skill_clashes.R`
  (`check_skill_clashes()`), `references/skill-boundaries.md` (ownership map, description rules, procedure, open items),
  `references/clash-decisions.tsv`, workflow step 1c, standing rule "Watch for skill clashes". After: no findings at threshold 0.15;
  at 0.1 only the generic `hpc-*` vocabulary noise. `lint_skills()`, `check_skill_links()`, `skills-ref validate` (15 changed skills)
  clean. Not tested: real trigger queries (score is lexical), body duplication beyond the GAM pair (see open items in
  skill-boundaries.md), the threshold on a larger skill set. No separate skill created: the task is a maintenance step, so it
  extends `github-skill-maintenance`.
  Follow-up: proxy trigger test with 15 queries (`github-skill-maintenance/assets/trigger-queries-clash-areas.json`), three subagent
  runs that saw only descriptions: expected skill in 45/45 selections; `hpc-cluster-docs` co-loads on most HPC queries (gate by design).
  Not tested: real loader, near-miss should-not-trigger queries. Summary in `skill-boundaries.md` open items.

- 2026-10-23: Drafted `python-reproducible-pipeline` (uv + Snakemake default, Slurm executor plugin; not committed). Files: SKILL.md,
  `references/` (`tool-choice`, `snakemake-slurm`, `environments-and-pinning`, `sources`), `assets/project-template/` (two-rule workflow,
  config, logs, benchmarks, report entry, Slurm profile with placeholders), `scripts/check_pipeline.py` (static checker). Research in
  `research/pipeline-resources-ledger.md` (shared with the planned `r-reproducible-pipeline` and `python-r-interop`; not a skill).
  Tested locally (Windows, Snakemake 9.27.1, plugin 2.8.0, uv 0.12.5): template run, incremental rerun via params, report (needs pygments),
  Slurm profile dry run, profile loading, stale-lock detection, checker on clean and seeded-defect copies (bugs found and fixed:
  docstring false positive, `uv run` hiding a stale lock). Observed but unexplained: a touch without content change does not rerun
  (checksum hypothesis untested). Not tested: real Slurm, NFS, Linux/macOS/WSL, conda/containers, Quarto step, uv on a cluster. Prefect,
  Dagster, Nextflow, pytask judged from docs only. Link audit: backlinks added in `animal-behaviour-tracking-analysis`,
  `data-repository-readme`, `hpc-job-scripts`; four `no-backlink` rows recorded. `lint_skills()` and `check_skill_links()` clean (20 skills),
  `skills-ref` valid.

- 2026-10-23: Research round 5 for `r-reproducible-pipeline` (ledger section 11, no skill files yet). Read the targets manual
  (walkthrough, projects, random, literate-programming, performance, debugging, hpc), renv docs and lockfile reference, Quarto
  project scripts. Installed from CRAN: targets, tarchetypes, crew, crew.cluster, qs2, gittargets, quarto (R pkg). Tested locally
  on an 8-target pipeline with a Python step via `uv run`, `tar_quarto`, crew local controller: hash-based file tracking (touch,
  comment edits ignored; unchanged output stops downstream reruns), name-derived seeds reproduce after deleting the store,
  `crew_controller_slurm()` constructs (no submit). Gotchas: R `yaml` reads key `n` as FALSE; `reporter = "summary"` deprecated;
  `tar_quarto` needs the `quarto` package. Not tested: renv init/snapshot on a targets project, Python chunk in a targeted
  report, real Slurm, NFS, Linux. Open items listed in ledger 11.5. (Committed.)

- 2026-10-23: Added `r-reproducible-pipeline` (SKILL.md; `references/` targets-patterns, renv-and-pinning, hpc-crew, tool-choice, sources;
  `assets/project-template/` with `_targets.R`, `R/`, `py/` (uv.lock), `config/`, `report.qmd`, `_dependencies.R`, `slurm/run_targets.sbatch`;
  `scripts/check_targets_project.R`). Tested locally (Windows, targets 1.12.0, crew 1.3.3, renv 1.3.1, uv 0.12.5): template end to end
  (Python step per sample through `uv run --locked`, dynamic branching, `tar_quarto`), skip on rerun, invalidation table, seeds reproduce after
  deleting the store, `PIPELINE_EXECUTOR=local`, Slurm controller builds, `renv::init()` in a `callr` subprocess and a run inside the project
  library, sbatch passes the `hpc-job-scripts` linter, checker on the template, an renv copy and a seeded-defect copy (CLI exit status too).
  Findings: whole-`config` dependency reran every branch when a sample was added (fixed with per-setting targets); renv implicit snapshot missed
  `quarto` (fixed with `_dependencies.R`); `tar_seed()` deprecated for `tar_seed_get()`; CRLF rewrite of a tracked file reruns dependants; the
  assistant's R session cannot read `.Rprofile` (checker reports INFO). **Incident:** a stray `file.copy()` of an renv test project onto itself
  truncated 63 entries in the shared renv cache (`%LOCALAPPDATA%/R/cache/R/renv/cache`), including older ones from July; repaired by copying the
  same versions from the installed library and verified with `diff -r` (0 differences, 267 entries intact afterwards); rule recorded in the skill.
  `lint_skills()` and `check_skill_links()` clean (21 skills), `skills-ref` valid for the new and four edited skills, `check_versions()` same.
  Backlinks added in `python-reproducible-pipeline`, `data-repository-readme`, `hpc-job-scripts`, `hpc-r-code`; three `no-backlink` rows. Not tested:
  `tar_make()` in a real Slurm job, crew.cluster submission, NFS, Linux/macOS, Python chunk in a targeted report, `tar_map`/`tar_rep`, undeclared-script
  negative case, restore from a P3M snapshot URL. (Committed in c4fd1fd; the template `uv.lock` was untracked until the next commit, see below.)

- 2026-10-24: Debugged a real undertrigger from `tmp-examples/conversation-export-1.json` (a DLC-on-HPC
  project log, not committed). Turn 1 asked for "an optional orchestrator for the sow and piglet submission
  scripts... to submit jobs with different training parameters"; `hpc-job-scripts` and `deeplabcut-hpc` did
  not load even after the assistant read the actual `GDK_DLC_*_submit.sh` files (which would show `#SBATCH`
  and a DLC training call) — only two turns later, once the user wrote "HPC best practices and DLC API"
  explicitly, did both plus `hpc-gpu-jobs`/`hpc-cluster-docs` trigger. Web sources read (philschmid.de,
  agensi.io, selftune.dev, atlan.com, codemyspec.com, dout.dev, bibek-poudel/sathishkraju on Medium, AWS
  DevOps blog; all agree the description is a semantic trigger, must mirror indirect/contextual user
  phrasing and not just tool jargon, and most undertriggers trace to the description rather than the body).
  Fix: widened the "Use when" clauses of `hpc-job-scripts` (added orchestrator/sweep/batch-of-runs phrasing
  and "a script that already contains #SBATCH/sbatch/srun, even if the request doesn't name Slurm/HPC") and
  `deeplabcut-hpc` (retrain/resubmit/orchestrator over existing DLC scripts, plus the same file-content
  signal for `import deeplabcut`/`pytorch_config.yaml`). Documented the general pattern — descriptions miss
  project/domain jargon, and the assistant does not auto-recheck skills after file reads reveal a match —
  as a new section in `github-skill-maintenance/references/testing-skills.md`. Deliberately did not add this
  user's own project words ("sow", "piglet") to the shared description; that doesn't generalise. New overlap
  from the wording (`deeplabcut-hpc`/`hpc-job-scripts`, score 0.161) recorded as `accepted` in
  `clash-decisions.tsv` (the two legitimately co-trigger for a DLC job orchestrator). Checked:
  `lint_skills()` (info-only, both descriptions now ~970 characters, under the 1024 limit),
  `check_skill_clashes(new=)` for both, `skills-ref validate` for both, `check_skill_links()` clean (24
  skills). Not tested: the new description wording against fresh conversations (no trigger-query re-run),
  whether the file-content-signal instruction actually changes assistant behaviour mid-task (this is a
  behavioural claim added to the description, not something lint can verify). Committed (`fb6eaf9`).

- 2026-10-24: Built `scripts/skill-file-signal-hook.sh`, the non-blocking R2 counterpart to
  `skill-trigger-hook.sh` (R1), after a second independent real-session recurrence of the
  context-clue undertrigger (see `research/skill-trigger-hooks-ledger.md` section 6 for the
  research round that led to this — six `web_search` calls found the problem is common across
  the Claude Code/agent-skill ecosystem, a mechanistic explanation in a 2026 arXiv tool-drift
  paper, and two independent community hooks already doing close to this design as a
  non-blocking nudge). Design: opt-in `metadata.file_signals` (a single `'|'`-separated regex
  string) in a skill's own frontmatter, read by one shared `PostToolUse` hook
  (matchers `skill` and `read|grep|bash`); on a match for a skill not yet loaded this session,
  emits `hookSpecificOutput.additionalContext` naming it, at most once per (session, skill),
  never a block. Seeded on `hpc-job-scripts` (`#SBATCH`/`sbatch`/`srun`) and `deeplabcut-hpc`
  (`import deeplabcut`/`pytorch_config.yaml`/`pose_cfg.yaml`) only — not added to the other 22
  skills speculatively. Extended `lint_skills()` (file_signals must be a single string,
  compiles as a regex, warns on low-specificity alternatives) and `check_sync_setup()` (new
  audit section, including a check that the script never emits `decision:"block"`). Registered
  in the real `~/.posit/assistant/settings.json` (backed up first to
  `settings.json.bak-filesignal`). Tested on Windows (Git Bash, GNU bash/grep/sed/awk):
  `bash -n`; eight scenarios with synthetic piped payloads (nudge on a matching `read`/`grep`
  result, silence on repeat/already-loaded/unrelated-content/non-matching-tool, missing
  session_id, malformed stdin) plus an embedded-double-quote content case and direct checks of
  the `file_signals` extractor against both seeded skills and a skill with none declared;
  `lint_skills()` clean (24 skills, same two pre-existing `info` items only);
  `check_skill_links()` clean; `check_sync_setup()` run against the real, updated
  `settings.json` content (same path-guard workaround as the other hook audits) — all `ok`
  except the expected `working tree` warning for uncommitted changes; `uvx skills-ref validate`
  passed for both touched skills. CRLF working-copy drift hit again on four files during this
  change (`hpc-job-scripts/SKILL.md`, `deeplabcut-hpc/SKILL.md`,
  `github-skill-maintenance/scripts/lint_skills.R`, `github-skill-maintenance/SKILL.md`) —
  normalised with `sed -i 's/\r$//'` before editing each time, per the existing pitfall.
  Documented in `github-skill-maintenance/references/skill-trigger-hook.md` (new "The
  file-signal hook (R2)" section) and a new SKILL.md workflow-step/tested-notes update.
  **Not tested:** the hook firing inside a real conversation turn (whether
  `additionalContext` from a Posit Assistant `PostToolUse` hook actually reaches the model's
  reasoning the way a cited Claude Code community test demonstrated is unverified here); the
  cost of scanning ~24 skill frontmatters per matching tool call at scale; Linux/macOS; a
  second machine; whether the two seeded patterns measurably reduce real misses (needs more
  real sessions to tell either way).

- 2026-10-24: Built `codebase-map` (SKILL.md; `scripts/build_codemap.R`, `scripts/codemap-hook.sh`; references
  `artifact-format.md`, `language-rules.md`, `triggering-and-updating.md`). Research and full build log in
  `research/codebase-navigation-ledger.md` sections 1-5e. Design, confirmed against the user's own decisions (R1-R8): scope
  is RStudio projects only, one `.codemap/` per project (`INVENTORY.md`, `CODEMAP.md`, `DEPENDS.tsv`), base-R-only regex
  scan chosen over ctags/tree-sitter/`pkgapi` (archived, package-only)/`repomix` (Node-only) after a prototype comparison,
  dependencies classified `file-internal`/`file-external`/`package`/`unresolved` with real path resolution, self-trigger
  thresholds (15 files or a 300-line file) gate whether `.codemap/` is created at all, self-update via a `PostToolUse` hook
  (no file-watcher/timer event exists in Posit Assistant, checked live), idempotent `.gitignore` and `AGENTS.md`/`DATABOT.md`
  pointer-block insertion (the AGENTS.md pointer was the user's explicit requirement), `.codemapignore` opt-out. **Incident:**
  testing the hook's project-root walk-up in a scratch folder nested inside this repo caused it to find `llm-skills.Rproj`
  and for real create `.codemap/`, edit the real `AGENTS.md` and `.gitignore` at the repo root; reverted immediately
  (`git checkout -- .gitignore AGENTS.md`, `rm -rf .codemap`), no lasting change. This directly motivated the
  `.codemapignore` opt-out and the decision to **not** register the hook in the live global `settings.json` — that needs
  the user's explicit go-ahead, unlike the earlier pure-nudge hooks in this repo, because it writes to and edits memory
  files in other real projects automatically. All further testing moved to an isolated scratch directory outside this repo.
  Tested (Windows, R 4.6.0): full hook pipeline on a qualifying synthetic project (build, gitignore/AGENTS.md insertion,
  one-time nudge, 30s throttle), a non-qualifying tiny project (no artifacts), a `.codemapignore`-opted-out project (fully
  silent), a plain non-`.Rproj` folder (silent), all four dependency `kind`s on hand-built fixtures (`source()`, `here::here()`,
  Python same-directory and relative imports, a true external-file reference, a package import), idempotency across three
  builds. Also caught and fixed four bugs during the earlier prototype phase (Windows path-regex escaping, `regexpr()` vs
  `gregexpr()` undercounting, R's uppercase-extension case-sensitivity trap, leading-decorative-dash heading capture) and
  one link-checker false positive (don't backtick an external/built-in skill name like `r-package-development` inside a
  "Related skills" section — matches the pre-existing, previously undocumented `recipe-notes-formatter` convention).
  `lint_skills()`, `check_skill_links()`, `check_skill_clashes(new=)`, `skills-ref validate` all clean; ownership row added to
  `skill-boundaries.md`; backlinks added in `r-reproducible-pipeline`, `python-reproducible-pipeline`,
  `git-for-research-projects`. Not tested: the hook in the live global settings (deliberately withheld), a real conversation
  turn, Linux/macOS, `DATABOT.md` as the target file (only `AGENTS.md` exercised), a real (non-synthetic) project, threshold
  tuning, `.qmd`/`.Rmd` embedded-chunk scanning on an actual Quarto file, performance beyond the ~170-file scale already
  measured.

- 2026-10-24: User reported a local `uv`/Python session that worked in this repo but failed to detect
  Python ("installed but not on PATH in that shell") in another project. Decided against a new skill
  (too narrow, would overlap `python-reproducible-pipeline`, `hpc-python-code`, `deeplabcut-hpc`, the
  planned `python-r-interop`): added a canonical section "uv/Python not found by the assistant's shell"
  to `python-reproducible-pipeline/references/environments-and-pinning.md` instead, with short pointers
  from `deeplabcut-hpc/SKILL.md` and `animal-behaviour-tracking-analysis/references/hpc-and-troubleshooting.md`
  (the two skills that actively shell out to `uv`/Python locally for prototyping/testing), plus a backlink
  in `python-reproducible-pipeline`'s Related skills. Mechanism recorded as a hypothesis, not a confirmed
  diagnosis of the other project: on Windows, a child process (the `bash` tool, spawned by RStudio) inherits
  the PATH snapshot of its parent at startup and does not see a PATH change made by installing something
  afterward; a new standalone terminal would see it, RStudio would not until restarted. Tested live in this
  session only: in the current working `bash` tool, `uv`/`python` resolved via inherited Windows user PATH
  entries (`~/.local/bin`, WindowsApps), there was no `~/.bashrc`/`~/.bash_profile` at all, and the shell was
  confirmed non-interactive/non-login — this ruled out "fix by editing `~/.bashrc`" as a false lead (a
  non-interactive Git Bash does not source it) but did not reproduce the actual failure from the other
  project, so the restart-reinherits-PATH explanation is stated as the leading hypothesis pending the user
  confirming it there. Note for later: the planned `python-r-interop` skill should also link to this section
  when it is written. Checks: `lint_skills()` clean (only the three pre-existing description-length info
  items), `check_skill_links()` clean (25 skills), `skills-ref validate` passed for both touched SKILL.md
  files. CRLF hit again on both edited `SKILL.md` files; normalised with `sed -i 's/\r$//'`.

- 2026-10-24: Built `web-fetching-r` (SKILL.md; `scripts/polite_fetch.R`;
  `references/shared-helper-contract.md`) and refactored the three skills that had each
  independently hand-rolled the same "polite R HTTP fetch" pattern (confirmed by direct code
  inspection, see `research/skill-roadmap-ledger.md` round 3): `job-opportunity-watch/scripts/jobwatch.R`,
  `recipe-notes-formatter/scripts/rn_web.R`, `social-research-search/scripts/social_search.R` now
  source `polite_fetch.R` and call its `pf_user_agent()`/`pf_wait()`/`pf_perform()`/`pf_fetch_html()`/
  `pf_blocked_text()`/`pf_js_suspect()` instead of maintaining their own user-agent string, per-host
  rate limiter and httr2 retry/error-swallow pipeline; each dependent script now `stop()`s with a
  clear message if sourced before `polite_fetch.R`. `rn_fetch_html()`'s return contract (numeric
  `$status`, raw `$html` string) was preserved exactly — `pf_fetch_html()` returns a different shape
  (`status` as "ok"/"http_error"/"error", `http` as the numeric code) so `rn_fetch_html()` maps
  between them rather than changing callers. `job-opportunity-watch/scripts/run_probe.R` (the
  headless/Task-Scheduler entry point) locates `web-fetching-r` as a sibling skill folder two levels
  up and sources it before `jobwatch.R`, since no assistant is present to load it there. Tested
  (Windows, R 4.6.0): `lint_skills()` (only the three pre-existing description-length info items),
  `check_skill_links()` (one new one-way link, recorded as `no-backlink` in `link-decisions.tsv`:
  `openalex` doesn't need a pointer back), `check_skill_clashes(new="web-fetching-r")` clean at 0.15,
  `uvx skills-ref validate` passed for all four touched/new skills; the full `recipe-notes-formatter`
  test suite including the live JSON-LD fetch test (116 assertions, 0 failures); offline
  `jw_classify_titles()`/`jw_read_links()` plus live `jw_probe_one()`/`jw_probe()` against real hosts
  (confirmed `ok_js_suspect`/`http_error`/`search_engine` classification unchanged, per-host pacing via
  `pf_wait()` measured at ~1.08s for a 1.0s minimum interval) and `jw_find_replacement()`'s `pf_perform()`
  call sites; a live `bsky_search()` call through the refactored `social_search.R`; the
  sourced-before-dependency guard in a fresh `Rscript` subprocess for all three dependent scripts.
  **Found, not fixed (pre-existing, unrelated to this refactor — reproduced identically via `git
  stash` on the original code):** `job-opportunity-watch`'s `jw_save_run()` errors
  (`replacement has 1 row, data has 0`) when a probe run finds zero anchors on the single link
  checked and no `anchors_seen.tsv` exists yet; logged as a lesson for later triage. Decided not to
  adopt the CRAN `polite` package (documented in the new reference file): none of the three skills
  used it already, it doesn't cover the JSON-API case, and swapping the transport under three
  already-tested skills was judged riskier than extracting the pattern that was actually there.
  CRLF hit repeatedly on `jobwatch.R` and `social_search.R` mid-edit (the edit tool reintroduced it
  each time); normalised with `sed -i 's/\r$//'` before each retry, per the existing pitfall. Not
  tested: a real Slurm-free headless Task Scheduler run end to end (only `Rscript run_probe.R`
  locally), Linux/macOS, the sibling-folder path assumption against a non-standard install layout.

- 2026-10-24: Third `skill-feedback-triage` run. 9 inbox files (12 entries): the two that led to the already-built
  `skill-trigger-hook.sh` and `skill-file-signal-hook.sh` (logged earlier the same day) were treated as `fix, already
  applied` and archived with no further edit; `openalex` duplicate-title-search entry stayed `park` (unchanged since
  the 2026-10-23 run, no new independent report); four `add-note` fixes applied after user approval:
  `data-repository-readme` step 1 now names "repository not yet decided" as an explicit path (flag written into the
  drafted README itself, not just spoken); `deeplabcut-hpc`'s "Not verified" section gained a real-use evidence
  paragraph (two independent real-project sessions: a frame-count diagnosis and a hyperparameter-sweep orchestrator,
  no cluster access used); `github-skill-maintenance`'s CRLF pitfall bullet now says `.gitattributes` only covers
  `.sh`/`.py`/`.md`/`.R` and to re-check with `git ls-files --eol -o -m --exclude-standard` *after* a batch of edits,
  not only before; a new Pitfalls bullet generalises the frontmatter-`metadata`-must-be-a-flat-string rule beyond its
  one existing mention inside the file_signals section. Also fixed the underlying `.gitattributes` gap for this repo
  (`*.R text eol=lf` was missing, the proximate cause of the CRLF entry) and added a note to
  `skill-feedback-triage/references/triage-method.md` on reading an inbox entry whose skill shows 0 loads in
  `usage.tsv` since the watermark. Two remaining entries were pure "worked" use-case confirmations already reflected
  in earlier Log entries; archived with no action. Ironic finding while editing: five files (`.gitattributes`,
  `data-repository-readme/SKILL.md`, `deeplabcut-hpc/SKILL.md`, `github-skill-maintenance/SKILL.md`,
  `skill-feedback-triage/references/triage-method.md`, and this `AGENTS.md` file itself) all came back from
  `edit`/`write` with CRLF and needed `sed -i 's/\r$//'` before `lint_skills()` would accept them or the edit tool
  would match — live corroboration of the very pitfall being fixed. Checked: `lint_skills()` (only the pre-existing
  `deeplabcut-hpc` description-length info item), `check_skill_links()` clean (24 skills), `skills-ref validate` for
  all four touched skills. Not checked: `check_skill_clashes()` (no description text changed), `check_versions()`
  (no version claims touched). Watermark advanced to 2026-10-24T17:22:20; processed files moved to
  `~/.posit/lessons/inbox/processed/` (the parked `openalex` file is the only one left in the inbox).

- 2026-10-23: Commit audit (`git status`, `--ignored`, tracked-file counts per skill, `origin/main` comparison). All 21 skills and
  `research/` were committed and pushed (HEAD 1551556 = origin/main); the "not yet committed" notes above were stale and are corrected.
  One real gap found: `.gitignore` has `*.lock` (meant for sync-hook locks), which silently excluded
  `r-reproducible-pipeline/assets/project-template/py/uv.lock`, although the skill and checker require it. Fixed with a `!uv.lock`
  negation and the file is now tracked. Only ignored leftovers remain (`__pycache__`, `tmp-examples/`, `.posit/`). Lesson: after adding a
  template that contains lockfiles, check `git status --ignored`. `python-reproducible-pipeline` template has no lockfile (not required there).

- 2026-10-23: Research round 1 for `reproducible-research-data` and `git-for-research-projects` (ledger `research/data-and-git-ledger.md`; no
  skill files yet). Read: Turing Way (reproducible research index, RDM storage and checklist, compendia, VCS in research, VCS for data,
  data licensing), Wilson 2017 and Perez-Riverol 2016 (page text), GitHub Docs (large files, Zenodo integration, CITATION files, removing
  sensitive data), Zenodo docs (GitHub integration, CITATION.cff, `.zenodo.json`, create upload), Dryad file requirements, git docs
  (gitignore, gitattributes), Git LFS man page, Syncthing ignore docs, FAIR list (PMC). Blocked (403 or client challenge): Springer
  journal pages, Ecosphere and OUP instructions, Alston and Rick full text, nature.com. Installed from CRAN: `cffr` 1.4.2 (tested on a
  non-package project), `zen4R` 0.10.6 (not tested, needs a token). Tested locally (Git 2.55, LFS 3.7.1): `*.lock` ignores `renv.lock`
  too; negation under an excluded directory has no effect; `git check-ignore -v` exits 0 for a negated match; tracked files are never
  reported; `core.autocrlf=true` comes from the Git for Windows system config; `.gitattributes` beats autocrlf and `--renormalize`
  works; local `git archive` includes LFS content while GitHub archives default to pointers; `export-ignore` works; read-only flag via
  `Sys.chmod` works on Windows; `zip::zip` and `git archive` set the UTF-8 flag; cffr validation catches non-ISO dates and non-SPDX
  licences but `cff_write(validate = TRUE, verbose = FALSE)` still wrote an invalid file. Finding about the user's setup:
  `Sync_Home_Work` is a Syncthing folder with no `.stignore` and seven Git repositories inside (no damage found in this one; unknown
  whether a second device syncs it); an empty untracked directory `llm-skills/file4b984174891` exists (origin unknown, left alone).
  Proposed split and refactor of `data-repository-readme` are in ledger section 7; five questions for the user in section 9.
  Also added `!renv.lock` next to `!uv.lock` in `.gitignore` (same `*.lock` incident class). Not done: any skill file, link audit, tests of
  repository APIs, `git filter-repo`, gitleaks, DVC, DataLad.

- 2026-10-23 (round 2, same research): User decisions recorded in ledger section 10: three skills (RRD, GIT, README refactor); target repositories
  Dryad, Figshare, Zenodo, institutional; target journals Oecologia, Behavioral Ecology and Sociobiology, Ecosphere, Behavioral Ecology and Computers
  and Electronics in Agriculture; Syncthing only as a short hazard note; DVC/DataLad as a decision table with plain-language explanation. Journal
  policies collected from search excerpts only (pages blocked): Behavioral Ecology needs CSV data plus README archived at submission (GitHub not
  accepted, code not required, no Dryad fee payment from 2026); Ecosphere/ESA needs data and novel code on acceptance; CEA (Elsevier Option C)
  requires deposit or a reason plus a data statement at submission; Springer journals require a data availability statement. Zenodo sandbox test
  with the user's token **failed with HTTP 403** on authenticated endpoints (public endpoint 200), probably a production token or missing
  scopes; the token was used in memory only and is deliberately not recorded anywhere; user should revoke it and store a new sandbox token as
  `ZENODO_SANDBOX_TOKEN` in `~/.Renviron`. Standing rule for tokens: never write them to files, memory or commits.

- 2026-10-23 (round 3, same research): Zenodo **sandbox test completed** with a working sandbox token (first one was a mismatch, revoked by the user). Findings in ledger
  10.3: zen4R 0.10.6 `sandbox = TRUE` uses the host `zenodo-rdm-qa.web.cern.ch` (same backend as `sandbox.zenodo.org`; pass `url = "https://sandbox.zenodo.org/api"` explicitly),
  draft create, tiny upload, read back and draft delete worked, nothing published, `setUploadType` deprecated, `addCreator` with an affiliation string 404s, `record$getFiles`
  not a method. Token never written anywhere. User decision (ledger 10.4): large files stay on university servers and are deposited or linked from there, never stored in GitHub
  repositories, so GIT covers no LFS or DVC walkthrough and RRD gets a manifest and checksum step plus a README line on where the original data live.

- 2026-10-23: Built `git-for-research-projects` (SKILL.md; `scripts/audit_repo.R` with `audit_repo()`, `release_check()`, `data_manifest()`,
  `verify_manifest()`, `write_citation_cff()`; `assets/gitignore-research`, `assets/gitattributes-research`; references `ignore-and-attributes`,
  `secrets-and-history`, `data-and-large-files`, `releases-and-citation`, `windows-and-sync`, `sources`). Scope follows ledger sections 7 and 10:
  no LFS/DVC walkthrough (plain-language table only), Syncthing as one short hazard note, data stay on the server with a tracked manifest.
  Online checks: Agent Skills spec, Anthropic best practices, git gitignore docs, GitHub sensitive-data docs, Quarto `_freeze` page (commit it).
  CRAN check: `gitignore` 0.1.8 (toptal templates; its R template ignores `docs/`, so only a starting block), `git2rdata` 0.5.2 (installed, not tested),
  `cffr`, `gert`, `usethis` (`git_vaccinate()` edits the global ignore, not run); no CRAN secret scanner found. Tested (Windows, Git 2.55, R 4.6.0):
  audit on a seeded scratch repo (all checks fired; first run missed `token <- "..."` because the pattern required `=` or `:`, fixed), no false
  positives on this repo except the true sync-folder finding; manifest round trip; `write_citation_cff()` (bug found and fixed: `lapply(authors,
  as_cff_person)` gave nested authors, ORCID survives only as `(ORCID: <https://orcid.org/...>)`; invalid SPDX licence and malformed author rejected;
  one earlier nested-authors file validated as TRUE, unexplained, a later direct test returned FALSE); `release_check()` before/after tagging;
  starter `.gitignore`/`.gitattributes` in a scratch repo; `uvx git-filter-repo --sensitive-data-removal` on a clone (works, keeps `origin`).
  `lint_skills()` and `check_skill_links()` clean (22 skills), `skills-ref` valid for the new skill and the three edited ones. Backlinks added in
  `r-reproducible-pipeline`, `python-reproducible-pipeline`, `data-repository-readme`; one `no-backlink` row (`hpc-job-scripts`). Not tested: Linux/macOS,
  push or GitHub Support side of a rewrite, gitleaks, pre-commit, case collisions and long paths, real Zenodo release, `git2rdata`, submodules.

- 2026-10-23: Built `reproducible-research-data` (SKILL.md; `scripts/check_deposit.R` with `check_deposit()` and `stage_deposit()`;
  references `repositories`, `journal-policies`, `contents-and-layout`, `licences-and-identifiers`; assets `data-availability-statements.md`,
  `deposit-checklist.md`). User decisions: external links not a hard requirement; institutional questions are resolved when the skill
  triggers (Aarhus ERDA and ULiège Dataverse are worked examples); pages that cannot be fetched are handled at trigger time (ask the user
  to paste text). Online sources: ERDA AU guidance portal (page read) and ERDA user guide v8 April 2026 (PDF read with `pdftotext`; the
  fetch tool shows only binary), ERDA/ULiège pages as search excerpts; `dataverse.uliege.be` home as excerpt only (fetch and `lib.uliege.be/en`
  failed or 404). **ERDA DOI not established** (front-page text says "AU DOIs", portal and guide do not describe a DOI procedure). **ULiège
  Dataverse limits, eligibility, curation and licence not established.** Refactor of `data-repository-readme`: the Standards section moved to
  `reproducible-research-data/references/licences-and-identifiers.md`, description and step 1 hand off the repository/journal/deposit decisions,
  rules and Related skills point to the new skill, `content-guide.md` CITATION.cff text now points to `git-for-research-projects`; backlinks added
  in `git-for-research-projects` (description trimmed to stay under 950 characters), `r-reproducible-pipeline`, `python-reproducible-pipeline`;
  one `no-backlink` row (`manuscript-figures-ggplot`); `skill-boundaries.md` table and open items updated. Tested on Windows (R 4.6.0): `check_deposit()`
  on a seeded scratch deposit (all intended checks fired; the `.Renviron` test file was blocked by the session guard, so a `secrets.yml` stand-in was used),
  `stage_deposit()` refusals, copy plus manifest, tamper detection. Not tested: case-only collisions, Linux/macOS, SFTP-mounted ERDA, the clean-clone
  procedure end to end, real uploads, trigger queries. Checks: `lint_skills()` no findings (23 skills), `check_skill_links()` clean,
  `check_skill_clashes(new=)` clean at 0.15, `skills-ref` valid for the six touched skills, `check_versions()` zen4R same. The working copies
  of three README-skill files and three neighbour `SKILL.md` files had CRLF; normalised to LF (index was already LF). Not committed yet.

- 2026-10-23 (follow-up, `reproducible-research-data`): user pointed out that Aarhus also has a Dataverse, so the skill must not trust the user's
  own list of institutional repositories. New workflow step 2 "Discover the options": ask for all institutions (current, previous,
  collaborating) and the country, search the web for the library and national offers, query re3data, tabulate what the user named versus
  what else turned up, flag conflicts, let the user choose; new rule "the user's list is a starting point". `repositories.md` now has an
  "Institution discovery" method plus Aarhus and ULiège as worked examples. Findings for Aarhus: AU Library lists Pure, Zenodo, Figshare and
  LOAR (not Dataverse, not ERDA); national **DeiC Dataverse** (dataverse.deic.dk; per-university collection; user guide: 1 GB per file,
  100 files per dataset, curation by the university, Private URL for reviewers) but **AU's access status is unclear** (a DeiC page
  excerpt said only Copenhagen could publish and others were still reviewing agreements; a Roskilde page says all universities get access in
  2026). LOAR lists Aarhus among its institutions (re3data, updated 2024-01-09). ULiège Dataverse in re3data: DOI, CC licences, upload
  restricted to institutional membership, versioning yes (updated 2026-03-30). New `scripts/find_repositories.R`: `re3data_search()`,
  `re3data_search_many()`, `re3data_info()` (keyless re3data beta API, httr2 + xml2). Bugs found and fixed in testing: an absolute XPath
  (`//`) inside a node returned the first record for every row (use `.//`); `local-name()` is needed because the XML has a namespace.
  Findings: re3data search is fuzzy (an "Aarhus" query returned unrelated entries) and incomplete (no DeiC Dataverse), so web search stays
  mandatory. My earlier claim in the same session that ERDA was the Aarhus example without mentioning other options was the gap the user caught.

- 2026-10-23: Second `skill-feedback-triage` run: 4 inbox files (4 use-case entries, 2 lessons, 1 user-correction; one project, so every issue is a single
  report). Outcomes: (1) apostrophe in a single-quoted description breaks frontmatter: `fix`, pitfall added to `github-skill-maintenance/SKILL.md`
  (not re-run, standard YAML behaviour); (2) multi-line edits fail on CRLF working copies: `fix`, CRLF pitfall widened to Markdown and reference files,
  confirmed with `git ls-files --eol`; (3) no guidance for testing neighbouring skills together: `add-note`, proxy-test section in
  `references/testing-skills.md`; (4) institution-discovery user correction: already fixed earlier, rejected as a new change; (5) openalex duplicate
  records in title search: `park` (file stays in the inbox). Working copies of the two edited files normalised to LF. `lint_skills()` clean (23),
  `skills-ref` valid. Not verified: a second independent report for any issue. Watermark set to 2026-10-23T23:23:10.

- 2026-10-24: Built `recipe-notes-formatter` (not committed yet). Files: SKILL.md; `scripts/rn_units.R`, `rn_core.R`, `rn_profile.R`, `rn_web.R`, `test_rn.R`; references `note-format`, `units`, `extraction-and-images`, `tag-profile`, `sources`; assets `example_note.md` (rendered by the code) and `recipe-profile.example.yml`. Decisions from the user (ledger R17-R22): ticked checkbox means not on the shopping list (verified from the Checklist plugin settings: it shows only unticked `#ingredients` items), numeric servings/time, empty Intro/FINISH dropped, metric replaces non-metric (English tbsp/tsp stay), picture downloaded and credited, profile YAML next to the output, never overwrite (backup first), folders checked and created only with permission, author is the note author, timestamps left to Templater. R rather than Python because the user is making an R project; CRAN check found no recipe package (installed `cld2` for language detection). Tested (R 4.6.0, Windows): 14 testthat blocks (offline 13 pass; the live block passes with RN_LIVE=1): unit conversion table, spoons and ambiguous units, temperatures and lengths, quantity parser, safe names, no-overwrite plus backup, folder check, render then check round trip with negative cases, placeholder tags, profile learning with rollup counts and base drift, JSON-LD (@graph, groups, raw-newline repair, durations, images), tier none, microdata, heading groups, ingredient overlap. Live end to end on the user's koket.se source: JSON-LD read, four heading groups found, picture downloaded (jpeg, 105 KB), note rendered and checked clean; chocochili.net gave tier none with usable page text and og:image. Profile learned from the 12 copied samples: drift found (three base views empty). Findings: the `write` tool produced CRLF in the .R files (normalised to LF); literal \u escapes typed into Markdown stayed literal (fixed); `test_file()` changes the working directory (tests handle both). Checks: `lint_skills()` no findings (24 skills), `check_skill_links()` clean after two no-backlink rows (`git-for-research-projects`, `r-reproducible-pipeline`), `check_skill_clashes(new=)` clean at 0.15, `skills-ref` valid, `check_versions()` nothing for the skill; ownership row added to `skill-boundaries.md`. Not tested: picture search for existing notes on real notes, German and other Swedish/Finnish sites, Recipe View thumbnail with the image before the H1, Bases image property, Templater timestamps for files copied in, Linux/macOS, real batch use, trigger queries.

- 2026-10-24: Analysed five new conversation exports in `tmp-examples/` (not committed, git-ignored) for skill-trigger behaviour. Found a clean case
  of an explicit, unambiguous "trigger the appropriate skills" instruction never acted on across four turns (Plan mode, an `explore` subagent, two
  implementation turns heavy with `sbatch`/DeepLabCut edits) in `conversation-export.json` — stronger than the export-1 case already in
  `testing-skills.md` (there it fired two turns late; here it never fired, and the word "skill" never recurred in any later narration). Logged a
  `github-skill-maintenance` lesson (`~/.posit/lessons/inbox/anon_20261024-162307_manual.md`, type `missing-guidance`, `confidence: medium`,
  unreproduced). Distinguished this ("R1", an explicit instruction dropped, checkable and therefore deterministically enforceable) from the
  already-known context-clue undertrigger ("R2", file content implies a skill with no explicit ask, not reliably decidable from content alone).
  Also found, in the same batch, a correct *non*-trigger: the assistant explicitly reasoned that `skill-lessons` did not apply to an ad-hoc `grep`
  mistake (no skill had guided the faulty work) and said so instead of calling the tool — recorded as a good example, not a bug.
  Research (`research/skill-trigger-hooks-ledger.md`): read the long-context instruction-following literature (lost-in-the-middle lineage) and the
  subagent-delegation-starts-clean literature to ground *why* this happens, and read the Posit Assistant hooks reference
  (assistant.posit.co/docs/features/hooks/) live, finding three capabilities not yet used by `skill-lessons`: `UserPromptSubmit` can inspect the
  exact incoming prompt text and inject `additionalContext` or block; `PostToolUse` can inject `additionalContext` as a *non-blocking* nudge, not
  only `decision:"block"`; `SubagentStart`/`SubagentStop` are separate, real events. Built and tested R1 only (decided R2's content-keyword nudge
  isn't worth the false-positive risk yet): new `scripts/skill-trigger-hook.sh` (`UserPromptSubmit` records a pending marker on an explicit
  trigger phrase using a `grep -P` lookahead to exclude questions like "is this a reason to trigger ... skills?"; `PostToolUse` matcher `skill`
  clears it; `Stop` blocks once, generically, without echoing the user's text back, if the marker is still there). Tested with twelve synthetic
  piped payloads (see the ledger for the full list). Registered in the real `~/.posit/assistant/settings.json` (backed up to
  `settings.json.bak-skilltrigger`): a new `UserPromptSubmit` hook, and a second handler added to the existing `PostToolUse`/`Stop` groups
  alongside `lessons-hook.sh` (hooks are additive). Extended `check_sync_setup()` with a matching audit section and ran it against the real
  settings content (read via `bash`/`cat`, passed as `cfg`, same path-guard workaround as the lessons audit) — all `ok`. New
  `github-skill-maintenance/references/skill-trigger-hook.md`; `SKILL.md` workflow step 4, a new pitfall (backticked `scripts/<name>` paths in a
  skill's own body are checked *inside that skill's folder*, so a repo-root script must be named without the `scripts/` prefix there — found while
  writing this), and tested/not-tested notes. `lint_skills()`, `check_skill_links()`, `check_skill_clashes(new=)`, `skills-ref validate` all clean.
  Not tested: the hook firing inside a real conversation turn, `SubagentStop`, Linux/macOS, a second machine.

- 2026-10-24: Ran a test audit of the new `agents-md-maintenance` skill against this repo's own `AGENTS.md`.
  Findings and fixes: (1) the "Auto-sync protocol" section still described the superseded copy/junction
  design (copying skill folders into `~/.posit/assistant/skills/`), contradicting the "Implementation
  notes" section next to it, which documents the actual, current `skills.paths`-points-at-the-clone design
  — merged the two into one "Skill sync" section describing only the current mechanism, with this entry
  recording the old design for history; (2) "Open decisions" carried two already-resolved, struck-through
  bullets (clone-in-place vs. copy; deleting the old `openalex` copy, both done 2026-10-23) — removed from
  the live file, recorded here; (3) no subagent-delegation rule existed anywhere in `AGENTS.md`, which the
  skill requires every reviewed file to carry (conditional wording: delegate narrow, context-heavy,
  low-judgment tasks, not by default) — added a new "Delegating to subagents" section; (4) the "Research
  folder" section's three ledger bullets restated each ledger's internal section index in detail (~20
  lines) — trimmed to one line per ledger (path + topic), since each ledger already carries its own index
  and status column at the top. No other staleness, contradictions, or formatting issues found; the todo
  table, "About the local user", and "Working rules" sections were judged current and adequately terse.

- 2026-10-24: Audited all existing skills (27 `SKILL.md` files) against the standing "Consider a
  subagent-delegation rule per skill" check. Delegated the survey to an `explore` subagent (read every
  `SKILL.md`, report whether a delegation rule already exists and whether the skill's own described
  workflow contains a narrowly-scoped, low-judgment, high-volume step repeated across many items).
  Result: most skills either already push their repeated work into bundled scripts/pipelines with no
  model involved (`codebase-map`, `reproducible-research-data`, `python-reproducible-pipeline`,
  `r-reproducible-pipeline`, `openalex`), or their repetition is judgment-heavy rather than mechanical
  (`git-for-research-projects`'s "read each one before acting", `skill-feedback-triage`'s per-issue
  reproduction, `github-skill-maintenance`'s lint-output triage) — a rule there would be boilerplate.
  One genuine candidate found: `job-opportunity-watch` Step 2 has the assistant itself bulk-skim roughly
  1,000 tier-2 job titles on a baseline run before any triage judgement is applied — mechanical, and the
  titles are exactly the kind of noisy context that doesn't need to live in the main conversation. Added a
  conditional note there (bulk tier-2 skim to a lower-effort subagent on large baseline queues only;
  smaller later-run queues stay inline — explicitly not a default). `lint_skills(skill =
  "job-opportunity-watch")` clean. `agents-md-maintenance` was confirmed as already carrying a related but
  distinct rule (it checks that *project* `AGENTS.md` files carry a delegation rule, not a per-skill
  workflow check), so it was not re-flagged. Not done: `check_skill_links()`/`check_skill_clashes()` (no
  description text changed), a second independent read of the borderline cases
  (`github-skill-maintenance`, `skill-feedback-triage`, `recipe-notes-formatter`).

- 2026-10-24: Triage run (`skill-feedback-triage`) over 22 parsed entries across 16 inbox files plus one
  malformed file the reader silently dropped (`anon_20261024-webfetch-refactor.md` used plain frontmatter +
  prose, not the `## skill: title` template, so `read_lessons()` found zero `##` headers and produced no
  row for it; read manually instead). Found, with the user's approval per issue: (1) three items already
  fixed by earlier work before this run even started — the Plan-mode/subagent skill-trigger drop and the
  implicit file-content-trigger miss were both already addressed by the skill-trigger and file-signal hooks
  built 2026-10-24 (confirmed live: the file-signal hook fired, as expected, while this run was reading a
  lesson file that merely *mentioned* `hpc-job-scripts` by name), and the CRLF-reappears and
  `metadata`-must-be-flat-string pitfalls were already documented in `github-skill-maintenance/SKILL.md`
  almost verbatim, as was `data-repository-readme`'s repository-undecided fallback; (2) one reproduced code
  bug: `job-opportunity-watch`'s `jw_save_run()` crashed with `replacement has 1 row, data has 0` on a first
  run with zero anchors and no prior `anchors_seen.tsv`, because `a$is_new <- TRUE` doesn't recycle into a
  0-row data frame in base R's `$<-.data.frame` — fixed with `a$is_new <- rep(TRUE, nrow(a))`, reproduced
  and re-verified in isolation (full integration test through `jw_save_run()` itself was not run — needs a
  `jobwatch.dir` state fixture); (3) added a decision rule to `agents-md-maintenance` for reference-doc vs.
  full-skill promotion (previously judgment-only) and a note to re-read an always-loaded memory file
  immediately before a full-file overwrite, since another skill's self-triggering hook appended to the same
  file mid-session in one real run; (4) extended `github-skill-maintenance`'s existing CRLF pitfall note to
  cover a mid-task edit failure (not just end-of-batch/before-commit), a shorter-anchor retry tip for a
  multi-line edit that still fails to match after CRLF is ruled out, and an explicit-`\r\n`-on-append
  caveat; (5) by explicit user instruction, parked a reported GAM results-prose convention (edf bucketed
  into five wiggliness categories, a reporting structure for simultaneous-CI difference curves, a
  link-scale/response-scale mixing caveat) as a scope note on the not-yet-built `stats-reporting-and-review`
  todo row rather than adding it to `gam-interpretation` now. Every file touched (`AGENTS.md`,
  `agents-md-maintenance/SKILL.md`, `github-skill-maintenance/SKILL.md`,
  `job-opportunity-watch/scripts/jobwatch.R`) came back CRLF from the editing tools at least once — including
  right after a prior `sed`-normalisation pass — and was re-normalised before lint; this is the exact
  recurring behaviour issue (4) above now documents more explicitly. `lint_skills()`, the external
  `skills-ref validate`, and `check_skill_links()` were clean on all four touched skills after the edits.
  Archived all 16 processed inbox files (including the manually-read malformed one) to
  `~/.posit/lessons/inbox/processed/` and advanced the usage watermark to `2026-10-24T22:29:35`. Not done:
  fixing the lesson-file format gap itself (a lesson entry that doesn't use the `##`-heading template is
  silently dropped by `read_lessons()` with no warning) — worth a follow-up note to `skill-lessons` or a
  `lesson_problems()` check for files that parse to zero rows, but out of scope for this run.

- 2026-10-24: Fixed the lesson-file format gap found in the triage above. `read_lesson_file()` previously
  returned `NULL` for a file with no `## skill: title` heading (e.g. the frontmatter-plus-prose
  `anon_20261024-webfetch-refactor.md`), so it silently vanished from `read_lessons()`'s output with no
  trace. It now returns one placeholder row (`parsed = FALSE`, `skill`/`type`/`confidence` pulled from
  whatever frontmatter exists, everything else `NA`) instead, and `lesson_problems()` gained a check on
  `parsed` as its first, most specific finding. Also fixed two latent gaps noticed while doing this: a title
  of `NA` was never flagged as "no title" (`!nzchar(NA_character_)` is `FALSE`, not `TRUE` — fixed to
  `is.na(title) | !nzchar(title)`), and `known_skill` would try `file.exists()` on an `NA` skill path
  (guarded with `!is.na(skill) & ...`); `lesson_dupes()` now also skips `NA`-skill rows explicitly rather
  than relying on a logical-NA subset (which would have pulled in spurious all-`NA` rows). Tested with two
  synthetic fixtures in a scratch inbox copy (one malformed frontmatter-plus-prose file matching the real
  `anon_20261024-webfetch-refactor.md` shape, one well-formed entry): the malformed file now surfaces three
  `lesson_problems()` rows (no heading, no symptom, no title) instead of zero rows, the well-formed entry is
  unaffected, and `lesson_overview()`/`lesson_dupes()` run without error on the mixed set. `lint_skills()`
  and `skills-ref validate` clean on `skill-feedback-triage`. Not done: a second real-world malformed file
  to confirm the frontmatter-field fallback (`skill`/`type`/`confidence`) generalises beyond the one shape
  seen so far; no `skill-lessons`-side change to make the template easier to follow when writing an entry.
