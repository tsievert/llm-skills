# llm-skills

Repository of custom Posit Assistant skills, synced via GitHub
(https://github.com/tsievert/llm-skills, branch `main`).

## Layout

- One folder per skill at the repo root: `<skill-name>/SKILL.md`
  (YAML frontmatter with `name` and `description`; optional `scripts/`,
  `references/`, `assets/`). Follows the Agent Skills spec (https://agentskills.io).
- Folder name must match the `name` in the frontmatter.
- Use the `create-skill` skill when authoring a new skill.

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

## Research folder (`research/`)

`research/` holds working notes gathered before a skill is written. These are not skills (no SKILL.md, not synced as skills).
Read the relevant file first when starting or revising a skill, and append to it instead of starting a new one.

- `research/pipeline-resources-ledger.md`: shared ledger for `python-reproducible-pipeline`, `r-reproducible-pipeline` and the
  planned `python-r-interop`. Sections: 1 shared concerns, 2 Python tools, 3 R tools, 4 Quarto, 5 design observations,
  8-10 rounds 2-4 (Prefect/Dagster/Nextflow docs, crew.cluster, Snakemake rerun triggers, P3M snapshots, `--report`),
  11 round 5 (R side: targets, tarchetypes, crew, renv; local tests; open items in 11.5). Each row states what was read vs only
  seen as a lead, so check the status column before relying on a claim. Versions are dated 2026-10-23; re-check with
  `check_versions()`.
- `research/data-and-git-ledger.md`: for the planned `reproducible-research-data` and `git-for-research-projects` and the refactor
  of `data-repository-readme`. Sections: 1 overlap map, 2 sources (read/blocked/search status), 3 local tests and gotchas
  (gitignore negation, `*.lock` vs `renv.lock`, `check-ignore -v` exit code, autocrlf, LFS vs `git archive`, cffr pitfalls),
  4 git doc facts, 5 packages, 6 OpenAlex, 7 proposed split and refactor, 8 findings about the user's own setup (Syncthing folder
  containing seven repositories), 9 open items and questions for the user.
- `research/recipe-notes-ledger.md` (started 2026-10-24): for the planned `recipe-notes-formatter`. Sections: 1 requirements
  R1-R11 (user decisions), 2 format candidates, 3 Cooklang facts, 4 Cooklang maintenance (bus factor one), 5 Obsidian recipe
  plugins, 6 local Obsidian entry points (CLI, Local REST API, MCP servers), 7 open research items, 8 log.
- **Always protocol research (standing rule, added 2026-10-24).** Whenever research is done for a skill or decision (web
  searches, page fetches, API checks, local tests), record it in `research/` in the same turn, before answering at length.
  Use one ledger per skill or topic (append to an existing one if the topic matches). Format that is easy to digest: a
  numbered **requirements** table (user decisions with dates), **source tables** with a status column (read, partial,
  blocked, search, meta, not researched), short **facts** with the source URL, **open research items**, and a dated **log**.
  Before searching again, read the ledger and do not repeat a search that has a row. Never record tokens or secrets. Mention
  the ledger path in the reply so the user can find it.
- Conventions: one dated section per research round; record sources fetched, local test results, bugs/gotchas found, open
  questions. R run from the assistant cannot write to the assistant scratch dir; use the git-ignored `tmp-examples/` for tests
  and delete afterwards.

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

- **Watch for skill clashes (added 2026-10-23).** The assistant picks a skill from its description alone, so overlapping
  descriptions make two skills load or the wrong one load. When creating or changing a skill: (1) read
  `github-skill-maintenance/references/skill-boundaries.md` (ownership map and description rules) before writing the
  description; (2) run `check_skill_clashes(new = "<skill>")` and resolve every `warn` (narrow the wording, add a hand-off
  sentence naming the neighbour, or record `accepted` with a reason in `references/clash-decisions.tsv`); (3) add the skill
  to the ownership table; (4) do not copy another skill's API or function advice into a body, point to it. A hand-off
  sentence goes in both skills' descriptions. Planned skills (`reproducible-research-data`, `stats-reporting-and-review`,
  `python-r-interop`, `manuscript-writing-quarto`) must define their territory against the table before they are written.

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

## Todo: skills to create

Full build history, test notes and findings for every row below are in
[`HISTORY.md`](HISTORY.md) — this table only tracks current status and what (if
anything) is still open. Before starting a new one: follow the working rules above
(check agentskills.io docs, check CRAN for helpers, use `create-skill`).

| Skill | Status | Scope / still open |
|---|---|---|
| `mixed-models-glmm` | done | lme4/glmmTMB/DHARMa/performance/emmeans for repeated-measures trials |
| `animal-behaviour-tracking-analysis` | partial | DLC metrics + keypoint-MoSeq done; open: validate immobility/freezing thresholds against manual scoring, real-data tests. SimBA/B-SOiD/VAME out of scope |
| `reproducible-research-data` | done | FAIR data deposits, data dictionaries, renv/uv lockfiles, Quarto manuscripts |
| `manuscript-figures-ggplot` | done | journal-ready ggplot2 figures (CVD-safe palettes, sizing, export) |
| `stats-reporting-and-review` | not started | effect sizes/uncertainty, power/sample size, pre-registration, reviewer-response drafting, pseudoreplication/multiple-testing checks |
| `chemical-ecology-data` | not started | GC-MS (xcms/MSnbase), compound annotation, PERMANOVA/PCA/PLS-DA — narrow use, confirm the user still does pheromone chemistry before building |
| `github-skill-maintenance` | done | skill lint/test/link/clash workflow |
| `recipe-notes-formatter` | done, not committed | plain text/Obsidian notes/links → recipe notes; open: trial run on a real batch, Obsidian thumbnail/Bases image property |
| `literature-review-workflow` | not started, low priority | extend `openalex`: screening log, dedup, PRISMA flow, BibTeX export |
| `r-reproducible-pipeline` | done | targets + renv + Quarto, HPC via crew.cluster |
| `manuscript-writing-quarto` | not started | Quarto manuscripts; **caveat:** linting/proofreading only, no autonomous prose, never auto-edit `.bib` |
| `python-r-interop` | not started | reticulate/uv, Arrow/parquet exchange, Windows PATH pitfalls (see `python-reproducible-pipeline`'s `environments-and-pinning.md`) |
| `git-for-research-projects` | done | git conventions, `.gitignore`/`.gitattributes`, release tagging/Zenodo |
| `grant-and-cv-support` | not started | OpenAlex/ORCID → CV/grant formatting; **caveat:** no automatic prose, every edit user-approved |
| `python-reproducible-pipeline` | mostly done | uv + Snakemake, HPC via Slurm executor plugin |
| `codebase-map` | done, not committed | per-project inventory/codemap/depends files, self-updating hook (hook deliberately not registered globally — needs per-project opt-in) |

## History

A detailed, dated log of what was built, tested and found while developing this repo
lives in [`HISTORY.md`](HISTORY.md), kept out of this file so it isn't reloaded into
every conversation's context. Read it on demand rather than up front. When finishing a
skill, a research round, or a triage run, append an entry there (not here).

## Lessons triage state

- Lessons usage watermark: 2026-10-24T17:22:20

The watermark above is read/written by `skill-feedback-triage/scripts/read_lessons.R`'s
`triage_watermark()`/`triage_watermark_set()`, which default to `agents = "AGENTS.md"` —
keep this line (and this heading) in `AGENTS.md` itself, not in `HISTORY.md`. The
narrative notes for each triage run (counts, outcomes, what was fixed) are in
`HISTORY.md` instead.

