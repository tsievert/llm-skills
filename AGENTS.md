# llm-skills

Repository of custom Posit Assistant skills, synced via GitHub
(https://github.com/tsievert/llm-skills, branch `main`).

## Layout

- One folder per skill at the repo root: `<skill-name>/SKILL.md`
  (YAML frontmatter with `name` and `description`; optional `scripts/`,
  `references/`, `assets/`). Follows the Agent Skills spec (https://agentskills.io).
- Folder name must match the `name` in the frontmatter.
- Use the `create-skill` skill when authoring a new skill.

## Working rules

- When writing or changing skill files (SKILL.md, frontmatter, scripts, references),
  always look up current references and guidance online first (Agent Skills spec at
  https://agentskills.io, Posit Assistant docs at https://assistant.posit.co/docs/,
  and best-practice sources) rather than relying on memory.
- The same applies to hooks and sync scripting: check the hooks docs
  (https://assistant.posit.co/docs/features/hooks/) before changing hook config.
- When developing a skill or changing its function, always check the R ecosystem (CRAN) for
  an R package that could improve it (e.g. replace hand-written helpers, add capability).
  - Installing or updating from CRAN is always allowed without asking.
  - Installing or updating from Bioconductor (via `BiocManager`) is also always allowed without asking (rule added 2026-10-23).
  - Installing or updating from GitHub (or any non-CRAN source, e.g. R-universe) requires
    stopping and asking the user for explicit permission first.

### Standing rules for all skills (added 2026-10-23)

- **HPC skills run locally.** Every HPC-related skill (`hpc-*`, `deeplabcut-hpc`, and any skill that ships sbatch/cluster
  scripts such as `animal-behaviour-tracking-analysis`) must state in a "Where this skill runs" section that the assistant
  is NOT intended to run on the cluster. It works locally on the user's computer and adapts scripts for the cluster.
  Information that only the cluster has (versions, partitions, `sacct`, logs, modules) is obtained by prompting the user to
  run the specific command in their own console/shell and paste back the output; never guess. New HPC skills must include
  this section. Checked 2026-10-23: all 8 existing ones comply.
- **Explain the reasoning.** Every skill (new and existing) must tell the assistant to explain briefly why things were or
  were not done (choices, rejected alternatives, skipped checks, assumptions). Purpose: teach the user long-term, not
  replace their thinking. Explanations stay short: a sentence or two, the trade-off, the decision that is the user's,
  a pointer for depth. Implemented as a section "Explain the reasoning (teaching rule)" at the end of each `SKILL.md`;
  new skills must include it.
- **Verify before reporting ready (added 2026-10-23).** Before telling the user that a new or changed skill is ready to
  commit, always load and follow the `github-skill-maintenance` skill: run `lint_skills()` (and `skills-ref validate`
  for the skill) and fix or report every error and warning, run `check_versions()` if the skill names package versions,
  and state in the reply what was checked and what was not. Do not use the words "ready" or "done" while errors remain.
- **Capture lessons (added 2026-10-23).** Every skill except `skill-lessons` must end with a section "Capture lessons
  (self-improvement rule)" that points to the `skill-lessons` skill (generic, anonymised entries into
  `~/.posit/lessons/inbox/`). New skills must include it; `lint_skills()` errors without it. Entries are triaged here with
  `skill-feedback-triage`. Lesson files and `usage.tsv` are never committed.
- **Link skills to each other (added 2026-10-23).** Every skill must point to the neighbouring skills a user would plausibly
  need next, in a short "Related skills" section placed before "Explain the reasoning" (one line per skill, saying what
  it is for; match the wording of the existing sections). When adding or changing a skill, (1) add the forward links, (2)
  check whether each target needs a backlink, and (3) run `check_skill_links()` from `github-skill-maintenance`. A missing
  backlink is a decision, not an automatic fix: add it if someone using the target would plausibly need this skill,
  otherwise record a `no-backlink` row with a reason in `github-skill-maintenance/references/link-decisions.tsv`. Do not
  let generic skills (`hpc-*`, `openalex`) collect a pointer to every domain skill. Planned skills that do not exist yet
  are not linked until they are written.

## Auto-sync protocol (status: installed and verified in a live session)

Goal: skills are installed globally (all projects) and kept current with GitHub.

- Install location: `~/.posit/assistant/skills/<skill-name>/SKILL.md` (user level).
  Project-level skills (`.posit/assistant/skills/`) are NOT used for this.
- Mechanism: a `SessionStart` hook in `~/.posit/assistant/settings.json`
  (global file, so it runs regardless of workspace trust).
- Hook script (`~/.posit/hooks/sync-skills.sh`, to be written):
  1. Exit early if a timestamp file shows a check within the last 24 h.
  2. `git fetch origin main`; compare local `HEAD` with `origin/main` (commit hash).
  3. If different, `git pull --ff-only`, then copy/sync skill folders into
     `~/.posit/assistant/skills/` (or use a junction if the clone is placed there).
  4. Print one line to stdout (e.g. `Skills updated: abc123 -> def456`), which is
     added to the session context. Stay silent on no change or when offline.
- Hook settings: `timeout` ~20 s; fails open on error. On Windows shell-form
  commands run under `cmd.exe`, so call `bash <script>` (Git Bash) explicitly.
- Caveat: newly pulled skills may only be available from the next conversation;
  mid-session rescan is unverified.
- Existing user skill `openalex` lives in `~/.posit/assistant/skills/` and is not
  in this repo yet. Decide whether to move it in before syncing, so a sync never
  overwrites or deletes it.

## Implementation notes (from docs, 2026-10-23)

- Posit Assistant supports `skills.paths` in `~/.posit/assistant/settings.json`
  (https://assistant.posit.co/docs/reference/config-file/). This makes junctions/copies
  unnecessary: point `skills.paths` at this clone. Later paths win on name conflicts.
- Setting `skills.paths` REPLACES the defaults, so repeat them: `~/.agents/skills`,
  `~/.posit/assistant/skills`, `.agents/skills`, `.posit/assistant/skills`, plus this clone
  (`~/Sync_Home_Work/llm-skills`) last.
- Script: `scripts/sync-skills.sh` (versioned in this repo). Derives the repo dir from its
  own location, throttles via `~/.posit/state/llm-skills-last-check`, fails open.
- Hook entry (installed in global settings on 2026-10-23, together with `skills.paths`):
  `{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"bash C:/Users/thorb/Sync_Home_Work/llm-skills/scripts/sync-skills.sh","timeout":20}]}]}}`
- Docs say new skills are available "in your next conversation".

## Open decisions

- ~~Clone-in-place vs. copy~~ Resolved: use `skills.paths` (see implementation notes).
- ~~Delete the old `~/.posit/assistant/skills/openalex`~~ Done 2026-10-23 (repo copy replaces it).
- Whether sync should delete skills removed from the repo (default: no).
- Handling local uncommitted edits in the clone (default: skip pull and warn).

## Todo: skills to create (planned 2026-10-23; `[~]` = partly done)

Before each: follow the working rules above (check agentskills.io docs, check CRAN for helpers, use `create-skill`).

- [x] `mixed-models-glmm` (done 2026-10-23, see Log): lme4, glmmTMB, DHARMa, performance, emmeans. Repeated-measures behaviour trials,
  random effects, zero inflation, overdispersion, model selection, residual checks, reporting. Link to `gam-mgcv`.
- [~] `animal-behaviour-tracking-analysis`: v1 (keypoint-MoSeq) and v2 (basic DLC metrics) done, see Log. Still open:
  validation of immobility/freezing thresholds against manual scoring, real-data tests.
  SimBA/B-SOiD/VAME are out of scope for now (decision 2026-10-23). Link to `deeplabcut-hpc`.
- [ ] `reproducible-research-data`: FAIR data deposits (Figshare "Data for:" style), data dictionaries,
  `renv`/`uv` lockfiles, Quarto manuscripts, code and data archive per paper.
- [x] `manuscript-figures-ggplot` (done 2026-10-23, see Log; not yet committed): journal-ready figures (colour-blind-safe
  palettes, size/DPI, patchwork panels, consistent themes, export). Link to the model skills.
- [ ] `stats-reporting-and-review`: effect sizes and uncertainty, power/sample size, pre-registration,
  reviewer-response drafting, checks for pseudoreplication, multiple testing, p-hacking.
- [ ] `chemical-ecology-data`: GC-MS peak processing in R (xcms, MSnbase), compound annotation, multivariate
  analysis (PERMANOVA, PCA, PLS-DA). Narrow use; confirm the user still does pheromone chemistry.
- [x] `github-skill-maintenance` (done 2026-10-23, see Log): skill test/lint workflow, review of `sync-skills` hook and `skills.paths`
  config, version notes, periodic check for stale package-version claims in `gam-mgcv`, `gam-interpretation`,
  `deeplabcut-hpc`.
- [ ] `literature-review-workflow`: extend `openalex` with screening log, deduplication, PRISMA-style flow,
  BibTeX export for Quarto. Lower priority (search step already covered).
- Added 2026-10-23 (user-approved from the reassessment). Each follows the working rules and standing rules (online check
  first, CRAN check, teaching section, capture-lessons section, verify with `github-skill-maintenance`):
  - [ ] `r-reproducible-pipeline`: targets, renv and Quarto project structure for multi-step analyses, re-running the whole
    analysis including on HPC (`crew.cluster`, `future.batchtools`). Distinct from `reproducible-research-data` (the deposit).
    If it ships cluster scripts it needs the "Where this skill runs" section (assistant runs locally only).
  - [ ] `manuscript-writing-quarto`: Quarto manuscripts with journal templates, CSL, cross-references, supplementary material,
    co-author review. **Caveat: not for autonomous writing.** Scope is linting, layout and proofreading only. Every edit needs
    explicit user approval (show a diff or list first). **Never edit `.bib` files automatically**; propose entries or fixes as
    text for the user to apply. No large generated prose.
  - [ ] `python-r-interop`: reticulate and uv environments, R/Python data exchange via Arrow/parquet, Windows pitfalls seen in
    this repo (blocked `~/.posit` paths from the R session, hdf5r dimension order, pandas pins).
  - [ ] `git-for-research-projects`: Git conventions for analysis repos, large files (git-lfs, DVC), `.gitignore` for data and
    secrets, release tagging linked to Zenodo DOIs. Overlaps `github-skill-maintenance` only in commit steps.
  - [ ] `grant-and-cv-support`: publication, citation and funding data from OpenAlex and ORCID, formatting for CVs and grant
    applications (narrative CV, DORA style, output summaries). **Caveat as for the manuscript skill:** no large automatic prose
    generation; most text is written by the user; the assistant structures, checks and formats, and every edit is user-approved.
    Pairs with `job-opportunity-watch`.
  - [~] `python-reproducible-pipeline` (drafted 2026-10-23, see Log; not yet committed): Python counterpart of `r-reproducible-pipeline`. uv (pyproject, lockfile, pinned Python),
    multi-step workflow tools (Snakemake, or DVC/Prefect/Dagster; compare and pick with the user), config and seeds, notebooks
    or Quarto as the report layer, re-running the whole chain including on HPC (Snakemake Slurm executor plugin). Pairs with
    `python-r-interop` and `hpc-python-code`. If it ships cluster scripts it needs the "Where this skill runs" section.

## Log

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
  structures, pbkrtest bootstrap with glmmTMB, brms. Not yet committed.
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
  `check_versions()` OK for frictionless. Not tested: Excel/HDF5 input, real submissions. Not yet committed.
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
  Not read: Rennie workshop slides, Posit cheatsheet content pages. Not yet committed.

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


## About the local user

- Name: Thorbjörn Sievert (git `user.name`; email `thorbjoern.sievert@gmx.net`, git `user.email`).
- GitHub: https://github.com/tsievert (this repo: https://github.com/tsievert/llm-skills).
- OpenAlex author profile: https://openalex.org/A5050945345 (API: https://api.openalex.org/authors/A5050945345).
  Found 2026-10-23 as the single hit for "Thorbjörn Sievert": 20 works, 235 citations, last known institution
  University of Jyväskylä. Profile not manually verified; the ORCID below came from OpenAlex itself.
- ORCID: https://orcid.org/0000-0002-4242-3779
- Machine: Windows 11, RStudio, R 4.6.0 with Rtools45, Git Bash. Home sync folder: `C:\Users\thorb\Sync_Home_Work`.
- Standing preferences (see user memory): use OpenAlex, not web search, for literature tasks; prefer
  `openalexR`/`httr2` or the `openalex` MCP server.
- Research field (from OpenAlex works list, 2026-10-23; 15 works 2015-2021, not manually verified): behavioural
  ecology of small mammals, mainly bank voles (predation risk, predator odour, alarm pheromones, transgenerational
  and in utero effects), plus chemical senses (predator odour components in mice) and small-rodent population
  cycles (Oecologia review, ~159 citations). Venues: Oecologia, Ecosphere, Behavioral Ecology and Sociobiology,
  Frontiers in Ecology and Evolution, Integrative Zoology, Chemical Senses. Publishes datasets on Figshare
  ("Data for: ..." entries). Earlier affiliation KTH (Sweden), later Jyväskylä (Finland). Data likely: behavioural
  trials, repeated measures/mixed models, chemical (pheromone) analysis, field trapping/population time series.
- Useful context for future tasks: works with GAMs (mgcv, gratia), HPC/Slurm clusters, DeepLabCut, R and Python.
  Check the OpenAlex profile for their publications to infer field conventions or to find their own papers
  (e.g. for self-citation checks or "my work on X" requests).

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
