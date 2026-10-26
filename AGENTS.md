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

Personal/identifying details (name, email, ORCID, GitHub handle, machine path, research field) live in
`AGENTS.local.md` at the repo root, which is gitignored and **not present in the public repo**. If that file
exists on this machine, read it for this context. If it doesn't (e.g. a fresh clone, or on someone else's
machine), treat this context as simply unavailable rather than guessing or inventing it — do not ask the user
to re-paste it unless the task actually needs it.

## Research folder (`research/`)

`research/` holds working notes gathered before a skill is written. These are not skills (no SKILL.md, not synced as skills).
Read the relevant file first when starting or revising a skill, and append to it instead of starting a new one. Each ledger
carries its own section index at the top (including a status column for what's read vs. only a lead) — read that instead of
duplicating it here.

- `research/pipeline-resources-ledger.md`: `python-reproducible-pipeline`, `r-reproducible-pipeline`, planned `python-r-interop`.
- `research/data-and-git-ledger.md`: `reproducible-research-data`, `git-for-research-projects`, the `data-repository-readme` refactor.
- `research/recipe-notes-ledger.md`: `recipe-notes-formatter`.
- `research/manuscript-writing-quarto-ledger.md`: planned `manuscript-writing-quarto` (Quarto manuscript/journal templates, CRediT helper via CRAN `CRediTas`, spelling/linting via `hunspell`/`spelling`).
- `research/stats-reporting-and-review-ledger.md`: planned `stats-reporting-and-review` (effect sizes via `effectsize`/`report`, power via `pwr`/`simr`, pre-registration via `preregr`, multiplicity); records the cross-skill finding that `report()`'s auto-generated prose conflicts with `manuscript-writing-quarto`'s "no autonomous prose" rule.
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

- **Consider a subagent-delegation rule per skill (added 2026-10-24).** When creating or substantially changing a skill,
  check whether its own workflow has a narrowly-scoped, low-judgment, high-volume step (e.g. per-file/per-sample checks,
  a mechanical search or edit repeated across many items, summarizing many logs or outputs) that would benefit from a
  skill-specific conditional rule to hand that step to a cheap/low-effort subagent, mirroring the repo-wide "Delegating
  to subagents" rule below but naming the skill's own concrete trigger. This is a judgment call, not a requirement for
  every skill: most skills have no such step, and adding the rule where it doesn't fit just adds boilerplate. Only add
  it to a skill's `SKILL.md` when a genuine case exists; otherwise skip silently rather than padding the file.

## Delegating to subagents

Delegate narrowly-scoped, low-judgment tasks (a mechanical search across many files, a repetitive edit
pattern, summarizing a large log or output) to a subagent — especially one that can run with lower effort
or a cheaper/smaller model — when doing it inline would mean loading a lot of noisy context (many files,
logs, search results) into the main conversation that won't be needed again. Don't delegate by default:
single-file edits, ambiguous-scope work, or tasks needing the main conversation's accumulated context are
usually cheaper and more reliable done directly, and fanning out many subagents on one task can burn more
tokens than it saves if they aren't genuinely lower-cost.

## Skill sync (installed and verified live, 2026-10-23)

Goal: skills are installed globally (all projects) and kept current with GitHub. Current mechanism —
no copying: `skills.paths` in `~/.posit/assistant/settings.json`
(https://assistant.posit.co/docs/reference/config-file/) points directly at this clone, replacing the
defaults (so the setting repeats them: `~/.agents/skills`, `~/.posit/assistant/skills`, `.agents/skills`,
`.posit/assistant/skills`, plus this clone last). A `SessionStart` hook keeps the clone itself current:

- Hook script `scripts/sync-skills.sh` (versioned in this repo): throttles via
  `~/.posit/state/llm-skills-last-check` (skip if checked within 24 h), `git fetch origin main`, and
  `git pull --ff-only` if `origin/main` has moved. Fails open (dirty tree or offline: skip and warn,
  never block the session). Derives the repo dir from its own location.
- Registered in `~/.posit/assistant/settings.json` (global, so it runs regardless of workspace trust),
  `timeout` ~20 s. On Windows, shell-form commands run under `cmd.exe`, so the entry calls
  `bash C:/Users/thorb/Sync_Home_Work/llm-skills/scripts/sync-skills.sh` explicitly (Git Bash).
- Newly pulled skills are available from the next conversation; a mid-session rescan is unverified.

## Open decisions

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
| `stats-reporting-and-review` | not started, researched 2026-10-26 | effect sizes/uncertainty, power/sample size, pre-registration, reviewer-response drafting, pseudoreplication/multiple-testing checks; also a GAM results-prose convention (edf bucketed into near-zero/negligible/weak/moderate/pronounced rather than a raw range, edf framed as wiggliness not effect size, significant time-window + peak response-scale difference for simultaneous-CI difference curves, never mixing link-scale CIs with response-scale estimates, flag uncorrected multiplicity across narrated contrast curves) reported 2026-10-24 from one project's independent convention — decide then whether it lives here or gets folded into `gam-interpretation`. Research done — see `research/stats-reporting-and-review-ledger.md`: wrap CRAN `effectsize` for effect sizes/CIs (sits downstream of `mixed-models-glmm`/`gam-mgcv`, don't re-fit); `pwr` + `simr` for power (note `simr` needs `lme4`, not `glmmTMB`); `preregr` for pre-registration forms; `stats::p.adjust`/`emmeans(adjust=)` already cover multiplicity, no gap. Key cross-skill finding: easystats `report()` auto-writes manuscript prose from models — conflicts with `manuscript-writing-quarto`'s "no autonomous prose" rule; use only as a reviewable scaffold, never paste verbatim, write this boundary into both skills. No tool found yet for reviewer-response drafting (open). |
| `chemical-ecology-data` | not started | GC-MS (xcms/MSnbase), compound annotation, PERMANOVA/PCA/PLS-DA — narrow use, confirm the user still does pheromone chemistry before building |
| `github-skill-maintenance` | done | skill lint/test/link/clash workflow |
| `recipe-notes-formatter` | done, not committed | plain text/Obsidian notes/links → recipe notes; open: trial run on a real batch, Obsidian thumbnail/Bases image property |
| `literature-review-workflow` | not started, low priority | extend `openalex`: screening log, dedup, PRISMA flow, BibTeX export |
| `r-reproducible-pipeline` | done | targets + renv + Quarto, HPC via crew.cluster |
| `manuscript-writing-quarto` | done, not committed | Quarto manuscript structure (`project: type: manuscript` + `quarto-journals` decision tree), CRediT helper wrapping CRAN `CRediTas` (`scripts/credit.R`), flags-only linting: spelling via `spelling`/`hunspell` and bibliography/non-standard-character checks (`scripts/check_manuscript.R`), plus grammar via LanguageTool wrapped through the GitHub package `LanguageToolR` (`scripts/check_grammar.R`, installed with user permission 2026-10-26). Lints clean, no link/clash findings, `skills-ref validate` passes. Open: link checking (noted as a gap in `references/linting-checklist.md`, not built); no end-to-end test of an installed `quarto-journals` template, a rendered MECA bundle, or LanguageTool on non-Windows. |
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

- Lessons usage watermark: 2026-10-26T10:12:11

The watermark above is read/written by `skill-feedback-triage/scripts/read_lessons.R`'s
`triage_watermark()`/`triage_watermark_set()`, which default to `agents = "AGENTS.md"` —
keep this line (and this heading) in `AGENTS.md` itself, not in `HISTORY.md`. The
narrative notes for each triage run (counts, outcomes, what was fixed) are in
`HISTORY.md` instead.

