---
name: skill-lessons
description: 'Records generic, anonymised lessons learned about the custom skills in the llm-skills repo into a local inbox, so real-world failures can later be fed back into the skills. Use when a skill''s advice or code failed or needed a workaround, an unanticipated error or version/API mismatch appeared while following a skill, the user corrected the assistant, or a skill lacked guidance the task needed; also when a lessons-check hook message asks for it, or the user types /skill-lessons or asks to log a lesson. Not for triaging collected lessons (use skill-feedback-triage).'
---

# Capture lessons about skills

Part of a feedback loop: skills were tested on synthetic data, real projects reveal what
breaks. Entries written here are collected later by `skill-feedback-triage` in the
llm-skills repo and turned into skill fixes. This skill only writes entries; it never edits
skills.

## When to record

Record an entry when, while using a skill, any of these happened:

- an error or warning the skill did not anticipate;
- code or advice from the skill failed, or needed a workaround;
- the user corrected the assistant or overrode the skill's advice;
- a package version, function or API differed from what the skill states;
- the skill had no guidance for something the task needed.

Do not record: one-off user preferences, quirks of one dataset, questions that were simply
answered, or anything the user asked not to share. If unsure whether it generalises, record
it with `generality: unsure`; triage decides.

Write the entry when the issue is resolved (or clearly unresolved), not at the end of the
session, because sessions can end abruptly. Tell the user in one sentence that an entry was
recorded and where.

## Use-case summary (every session that used a skill)

Besides lessons, write one short `use-case` entry per session in which a repo skill was
used, even when nothing went wrong. It proves the capture path works and shows what the
skills are actually used for. Use `usecase_add()` (below) or the same block by hand:
heading `## <main-skill>: use case (<outcome>)`, `type: use-case`, `symptom` = one to three
generic sentences on the task ("fit a zero-inflated GLMM to repeated-measures counts,
40 animals x 3 sessions"), `context` = all skills used, `resolution` = outcome
(`worked`, `worked-with-workaround`, `partly-worked`, `failed`, `abandoned`), `evidence` =
friction or "none". Same privacy rules as lessons. If the hook reminder names a file,
write the use-case entry first, then any lesson entries into the same file.

## Privacy (hard rules)

The repo is public and the inbox may be shared. Entries must be generic:

- no data values, animal/sample/subject IDs, unpublished results, names, emails, tokens;
- no absolute paths or file names from the project (write `<path>`, `data.csv` becomes `<file>`);
- describe data by type and size only ("repeated-measures counts, 40 animals x 3 sessions");
- error messages are fine after removing paths and identifiers;
- the `project` field is the folder name only, so choose a non-sensitive name or write `anon`.

`scripts/lesson_helpers.R` scrubs obvious paths and emails and refuses what it still flags;
it does not make an entry safe by itself, so reread the entry before reporting it.

## Where

One file per session in the global inbox, so projects and sessions never collide:

`~/.posit/lessons/inbox/<project>_<YYYYMMDD-HHMMSS>_<session8>.md`

(`USERPROFILE/.posit/lessons/inbox` on Windows.) If a hook message gave a full path, use
exactly that path. Without one, use `lesson_file()` below (it ends in `_manual`). Several
entries from one session go into the same file, one `##` block each.

## Entry format

The file starts with front matter (written once, the helper does it), then one block per
entry. Heading: `## <skill-name>: <short title>`; the skill name must match a skill folder.

```markdown
---
project: <folder name or anon>
date: 2026-10-23
session: a1b2c3d4
environment: {os: "Windows 11", r: "4.6.0", python: null, packages: {mgcv: "1.9-4"}}
---

## gam-mgcv: k.check returns NA for sz smooths
- type: bug | missing-guidance | outdated-fact | user-correction | env-difference | worked-well | use-case
- symptom: what happened, generic terms
- context: function/package + version, data type and size (anonymised)
- tried: what was attempted, in order
- resolution: what finally worked, or "unresolved"
- evidence: error text (paths removed) or a minimal reproducible snippet
- suggested-change: one sentence on what the skill should say, or "unknown"
- confidence: high | medium | low (high only if the user confirmed the fix worked; optional for `use-case` entries)
- generality: general | likely-user-specific | unsure
```

`worked-well` is allowed: a recommendation that held up on real data is evidence too.

## How to write it

With the helper (R, from any directory):

```r
source("<skill-dir>/scripts/lesson_helpers.R")   # skill directory is shown when this skill loads
lesson_add(
  skill = "gam-mgcv", title = "k.check returns NA for sz smooths", type = "bug",
  symptom = "...", context = "mgcv 1.9-4; 3000 rows", tried = "...",
  resolution = "...", evidence = "...", suggested_change = "...",
  confidence = "medium", generality = "general",
  packages = c("mgcv", "gratia"),
  file = "<path from the hook message, if any>"
)
```

`lesson_add()` creates the file and front matter, fills the environment from the running R
session, scrubs, validates the fields and appends the block. The assistant's R session is
usually not allowed to write outside the project (verified here: `dir.create()` on the
home-folder inbox is blocked), so expect the fallback: the helper then prints the
validated text and the assistant saves it with the `write` tool (or `bash`) to the same
path. Without R, write the same markdown directly. `lesson_file()` returns a new inbox
path. If the front matter already exists in the file, append only the `##` blocks.

## What happens next

- A `PostToolUse` hook logs each load of a repo skill to `~/.posit/lessons/usage.tsv`
  (timestamp, session, project folder, skill). That log needs no model cooperation.
- A `Stop` hook reminds the assistant once per session to write a use-case summary and any
  lessons, after an error-like tool result or `LESSONS_TURN_LIMIT` turns (pilot default 2).
  Each reminder is logged to `~/.posit/lessons/reminders.tsv`. Loading this skill
  suppresses the reminder (the use-case entry is then still expected from this skill).
  Setup, tests and limits: [references/hook-setup.md](references/hook-setup.md).
- The inbox is read by `skill-feedback-triage`. Entries are hypotheses until reproduced.

## Limits

The assistant, not a program, decides what counts as a lesson, so entries will be missed
and some will be wrong or too specific; that is why triage reproduces before editing.
The reminder fires at most once per session. Sessions on a cluster only produce entries for
things the user pasted back; this skill does not run on the cluster.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why an entry was or was not written (which trigger applied, why something was judged too user-specific, what was anonymised and why), and which decisions are the user's (what to share, whether an issue is a skill problem or a data problem). Keep each explanation to a sentence or two and point to a reference for depth.
