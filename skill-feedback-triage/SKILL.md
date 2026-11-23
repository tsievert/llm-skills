---
name: skill-feedback-triage
description: 'Reads the lessons-learned inbox written by the skill-lessons skill (generic entries from real projects), groups and deduplicates them per skill, reproduces and researches each issue, and proposes fixes to the skills in the llm-skills repo. Use when the user asks to process, triage, review or harvest lessons or feedback from skill use, to improve skills from real-world problems, to see which skills are actually used, or to check whether the lessons hook and inbox work. Runs in the llm-skills working directory, never edits skills without approval.'
---

# Triage lessons from real use into skill fixes

Runs in the llm-skills repo (the working directory). Input: the inbox and usage log written
by the `skill-lessons` skill and the repo-root hook script `lessons-hook.sh`. Output: a triage table, then
approved edits to skills. The project working rules apply (look up current docs online
before changing skill files or hook config; check CRAN before hand-writing helpers;
GitHub or R-universe installs need the user's permission).

## Inputs

| What | Where | Note |
|---|---|---|
| Lesson files | `~/.posit/lessons/inbox/*.md` (also on other machines: collect them into one folder) | one file per session, named `<project>_<timestamp>_<session8>.md` |
| Usage log | `~/.posit/lessons/usage.tsv` | `time, session, project, skill`, written by the hook; append-only, never emptied; a watermark line in `AGENTS.md` marks what earlier runs counted; per-run narrative entries go to `HISTORY.md` |
| Format | the `skill-lessons` skill | headings `## <skill>: <title>` then `- field: value` |

Copy the inbox, usage log and dispositions into the git-ignored `.posit/assistant/lessons-work` with bash
(the R session cannot read the home folder), check the file counts match, and delete the copy once the run is
archived: [references/work-copy.md](references/work-copy.md). A leftover copy re-triages archived files.

If the user collected files from other machines or projects, they go into the same
`inbox` copy; names do not collide by design.

**Dropped-off conversation exports.** If the user also provides conversation-export JSON files,
read the lesson files first and use an export only to verify a claim; the parsing recipe is in
[references/conversation-exports.md](references/conversation-exports.md).

## Gates (the table is not shown without these)

1. **Research row per issue.** Every issue that could end as `fix` or `add-note` has a recorded research row
   (reproduction, upstream, CRAN, OpenAlex for method claims, skill text read) in a ledger under `research/`,
   shown as a column in the table. No row: the outcome is `park` or `needs-info`, never `fix`.
2. **Placement.** A fix carries no provenance ("reported once", dates), a one-project finding goes to a
   `references/` file, and a small fix replaces or merges with existing text. This keeps routine fixes small; it
   does not limit a `rework` (gate 4).
3. **Size.** Compare the target SKILL.md size before and after; above about 12 KB, move something out in the
   same change. Details: [references/triage-method.md](references/triage-method.md).
4. **Cause, not symptom.** Before the table, run the target scan (step 3) and place each fix on the fix ladder
   (text, structure, enforcement, remove the cause), stating why a higher rung was or was not chosen. A repeat
   report of something already fixed is a failed fix, never `already-present`. A target with repeated patches
   gets a `rework` proposal instead of another patch.

## Workflow

1. **Read and validate.**
   ```r
   source("skill-feedback-triage/scripts/read_lessons.R")
   L <- read_lessons(".posit/assistant/lessons-work/inbox", repo = getwd())
   W <- triage_watermark()   # NULL on the first run, else the cutoff of the last run
   U <- read_usage(".posit/assistant/lessons-work/usage.tsv", since = W)
   D <- dispositions_read(".posit/assistant/lessons-work/dispositions.tsv")
   L <- lesson_status(L, D)   # adds `status`: new / parked / needs-info / closed
   status_summary(L)       # triage "new (actionable)"; note-only: no-change; others are context
   lesson_problems(L)      # malformed entries, unknown skill folders (skips closed and built-in-skill entries)
   lesson_overview(L, U)   # per skill: loads, sessions, projects, entries by type
   lesson_dupes(L)         # candidate duplicates (heuristic, check by reading)
   ```
   Set `options(width = 200)` first. Give `L` a numbered key (`L$n <- seq_len(nrow(L))`) once and print every
   listing from that object, in batches (about 17 KB overflows the code tool's output). Report coverage first
   (skills never loaded; skills loaded often with no entries: fine, or the reminder fails, unknown). Fix or
   report malformed entries rather than dropping them; `closed` entries stay out of the table. Every run, run
   `parked_recheck(L)` before the table (`likely_stale` flag: [references/triage-method.md](references/triage-method.md));
   survivors stay parked until a new report of the same thing.
2. **Group.** Merge duplicates into one issue and count independent projects and sessions
   per issue. Keep `generality: likely-user-specific` entries out of skill edits unless a
   second project shows the same thing.
3. **Scan the targets, then treat every entry as a hypothesis.** For each target file run `target_scan(L, D)` (`read_lessons.R`) as in
   [references/triage-method.md](references/triage-method.md) (recent edits, other entries naming it, recurring
   closures) and read the whole file. Every run also show the top five of `usage_churn_table()`
   (`scripts/churn.R`, all skills, ranked by commits since the last rework in `references/rework-log.tsv`) and,
   for a rework candidate, `usage_churn_files(skill)`.
   Then treat every entry as a hypothesis. Run the research checklist in
   [references/triage-method.md](references/triage-method.md) for each issue and record it in the ledger
   (see Gates; ledger skeleton: [assets/research-ledger-template.md](assets/research-ledger-template.md)). A `bug` entry naming a script is reproduced with a cheap test of that code path before it is
   parked or rejected. Grep the named skill and `HISTORY.md` for the entry's key terms before building the
   table, then read the target section: a `suggested-change` already applied is `already-present`; an entry
   about a built-in skill with no folder here (for example `quarto-authoring`) is `reject`.
   `type: new-skill-suggestion` entries (slot `new-skill`) have nothing to reproduce: check overlap with
   existing territory (`github-skill-maintenance/references/skill-boundaries.md`), whether a second
   independent report backs it, and whether the scope fits one skill `description`.
4. **Decide per issue.** Outcomes: `fix` (skill text, script or reference changes),
   `add-note` (caveat or "verified on" line), `needs-info` (ask the user to rerun a
   command and paste the output), `reject` (user-specific, or the skill was right), `park`
   (one low-confidence report; leave it in the inbox so evidence can accumulate), or
   `new-skill` (build it with `create-skill`, in this triage session, only after the user
   approves it in step 5 — `new-skill-suggestion` entries exist precisely so that decision
   is made here, deliberately, rather than on the spot in whatever session first noticed
   the need).
   `rework` (restructure a section, file or mechanism in its own change: [references/rework.md](references/rework.md)).
   Evidence thresholds are in the reference.
5. **Show the triage table and ask.** One row per issue, not per entry, listing its entry numbers
   (`L$n`) so the outcome column can be built from them. Columns: issue, entries, skills, reports
   (projects), research (ledger row and checklist result), proposed outcome and change, fix-ladder rung,
   alternative considered (one broader option and why not), target file and
   size after the change. Wait for the user's choice
   (the `AskUser` tool suits batches) before editing any skill. If the run is postponed, save the proposed outcomes
   keyed by `L$key` (file, skill, title), not by entry number (numbers shift when files are added), and leave
   dispositions and the watermark untouched.
6. **Edit, then verify.** After approval, change the skills under the placement and size gates (for a `new-skill` outcome, load
   `create-skill` and build the new skill folder, including the standing sections this repo
   requires: subagent-delegation note where it fits, "Related skills", "Explain the
   reasoning", "Capture lessons"), then load and follow `github-skill-maintenance`
   (`lint_skills()`, `uvx --from skills-ref agentskills validate <dir>` (the bare `skills-ref` command is not on PATH), `check_versions()` when versions are named,
   `check_skill_clashes()` and `check_skill_links()` for a new skill), run any changed
   script or snippet, and state what was and was not tested. Do not call anything ready
   while errors remain.
7. **Archive.** Work through [references/archive-checklist.md](references/archive-checklist.md) in order (keep list,
   `mv` to `processed/`, one disposition per entry, watermark, ledger copy-back, delete the work folder,
   `HISTORY.md` entry). No archiving or watermark before the user has seen the table.

## Usage and maintenance review (no triage)

When the user asks which skills are used or edited most, or whether skills are bloated, do not archive,
move the watermark or write dispositions. Follow [references/usage-review.md](references/usage-review.md).

## What the data can and cannot say

Entries are written by an assistant that may misjudge what generalises, and a quiet inbox
does not mean a skill works: sessions without a reminder, uncaptured user corrections and
unreported silent errors leave no trace. The usage log is the reliable part. With few
projects, one report is an anecdote; say so rather than generalising.

## Privacy

Entries should already be generic. If one still contains identifiers, paths or data
values, do not copy it into skills, `AGENTS.md`, commits or search queries; reword it
generically and tell the user the entry slipped through.

## Related skills

- `skill-lessons`: writes the inbox this skill reads. The entry format, privacy rules and the
  new-skill-suggestion convention live there, not here.
- `agents-md-maintenance`: one source of new-skill-suggestion entries triaged here — when it
  finds a procedure that has outgrown a project's memory file, it logs the suggestion via
  skill-lessons instead of building the skill itself.
- `github-skill-maintenance`: the step after a fix or new-skill outcome is approved — lints,
  tests and verifies the edited or newly built skill before it's called ready.

## Capture lessons (self-improvement rule)

Load the `skill-lessons` skill and append a generic, anonymised entry (no project data, IDs or paths) as soon as something unanticipated happens: an error or warning, advice or code that failed, a user correction, a version or API mismatch, missing guidance, or a recommendation that held up (`worked-well`). Also write one `use-case` entry per session. When unsure, record it with `generality: unsure`. Entries are hypotheses for `skill-feedback-triage`.

Specific to this skill: also record a failing workflow step, a misbehaving script, or a user correction of the triage process itself.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why each issue got its outcome (what evidence counted, why one report was parked, why a fix was or was not proposed), what could not be checked, and which decisions are the user's (accepting a change, treating a pattern as a skill problem or a data problem). Keep each explanation to a sentence or two and point to a reference for depth.
