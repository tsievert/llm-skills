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
| Usage log | `~/.posit/lessons/usage.tsv` | `time, session, project, skill`, written by the hook; append-only, never emptied; a watermark line in `AGENTS.md` marks what earlier runs counted |
| Format | the `skill-lessons` skill | headings `## <skill>: <title>` then `- field: value` |

The assistant's R session is blocked from paths outside the project, so copy first with
bash (gitignored, so lesson text is never committed):

```bash
mkdir -p .posit/assistant/lessons-work
cp -r ~/.posit/lessons/inbox ~/.posit/lessons/usage.tsv .posit/assistant/lessons-work/
```

If the user collected files from other machines or projects, they go into the same
`inbox` copy; names do not collide by design.

## Workflow

1. **Read and validate.**
   ```r
   source("skill-feedback-triage/scripts/read_lessons.R")
   L <- read_lessons(".posit/assistant/lessons-work/inbox", repo = getwd())
   W <- triage_watermark()   # NULL on the first run, else the cutoff of the last run
   U <- read_usage(".posit/assistant/lessons-work/usage.tsv", since = W)
   lesson_problems(L)      # malformed entries, unknown skill folders
   lesson_overview(L, U)   # per skill: loads, sessions, projects, entries by type
   lesson_dupes(L)         # candidate duplicates (heuristic, check by reading)
   ```
   Report coverage first: skills never loaded in real projects (still untested on real
   data), skills loaded often with no entries (either fine or the reminder is not working;
   say which is unknown), and entries per load. Fix or report malformed entries rather
   than dropping them silently.
2. **Group.** Merge duplicates into one issue and count independent projects and sessions
   per issue. Keep `generality: likely-user-specific` entries out of skill edits unless a
   second project shows the same thing.
3. **Treat every entry as a hypothesis.** For each issue:
   - reproduce it on a small synthetic example in the scratch directory, or say why not
     (needs the user's data, a cluster, a GPU);
   - check upstream (package NEWS, docs, GitHub issues; see
     [references/triage-method.md](references/triage-method.md));
   - check the skill text the entry blames: is the claim wrong, missing, or just not read?
   - check CRAN for a package that would remove the problem.
4. **Decide per issue.** Outcomes: `fix` (skill text, script or reference changes),
   `add-note` (caveat or "verified on" line), `needs-info` (ask the user to rerun a
   command and paste the output), `reject` (user-specific, or the skill was right), `park`
   (one low-confidence report; leave it in the inbox so evidence can accumulate).
   Evidence thresholds are in the reference.
5. **Show the triage table and ask.** Columns: issue, skills, reports (projects),
   reproduced, upstream finding, proposed outcome and change. Wait for the user's choice
   (the `AskUser` tool suits batches) before editing any skill.
6. **Edit, then verify.** After approval, change the skills, then load and follow
   `github-skill-maintenance` (`lint_skills()`, `skills-ref validate`, `check_versions()`
   when versions are named), run any changed script or snippet, and state what was and was
   not tested. Do not call anything ready while errors remain.
7. **Archive.** Move processed files with bash (`mv ... inbox/processed/`) in the real
   inbox, not the copy, keeping parked ones in place. Never truncate or edit `usage.tsv`;
   instead record the watermark with `triage_watermark_set(max(U$time))` (only once the
   user has seen the triage table; skip it if `U` is empty). The next run then counts
   only newer rows, so months-apart runs do not double-count. Add a Log entry to `AGENTS.md`
   (counts, outcomes, what was not verified) with generic wording only. Commit skill
   edits, never lesson files.

## What the data can and cannot say

Entries are written by an assistant that may misjudge what generalises, and a quiet inbox
does not mean a skill works: sessions without a reminder, uncaptured user corrections and
unreported silent errors leave no trace. The usage log is the reliable part. With few
projects, one report is an anecdote; say so rather than generalising.

## Privacy

Entries should already be generic. If one still contains identifiers, paths or data
values, do not copy it into skills, `AGENTS.md`, commits or search queries; reword it
generically and tell the user the entry slipped through.

## Capture lessons (self-improvement rule)

If a step of this workflow fails, a script misbehaves, or the user corrects the process,
record a generic, anonymised entry by following the `skill-lessons` skill (no project data,
IDs or paths; write it when the issue is resolved, mention it in one sentence). Entries are
hypotheses for later triage, not facts.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why each issue got its outcome (what evidence counted, why one report was parked, why a fix was or was not proposed), what could not be checked, and which decisions are the user's (accepting a change, treating a pattern as a skill problem or a data problem). Keep each explanation to a sentence or two and point to a reference for depth.
