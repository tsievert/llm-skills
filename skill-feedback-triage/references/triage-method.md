# Triage method

## Contents

Evidence thresholds, target scan, research checklist, where a change goes (size and provenance gates),
reproducing, upstream checks, classifying the cause and the fix ladder, measuring whether the loop works,
re-checking parked entries. Restructuring a section or file (`rework`): [rework.md](rework.md).

## Evidence thresholds (starting point, adjust with experience)

| Situation | Outcome |
|---|---|
| Reproduced on synthetic data, or error text clearly names a skill claim as wrong | `fix`, even from one report |
| Same issue in 2 or more projects, not reproduced | `fix` or `add-note`; say "not reproduced" only if it changes how the reader should act |
| One report, `generality: general`, `confidence` medium or higher, change is a cheap additive note (a bullet or sentence, no behaviour change) | `add-note`, placed in a `references/` file (see "Where a change goes") |
| One report, `confidence: low`, `generality: unsure`, or the change alters behaviour or adds bulk | `park` (but a `bug` entry naming a script is reproduced first; one quick test, not code reading) |
| `generality: likely-user-specific` and no second report | `reject` or `park` |
| Needs a cluster, GPU or the user's data to check | `needs-info`: give the exact command and ask for the pasted output |
| `use-case` | not a defect: count per skill, list friction notes, compare with `usage.tsv` and `reminders.tsv` to judge whether capture triggers reliably (loads vs. reminders vs. entries) |
| `worked-well` | note in the skill's "tested" statement only if it adds real-data evidence |

There is one user (multiple users are not planned), so every report comes from the same
person's habits. "Independent" therefore means different project folders and sessions of
that user, not different people; two files from the same project count once. Because a
second reporter will never exist, a one-report gate alone would stall most guidance gaps:
weigh the cost and generality of the change (see the cheap-note row) instead of waiting
for repetition.

## Target scan (required before the table)

Issues are grouped by cause, but fixes land in files, and a file that keeps getting small patches is the real
problem. `target_scan(L, D)` lists per skill: edits in the last 60 days, the busiest file and its edit count,
files with 3 or more edits, entries by status, and new entries that look like a repeat of an entry the ledger
already closed. Then read each target file whole (not only the section named in the entry) and note how many
patches from earlier runs it carries (`git log -p -- <file>`). Results go in the ledger and the table.

- **Recurrence.** A new entry that repeats an issue closed earlier as `fix`, `add-note` or `already-present`
  is evidence that the earlier fix failed, so it is not `already-present`. Find why it failed (text not seen,
  wrong place, rule too weak, no enforcement) and move up the fix ladder. The title match is a screen: read
  both entries. Record the outcome as `fix`.
- **Same failure class on several sites** (several entries, different sites or inputs): propose a code-level
  fix keyed by failure class (a ladder in the script) before any per-site documentation note.
- **Rework trigger.** Propose `rework` when a target file has 3 or more edits in the window and at least 2 entries
  point at it, when a recurrence exists, or when the same topic needs a third bullet. At most one or two reworks
  per run, picked by churn; the user decides which.

## Patch gate (required before the table)

The target scan shows pressure; the patch gate forces a decision. After outcomes are chosen, list one path per
proposed edit and run `patch_gate()` (`scripts/churn.R`). A row is `rework-or-defer` when the file has 3 or more
edits since its last rework (or in the window if never reworked), when this run edits it twice, or when this run
edits 3 or more places in the same skill. Thresholds count all commits, not only triage ones: read them as a
prompt to look, then judge.

- For each such row choose: propose a `rework` (scope it with `usage_churn_files(skill)`), or defer with a
  one-sentence reason shown in the table. "Cheap note, one report" is a reason only if the file is not also
  contradictory or overlapping; read the file to say so.
- A deferral is recorded with `rework_defer(target, reason)` at archive time. A target with an earlier deferral
  shows `deferred_n` above 0: propose the rework first; deferring again is the user's explicit choice.
- `patch` rows (low churn, single change) go ahead as small fixes. A one-line fix is the right answer when the
  target is healthy; the gate only prevents it from being the default regardless of the target's state.
- Several `add-note` outcomes on one skill in one run are one topic: ask whether a restructure of that reference
  would absorb them.

## New-skill suggestions

Nothing to reproduce. Check overlap with existing territory (`github-skill-maintenance/references/skill-boundaries.md`),
whether a second independent report backs it, and whether the scope fits one skill `description`.

## Research checklist (required per issue before the table)

Every issue that could end as `fix` or `add-note` needs a research row in the ledger
(`research/<skill-or-topic>-ledger.md`; start from `assets/research-ledger-template.md`). The table
shows the row as a "research" column. No row means the outcome is `park` or `needs-info`. A row
records, each with a status (done, not applicable with a reason, not possible with a reason):

1. Reproduction on a small synthetic example, or why not (needs data, cluster, GPU).
2. Upstream: package NEWS or docs, issue tracker, for any claim about a package's behaviour.
3. CRAN or Bioconductor: a package that removes the problem.
4. OpenAlex, for a claim about a scientific method (user standing rule); read the source, not the title.
5. The named skill's own text read (not only grepped), including references.
6. The cause behind the symptom: why the skill or assistant allowed it, and what design would stop the whole
   class (see the fix ladder), not only this instance.

Split what the sources support from claims with no source; only the supported part can become a fix.
Research is recorded in the same turn it is done, not summarised afterwards.

## Where a change goes (size and provenance gates)

- **Replace or merge, never append.** Find the existing sentence or bullet on the topic and rewrite it. A new
  bullet is allowed only when nothing in the file covers the topic.
- **These rules keep routine fixes small; they do not forbid a `rework`.** A rework may change more than one line
  and may restructure, as long as net size does not grow and its own gate in [rework.md](rework.md) is met.
- **One-project findings go to a `references/` file** (or are parked). SKILL.md gets a fix only when the issue
  was reproduced or seen in two or more projects, and then at most one line plus a pointer.
- **No provenance in skill text.** Phrases such as "reported once", "two sessions", "one project", dates and
  entry stories belong in the ledger or `HISTORY.md`. The skill states the rule, not who found it.
- **Size budget.** Before and after editing a SKILL.md, compare `file.size()`; above about 12 KB new detail
  goes to a reference by default, and `lint_skills()` warns above 16 KB. A fix that grows a SKILL.md past
  the budget moves something else out in the same change.
- **Shared boilerplate has one canonical text** (the "Capture lessons" and "Explain the reasoning" sections);
  change it by script across all skills in one commit, never by editing one copy.

**First-hand observations.** When an entry reports a version-specific or cluster-only fact that cannot be reproduced locally, write the research row as "unverified, source: reporting session" plus the skill-text check; it can support an `add-note` in a `references/` file but not a SKILL.md change. When an entry's fix text contains backslash sequences (such as `\r`), apply it with the edit tool, not `sed`, and check with `grep -cU $'\r'`.

**User memory outcome.** A one-user formatting preference, or environment guidance that recurs across sessions, is proposed for the user's memory file (`~/.posit/assistant/AGENTS.md`) instead of a skill edit; record the entry as `fix` once written there.

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

## Classifying the cause and the fix ladder

| Cause | Typical fix |
|---|---|
| Skill claim wrong or outdated | correct the text, add "verified with <version>" |
| Skill silent on a real case | short section or reference file; if the topic already has two bullets, restructure instead |
| Skill right, assistant did not follow it | next rung up the ladder (below), not louder wording |
| Package changed | version caveat, re-test snippets, update `check_versions()` claims |
| Environment (Windows paths, permissions, cluster) | add an environment note, keep generic |
| Data problem, not a skill problem | reject, tell the user why |

**Fix ladder.** Pick the lowest rung that removes the cause, and say in the table why a higher rung was or was
not chosen (an unreproduced one-project finding usually stays on rung 1 or 2).

1. **Text:** a correct sentence in the right place.
2. **Structure:** move the rule earlier, merge duplicates, turn prose into a checklist, decision table or
   template, split a file by topic.
3. **Enforcement:** a `lint_skills()` check, a script, a template, a hook, so the rule no longer depends on the
   assistant remembering it. Preferred for anything reported again after a text fix.
4. **Remove the cause:** delete the step, change the default, merge or retire the skill.

Keep each fix in the right file: SKILL.md stays short, detail goes to `references/`. Do not add a lesson's
story, only the rule it supports. For every table row also name one broader option (a higher rung or a
`rework`) and why it was not proposed (cost, evidence, risk); if the honest answer is "no good reason", propose it.

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

## Re-checking parked entries

Parked entries go stale: later edits often cover them (one run: about a third of 20 were already
present). `parked_recheck(L)` scores each entry's distinctive words against the named skill's files;
add `all_skills = TRUE, flag_share = 0.6` to also search neighbouring skills. It is a screen, not a
verdict. `likely_stale` over-fires right after a review that wrote new reference text, and is often a false positive for broad topics (one run: 6 of 7 flagged, guidance
absent for most), so grep two or three distinctive terms first, then read the target section. Give a
confirmed one `already-present` (or `add-note`/`fix` under the thresholds above) or keep it parked.
Grep misses paraphrased guidance, so read the section for every proposed fix.
