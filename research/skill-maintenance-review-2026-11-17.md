# Skill maintenance review (started 2026-11-17)

Task list that survives conversation restarts. Read this file first when the user says "continue the
maintenance review". Update the Status column and the Log as work proceeds. Generic wording only (public repo).

## How this review started

User asked to review which skills had the most uses and edits (via `skill-feedback-triage` data), then check
those skills for scope creep, overlap and bloat, and for sections that need new research. The triage run itself was
NOT archived: no dispositions recorded, watermark not moved, inbox untouched (the `.posit/assistant/lessons-work`
copy was deleted). Open inbox state at that time: 5 new, 8 parked, 60 closed entries.

## Evidence (all-time loads from `~/.posit/lessons/usage.tsv`, 545 rows; commits since 2026-10-15)

| Skill | Loads | SKILL.md | Tree | Note |
|---|---|---|---|---|
| skill-lessons | 176 | 11 KB | 26 KB | mostly hook-fired, weak signal |
| github-skill-maintenance | 52 | 11 KB | 155 KB, 20 files | heaviest reference tree |
| gam-mgcv | 48 | 15 KB | 79 KB | 12 inbox entries, many edits |
| skill-feedback-triage | 43 | 15 KB | 37 KB | |
| deeplabcut-hpc | 22 | 20 KB | 40 KB | largest SKILL.md |
| gam-interpretation / stats-reporting / hpc-job-scripts / manuscript-figures-ggplot / application-style-coach | 19-21 | 8-16 KB | | |

## Tasks

Order = suggested order. Status: todo / in progress / done / dropped.

| # | Task | Skill(s) | Status | Detail |
|---|---|---|---|---|
| 1 | Trim deeplabcut-hpc | deeplabcut-hpc | done 2026-11-17 (SKILL.md 20 KB to 14 KB; new references/pitfall-details.md and upstream-search.md; evidence moved to ledger; pitfalls renumbered 1-12) | Target SKILL.md ~11-12 KB. Move long pitfall detail (items 4, 5, 7, 8, 11a) into a new `references/` file, keep one-line pitfalls in SKILL.md. Fix numbering (11a precedes 11). Move the ~35-line "search upstream before improvising" procedure to `references/`. Move the "Not verified" real-use evidence narrative to `research/deeplabcut-hpc-ledger.md`. Remove "reported once" asides that carry no instruction. Keep the "Where this skill runs", Related, Teaching and Capture sections. Check the `hpc-job-scripts` PATH note is a pointer only. |
| 2 | Shorten shared boilerplate | all skills, `lint_skills()` | done 2026-11-17 (Capture 913 to ~440 chars in 33 skills, Explain base 457 to ~200 in 19 skills; 14 tailored Explain sections and the two skill-specific Capture extras kept; lint and link check clean; user approved) | "Capture lessons" (~1.4 KB) and "Explain the reasoning" (~1.4 KB) are copied verbatim into ~35 skills; the 2026-11-16 commit lengthened Capture. Design a shorter canonical text that points to `skill-lessons` for the full rule. Check what `lint_skills()` and the hook require (exact strings?) BEFORE editing; check current Posit Assistant docs on hooks/skills first (AGENTS.md working rule). Decide with the user whether the reminder strength matters (it was strengthened deliberately). Apply by script, verify with lint. |
| 3 | Move single-report GAM prediction bullets | gam-mgcv, gam-interpretation | done 2026-11-17 (both bullets moved to gam-interpretation/references/uncertainty-and-inference.md "Random effects and held-fixed covariates"; one-line pointer left; gamlss2/inlaws section kept, already a pointer to its reference) | In gam-mgcv "Interpretation and prediction": the group-mean contrast bullet (one project) and the log-link covariate-averaging bullet. Move to gam-interpretation (owns prediction and wording) or a gam-mgcv reference; leave a one-line pointer. Re-read `skill-boundaries.md`; run `check_skill_clashes()` and `check_skill_links()`. Also consider moving the gamlss2/inlaws section to a pointer. |
| 4 | Trim skill-feedback-triage step 1 | skill-feedback-triage | done 2026-11-17 (step 1 shortened, parked-recheck detail moved to triage-method.md; step 5 groups rows by issue with entry numbers; step 7 keys outcomes by entry number; new references/usage-review.md and a short pointer section for usage reviews) | Step 1 paragraph is long with "reported once" asides; move detail to `references/triage-method.md`. Also address 2 new entries: keep outcomes keyed by entry key not position (print numbered listing from the same object), and mention grouping rows by issue with entry numbers in step 5. |
| 5 | Overlap check: application-style-coach vs manuscript-writing-coach | both | done 2026-11-17 (shared rules kept in each skill on purpose; application SKILL.md 15.6 to 15 KB, call-copy and text-source detail moved to references/documents-and-calls.md, PDF excluding-references recipe added; routing of find-a-study requests to openalex added to both; Gantt entry to be rejected/parked in task 11) | Compare chat-only / no-drafting / no-reference-insertion rules; keep one canonical wording and point from the other. Decide the parked entry on "is there a study that..." requests (route to `openalex` as a separate user-asked step, coaching never finds references). Parked entry on timeline/Gantt of applications is low value: keep parked or reject. Trim SKILL.md (16 KB) modestly. |
| 6 | Audit github-skill-maintenance references | github-skill-maintenance | done 2026-11-17 (safe trims plus merge of the three hook references into references/hooks-reference.md, 32 KB to 13 KB; old files kept in git-ignored tmp-examples/old-hook-refs/) | 20 files, 155 KB. List files, sizes, last edit, inbound links from SKILL.md; flag stale or duplicated content (e.g. the three hook/signal references, `tested-and-not-tested.md`, `pitfalls.md` vs SKILL.md "Pitfalls this repo has hit"). Propose merges/deletions; do not delete without approval (prefer move aside). |
| 7 | Research: baseline covariates in marginal GAMs | gam-mgcv | done 2026-11-17: entry parked, no skill text (research in research/gam-mgcv-ledger.md) | Parked entry. Use OpenAlex (standing rule) plus mgcv/gratia docs. Questions: baseline as covariate vs change score, `s(time, by = baseline)`, repeated baselines, standardising group-mean predictions, leave-animals-out CV. Record in a new ledger `research/gam-mgcv-ledger.md` (or append if it exists) BEFORE writing skill text. Only then decide on a short reference section. |
| 8 | Decide: GAM band calibration simulation skill | new-skill suggestion | done 2026-11-17: no new skill, entry stays parked; consolidated reference gam-mgcv/references/coverage-simulation.md written after reading Morris et al. 2019 (ledger sections 5-6) | One report only (parked). Check overlap with gam-mgcv/gam-interpretation/stats-reporting-and-review (power via simr); research simulation-coverage practice (OpenAlex). Default outcome: stay parked or add a short reference to gam-interpretation. |
| 9 | Research: multithreaded bam slowdown on fragmented cores | hpc-r-code, hpc-resource-allocation | done 2026-11-17: parked, no skill text (research in research/hpc-threading-ledger.md) | Parked entry. Needs site docs (use `hpc-cluster-docs` flow, user runs commands) and benchmarks, never guessed. Keep both skills' "Where this skill runs" rule. Likely outcome: short note once a second report arrives. |
| 10 | Merge duplicate Quarto and pipeline entries | manuscript-writing-quarto, r-reproducible-pipeline | done 2026-11-17: merged and parked, ledgers updated, no skill text | Quarto: one new + one parked entry on movable outcome-organised sensitivity blocks / guard blocks (same topic; one project). r-reproducible-pipeline: "no targets" appendix + analysis-cache-provenance new-skill suggestion are one proposal reported twice (one project). Default: keep parked, record as one issue. |
| 11 | Finish and archive the 2026-11-17 triage run | skill-feedback-triage | done 2026-11-17 (run archived, dispositions and watermark recorded, HISTORY entry added; see research/triage-run-2026-11-17-ledger.md) | After tasks 4/5 decisions: follow step 7 archive checklist (keep list, dispositions for every entry, watermark, copy ledger back, HISTORY entry, AGENTS.md watermark line in same commit). Existing watermark: 2026-11-17T19:56:20. |
| 12 | Verify and log | github-skill-maintenance | done 2026-11-17 (checkpoint before task 13; re-run after 13; HISTORY entry added; check_sync_setup not run, settings.json unreadable) | After each edited skill: `lint_skills()`, `uvx --from skills-ref agentskills validate <dir>`, `check_versions()` if versions named, `check_skill_clashes()`, `check_skill_links()`. Append a `HISTORY.md` entry (generic wording). Do not say "ready" while errors remain. |
| 13 | Review the lesson-triage process itself (root cause) | skill-feedback-triage, skill-lessons, agents-md-maintenance, create-skill, github-skill-maintenance | done 2026-11-17 (gates, research checklist, lint checks; ledger research/triage-process-ledger.md; open O1-O3) | Much of this review (tasks 1-5) is cleanup of bloat that triage rounds added: each round appended a "reported once" aside or paragraph to SKILL.md instead of routing it to a reference, merging with existing text, or rejecting it. Find why the process allowed that and change the process. Check: (a) add a size/budget gate to triage step 6 (SKILL.md byte budget per skill, e.g. warn above ~12 KB; new detail goes to references/ by default, SKILL.md gets at most a one-line pointer); (b) rule that a fix must replace or merge with existing text, not append, and must not carry provenance narrative ("reported once", dates) in SKILL.md, which belongs in the ledger/HISTORY; (c) route single-report findings (one project) to references or park, not SKILL.md body, matching the single-user thresholds in references/triage-method.md; (d) make lint_skills() warn on SKILL.md size growth and on "reported once"/"reported by" provenance phrases; (e) boilerplate edits belong in one canonical place (task 2 showed 33 copies); (f) consider a periodic bloat check step in triage (usage + size + edit-count view, which this review had to assemble by hand) and the usage-review mode noted in the 2026-11-17 lesson entries; (g) keep outcomes keyed by entry key (see task 4); (h) strengthen the research requirement in triage: before any `fix` or `add-note` is proposed, require a recorded research step per issue (upstream docs/NEWS/issues, CRAN, OpenAlex for scientific-method claims, a reproduction), with the findings in the research ledger and shown as a column in the triage table; no research row means the outcome defaults to `park` or `needs-info`, never `fix`. Make the rule concrete (a checklist the table cannot be shown without) and put it in the triage skill early, not only in step 3, since the existing text on this was apparently not enough. Look up current docs on skill authoring best practice (agentskills.io progressive disclosure, size guidance) first per working rules; protocol in research ledger. Do this last so it reflects what tasks 1-12 revealed. |

## Standing rules to keep in mind (from AGENTS.md)

- Look up current docs online before changing skill files or hooks; check CRAN before hand-writing helpers; CRAN installs
  allowed, GitHub/R-universe installs need explicit permission.
- Protocol research in `research/` in the same turn; scientific literature via OpenAlex.
- Source-quality rules: skip commercial, LLM-like, US-specific sources and record them as skipped.
- Tests go in git-ignored `tmp-examples/`, deleted afterwards. No secrets, no lesson text or `usage.tsv` in git.
- Every skill keeps: Related skills, Explain the reasoning, Capture lessons; HPC skills keep "Where this skill runs".
- Show the user a plan/diff summary and get approval before bulk edits across skills (task 2).

## Log

- 2026-11-17: review run (read-only). Findings above; no skill files edited. Task list created.
- 2026-11-17: task 1 done. lint_skills: no errors/warnings (info only); skills-ref validate passes.
- 2026-11-17: task 2 done. lint_skills() and check_skill_links() only match the two '##' headings by prefix; hooks (scripts/lessons-hook.sh) do not read skill text. Uncommitted.
- 2026-11-17: task 3 done, uncommitted.
- 2026-11-17: task 4 done, uncommitted. lint_skills, check_skill_links, skills-ref validate clean. Handled 4 entries: positional outcomes, grouped table, usage-review mode, frontmatter-parse note (in usage-review.md). Dispositions still to be recorded in task 11.

- 2026-11-17: task 13 added (triage process review, to be done last).
- 2026-11-17: task 13 extended with item (h): stronger research requirement during triage.
- 2026-11-17: task 5 done, uncommitted. Overlap: chat-only, facts-belong-to-user, one-sentence examples, no-references, no-LLM-wording, flags-are-prompts are near-identical in both; kept duplicated because a skill cannot rely on the other being loaded; Related-skills pointers already exist both ways. Dispositions for application-style-coach entries (chat-only exception, call copy, whole-document read, citation spacing, pdf excluding references, find-a-study) to be recorded in task 11.

- 2026-11-17: task 6 audit. Trimmed pitfalls.md CRLF bullet (35 to 13 lines), condensed tested-and-not-tested.md to a summary, removed date asides in SKILL.md. Proposal pending: merge skill-trigger-hook.md, file-signal-hook.md, prompt-signal-channel.md (32 KB, three copies of the settings JSON and overlapping tested narratives) into one hooks reference. Uncommitted.

- 2026-11-17: task 6 merge approved and done. Inbound links updated (SKILL.md, README.md, codebase-map, both hook scripts' header comments, check_sync_setup.R comments, pitfalls.md, tested-and-not-tested.md). lint, link check, check_sync_setup, skills-ref validate (2 skills) and bash -n clean. Uncommitted.


- 2026-11-17: task 7 parked (no text). Task 8: coverage-simulation.md written, ncv notes and model-comparison bullets pointed to it; lint, link check and skills-ref validate clean. Uncommitted.

- 2026-11-17: task 9 researched (docs only, no benchmark possible here). Entry stays parked, no skill text; ledger research/hpc-threading-ledger.md. Disposition to be recorded in task 11.

- 2026-11-17: task 10 done (no skill edits): guard-block entries already merged into one SKILL.md bullet; movable-block and staged-drafting stay parked; no-targets appendix and analysis-cache-provenance recorded as one parked issue (ledgers updated). The movable sensitivities-block entry (57ca9ec1) has no disposition row yet: record `park` in task 11.

- 2026-11-17: task 11 postponed at the table stage (user: the triage skill will change first, see task 13). Nothing archived, no dispositions written, watermark unchanged. The git-ignored copy `.posit/assistant/lessons-work` was left in place: delete it (it is a stale copy that would re-triage files) before the next run. State: 28 new, 8 parked, 60 closed (12 inbox files). Proposed outcomes shown, not approved: no-change for use-case and worked-well entries (70, 73, 74, 77, 80, 81, 85, 88, 96), reject 86 and 90, already-present 71, 72, 75, 76 and 95, add-note 89 (pitfalls.md, no python in bash), 82-84 and 91 (openalex query-refinement.md), 92-94 (openalex fulltext.md), park 78, 79, 87, 54, reject the parked Gantt entry, already-present for the find-a-study entry, other parked entries stay parked. Entry numbers are positional: rebuild the table from a fresh read.
- 2026-11-17: task 11 done: user approved the table; 6 add-notes applied, 99 dispositions closed, 12 parked, watermark 2026-11-17T22:20:25. Process review item O3 (gates applied in a real run) done.
