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
  SimBA/B-SOiD/VAME, validation of immobility/freezing thresholds against manual scoring, real-data tests.
  Link to `deeplabcut-hpc`.
- [ ] `reproducible-research-data`: FAIR data deposits (Figshare "Data for:" style), data dictionaries,
  `renv`/`uv` lockfiles, Quarto manuscripts, code and data archive per paper.
- [ ] `manuscript-figures-ggplot`: journal-ready figures (colour-blind-safe palettes, size/DPI, patchwork panels,
  consistent themes, export). Link to the model skills.
- [ ] `stats-reporting-and-review`: effect sizes and uncertainty, power/sample size, pre-registration,
  reviewer-response drafting, checks for pseudoreplication, multiple testing, p-hacking.
- [ ] `chemical-ecology-data`: GC-MS peak processing in R (xcms, MSnbase), compound annotation, multivariate
  analysis (PERMANOVA, PCA, PLS-DA). Narrow use; confirm the user still does pheromone chemistry.
- [ ] `github-skill-maintenance`: skill test/lint workflow, review of `sync-skills` hook and `skills.paths`
  config, version notes, periodic check for stale package-version claims in `gam-mgcv`, `gam-interpretation`,
  `deeplabcut-hpc`.
- [ ] `literature-review-workflow`: extend `openalex` with screening log, deduplication, PRISMA-style flow,
  BibTeX export for Quarto. Lower priority (search step already covered).

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
