# Triage method

Contents: evidence thresholds, reproducing, upstream checks, classifying the cause, writing
the fix, measuring whether the loop works.

## Evidence thresholds (starting point, adjust with experience)

| Situation | Outcome |
|---|---|
| Reproduced on synthetic data, or error text clearly names a skill claim as wrong | `fix`, even from one report |
| Same issue in 2 or more independent projects, not reproduced | `fix` or `add-note`, worded as "reported, not reproduced" |
| One report, `confidence: low`, `generality: unsure` | `park` (but a `bug` entry naming a script is reproduced first; one quick test, not code reading) |
| `generality: likely-user-specific` and no second report | `reject` or `park` |
| Needs a cluster, GPU or the user's data to check | `needs-info`: give the exact command and ask for the pasted output |
| `use-case` | not a defect: count per skill, list friction notes, compare with `usage.tsv` and `reminders.tsv` to judge whether capture triggers reliably (loads vs. reminders vs. entries) |
| `worked-well` | note in the skill's "tested" statement only if it adds real-data evidence |

Independent means different project folders and sessions; two files from the same project
count once.

## Reproducing

Use a small synthetic example in the scratch directory, with the package versions named in
the entry (`environment` in the front matter lists R, OS and packages). If installed
versions differ, say so: a bug may exist only in a newer or older version, which is a
version caveat in the skill, not a rewrite. Do not install from GitHub or R-universe
without asking. CRAN and Bioconductor installs are allowed.

## Upstream checks

- Package NEWS and reference pages (`utils::news()`, pkgdown sites, CRAN "NEWS").
- GitHub issues: the search API works keyless
  (`https://api.github.com/search/issues?q=<terms>+repo:<owner>/<repo>`), `gh` may not be on
  PATH. Read the issue; a title match is not evidence.
- The skill's own references and prior Log entries in `AGENTS.md`, which record what was
  already verified.
- OpenAlex only for literature questions (user standing rule).

## Classifying the cause

| Cause | Typical fix |
|---|---|
| Skill claim wrong or outdated | correct the text, add "verified with <version>" |
| Skill silent on a real case | add a short section or a reference file |
| Skill right, assistant did not follow it | strengthen wording or move the rule earlier; check the description trigger |
| Package changed | version caveat, re-test snippets, update `check_versions()` claims |
| Environment (Windows paths, permissions, cluster) | add an environment note, keep generic |
| Data problem, not a skill problem | reject, tell the user why |

Keep each fix minimal and in the right file: SKILL.md stays short, detail goes to
`references/`. Do not add a lesson's story, only the rule it supports.

## An entry with no matching load

A skill named in an inbox entry can show 0 loads in `usage.tsv` since the watermark. This is not
necessarily a gap: the skill may have been loaded before the watermark cutoff (loads are
append-only and never double-counted after a watermark is set), the entry may be a manually
written one (`session` ending in a non-hash suffix such as `manual` or a free label) rather than
one captured live, or the usage log may simply not cover that machine or session. Check the
entry's own `date`/`session` against the watermark and against `usage.tsv` directly before
treating it as evidence that capture is unreliable; only a load recorded *after* the watermark
with no entry (or vice versa, within the same session) is a real mismatch worth reporting.

## Measuring the loop itself

From `usage.tsv` and the inbox: loads per skill, sessions with at least one repo skill,
sessions with an entry, entries per session. If many sessions loaded skills but no entry
exists, either nothing went wrong or the reminder fails; test by looking at
`state/*.reminded` flags (reminder fired) against inbox files (reminder followed). A
persistent gap means the turn limit or wording needs changing (see
`../skill-lessons/references/hook-setup.md`).
