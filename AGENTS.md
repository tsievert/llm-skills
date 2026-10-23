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
- Useful context for future tasks: works with GAMs (mgcv, gratia), HPC/Slurm clusters, DeepLabCut, R and Python.
  Check the OpenAlex profile for their publications to infer field conventions or to find their own papers
  (e.g. for self-citation checks or "my work on X" requests).
