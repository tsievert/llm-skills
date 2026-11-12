# llm-skills

Repository of custom Posit Assistant skills, synced via GitHub
(https://github.com/tsievert/llm-skills, branch `main`).

## Hard rules (never break; the repo is public)

- **No secrets.** Never write tokens, passwords, API keys or `.env` contents into any file, ledger, commit,
  skill or search query. Check that a secret exists; do not print it.
- **No personal or session data in git.** Never commit or copy verbatim into skills: `AGENTS.local.md`,
  `context-inbox/` contents, lesson files, `usage.tsv`. Anonymise anything drawn from them.
- **Installs.** CRAN and Bioconductor (`BiocManager`) installs and updates are always allowed. Installing from
  GitHub or any other non-CRAN source (for example R-universe) requires stopping and asking the user for explicit
  permission first.

## Layout

See `README.md`'s own Layout section for the folder structure. Two rules not stated there:

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
- `research/stats-reporting-and-review-ledger.md`: `stats-reporting-and-review` (effect sizes via `effectsize`/`report`, power via `pwr`/`simr`, pre-registration via `prereg` — `preregr` was archived from CRAN 2026-07-28, multiplicity); records the cross-skill finding that `report()`'s auto-generated prose conflicts with `manuscript-writing-quarto`'s "no autonomous prose" rule.
- **Always protocol research (standing rule, added 2026-10-24).** Whenever research is done for a skill or decision (web
  searches, page fetches, API checks, local tests), record it in `research/` in the same turn, before answering at length.
  Use one ledger per skill or topic (append to an existing one if the topic matches). Format that is easy to digest: a
  numbered **requirements** table (user decisions with dates), **source tables** with a status column (read, partial,
  blocked, search, meta, not researched), short **facts** with the source URL, **open research items**, and a dated **log**.
  Before searching again, read the ledger and do not repeat a search that has a row. Mention
  the ledger path in the reply so the user can find it.
- **Source-quality rules for all research (standing rule, added 2026-10-30).** (1) Ignore commercial sites (resume/CV services, paid coaching, editing or grant-writing companies, product blogs): they often sell something and their advice is often snake oil. Prefer funders, universities, learned bodies, regulators, primary documents and peer-reviewed work. (2) Ignore sites with clear signs of LLM-generated text (stock phrasing, generic filler, templated sample letters, invented-looking examples). (3) Ignore guidance tuned for a US audience (US-specific norms, funders, systems); general-purpose guidance is fine. Record any source skipped for these reasons in the ledger with status 'skipped: commercial/LLM-like/US'. Skill-specific scope limits (e.g. postdoc and tenure track only) sit in that skill's `SKILL.md` and ledger.
- Conventions: one dated section per research round; record sources fetched, local test results, bugs/gotchas found, open
  questions. R run from the assistant cannot write to the assistant scratch dir; use the git-ignored `tmp-examples/` for tests
  and delete afterwards.

## Context inbox (`context-inbox/`)

Gitignored drop-off folder where the user puts files (conversation exports, scripts, samples) as context for
developing or improving skills. When the user refers to files they "dropped off", or skill work starts with no
other source given, list this folder and read the relevant files. Its contents may contain personal data
(see "Hard rules"); anonymise any lesson drawn from it.

## Working rules

- When writing or changing skill files (SKILL.md, frontmatter, scripts, references),
  always look up current references and guidance online first (Agent Skills spec at
  https://agentskills.io, Posit Assistant docs at https://assistant.posit.co/docs/,
  and best-practice sources) rather than relying on memory.
- The same applies to hooks and sync scripting: check the hooks docs
  (https://assistant.posit.co/docs/features/hooks/) before changing hook config.
- When developing a skill or changing its function, always check the R ecosystem (CRAN) for
  an R package that could improve it (e.g. replace hand-written helpers, add capability).
  - Install permissions are in "Hard rules" above.

### Standing rules for all skills (added 2026-10-23)

- **HPC skills run locally.** Every HPC-related skill (`hpc-*`, `deeplabcut-hpc`, and any skill that ships sbatch/cluster
  scripts such as `keypoint-moseq`) must state in a "Where this skill runs" section that the assistant
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
  commit, always load and follow the `github-skill-maintenance` skill: run `lint_skills()` (and `uvx --from skills-ref agentskills validate`
  for the skill) and fix or report every error and warning, run `check_versions()` if the skill names package versions,
  and state in the reply what was checked and what was not. Do not use the words "ready" or "done" while errors remain.
- **Capture lessons (added 2026-10-23).** Every skill except `skill-lessons` must end with a section "Capture lessons
  (self-improvement rule)" that points to the `skill-lessons` skill (generic, anonymised entries into
  `~/.posit/lessons/inbox/`). New skills must include it; `lint_skills()` errors without it. Entries are triaged here with
  `skill-feedback-triage`.
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

## Skill sync

Skills load directly from this clone via `skills.paths` in `~/.posit/assistant/settings.json`, and a
`SessionStart` hook (`scripts/sync-skills.sh`, once per 24 h, fast-forward only, fails open) keeps the clone
current. Keep the settings file identical on every machine and never hard-code a user name in it. Details,
the exact hook command and the decided defaults (removed skills, dirty clone):
`github-skill-maintenance/references/sync-and-config-facts.md`; audit with `check_sync_setup()`.

## Todo: skills to create

Full build history, test notes and findings for every row below are in
[`HISTORY.md`](HISTORY.md) — this table only tracks current status and what (if
anything) is still open. Before starting a new one: follow the working rules above
(check agentskills.io docs, check CRAN for helpers, use `create-skill`).

| Skill | Status | Scope / still open |
|---|---|---|
| `mixed-models-glmm` | done | lme4/glmmTMB/DHARMa/performance/emmeans for repeated-measures trials |
| `animal-behaviour-tracking-analysis` | partial | DLC metrics and their statistics (kpms split out 2026-10-29). Open: validate immobility/freezing thresholds against manual scoring, real-data tests. |
| `keypoint-moseq` | done | kpms fitting, kappa, known user problems, syllable statistics; research in `research/keypoint-moseq-ledger.md`. Last checked against kpms 0.8.6 (2026-11-09, CPU, synthetic). Open: GPU/Slurm runs, real data, `apply_model`, grid movies. |
| `reproducible-research-data` | done | FAIR data deposits, data dictionaries, renv/uv lockfiles, Quarto manuscripts |
| `manuscript-figures-ggplot` | done | journal-ready ggplot2 figures (CVD-safe palettes, sizing, export) |
| `stats-reporting-and-review` | done | Effect sizes, power, pre-registration (`prereg`; `preregr` archived from CRAN 2026-07-28, do not use), multiplicity, reviewer responses. `report()` output is a scaffold only. Open: GAM results-prose convention not yet added to `gam-interpretation`. |
| `chemical-ecology-data` | not started | GC-MS (xcms/MSnbase), compound annotation, PERMANOVA/PCA/PLS-DA — narrow use, confirm the user still does pheromone chemistry before building |
| `github-skill-maintenance` | done | skill lint/test/link/clash workflow |
| `recipe-notes-formatter` | done | plain text/Obsidian notes/links → recipe notes; open: trial run on a real batch, Obsidian thumbnail/Bases image property |
| `literature-review-workflow` | not started, low priority | extend `openalex`: screening log, dedup, PRISMA flow, BibTeX export |
| `r-reproducible-pipeline` | done | targets + renv + Quarto, HPC via crew.cluster |
| `manuscript-writing-quarto` | done | Quarto manuscript structure, CRediT helper (`CRediTas`), spelling/grammar/bibliography linting (LanguageToolR installed with permission 2026-10-26). Open: link checking, end-to-end tests of a journal template, MECA bundle and non-Windows LanguageTool. |
| `manuscript-writing-coach` | done 2026-11-10, unproven | Chat-only content coaching for scientific manuscripts (claim-evidence fit, section checks, writer's-block question skeleton, reporting-guideline pointers, no drafting, no inserted references); read-only `scripts/number_consistency.R` (abstract vs body numbers); `.bib` open-full-text check via the `openalex` script. Research in `research/manuscript-writing-coach-ledger.md`; leftover hand-off list in `research/HANDOFF-manuscript-writing-coach.md`. Hand-offs, ownership row, backlinks and clash check done; proxy trigger test 29/30 on should-trigger, 3/30 near-miss slips. Open: `uvx --from skills-ref agentskills validate` (user shell), number script on a real manuscript, `.bib` check on more papers, Zotero exports, live trigger test (first real-file test and claim comparison done 2026-11-10, ledger sections 15-16). |
| `python-r-interop` | not started | reticulate/uv, Arrow/parquet exchange, Windows PATH pitfalls (see `python-reproducible-pipeline`'s `environments-and-pinning.md`) |
| `git-for-research-projects` | done | git conventions, `.gitignore`/`.gitattributes`, release tagging/Zenodo |
| `grant-and-cv-support` | not started | OpenAlex/ORCID → CV/grant formatting; **caveat:** no automatic prose, every edit user-approved |
| `python-reproducible-pipeline` | mostly done | uv + Snakemake, HPC via Slurm executor plugin |
| `codebase-map` | done | per-project inventory/codemap/depends files, self-updating hook (hook deliberately not registered globally — needs per-project opt-in) |
| `staged-assistant-workflow` | done, unproven | Stage table, status function, file hand-offs, gates for long or recurring assistant workflows; promoted early on one report. Open: not yet applied to a second workflow. |
| `application-style-coach` | done, unproven | Chat-only style coaching for academic applications (English); research in `research/application-style-coach-ledger.md`. Open: live trigger test, real applications. |
| `tidy-data-wrangling` | done, unproven | R tidyverse reshaping, cleaning, joins, messy spreadsheets; read-only `scripts/audit_table.R`; research in `research/tidy-data-wrangling-ledger.md`. Open: live trigger test, real messy file, Python variant. |
| `job-opportunity-watch` | done, staged pipeline (s0-s6), partly unproven | Weekly job search over a user links file and profile; research in its ledger. Open: Brave Search API source, platform APIs untested, `skills-ref validate` not run. |

## History

A detailed, dated log of what was built, tested and found while developing this repo
lives in [`HISTORY.md`](HISTORY.md), kept out of this file so it isn't reloaded into
every conversation's context. Read it on demand rather than up front. When finishing a
skill, a research round, or a triage run, append an entry there (not here).

## Lessons triage state

- Lessons usage watermark: 2026-11-12T22:20:01

The watermark above is read/written by `skill-feedback-triage/scripts/read_lessons.R`'s
`triage_watermark()`/`triage_watermark_set()`, which default to `agents = "AGENTS.md"` —
keep this line (and this heading) in `AGENTS.md` itself, not in `HISTORY.md`. The
narrative notes for each triage run (counts, outcomes, what was fixed) are in
`HISTORY.md` instead.

