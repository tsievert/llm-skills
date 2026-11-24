# Triage run 2026-11-24b (9 new entries, all about triage and maintenance in one session; first run with the patch gate)

## Requirements

| # | Decision | Date |
|---|---|---|
| 1 | Run the next triage with the patch gate and use it to tune thresholds (user) | 2026-11-24 |

## Research rows

| Entries (L$n) | Issue | Skill text read | Result |
|---|---|---|---|
| 215 | print of lesson listing errors | reproduced: `L` is a plain data.frame, so `print(x, n = 5)` passes `n` as `na.print` | own slip, not a skill fault: reject |
| 216 | entries filed the day of a rework | triage-method.md "Recurrence" | no rule on session time vs fix commit time: add-note (compare `git log -S` time with session time) |
| 217 | keep list can equal all files | archive-checklist.md | not stated that this is expected: add-note |
| 218 | wrong number from `lesson_dupes()` | read_lessons.R l.151 | output has no `L$n`, only file and title; reproduced (names: skill, a, title_a, b, title_b, dist): fix on rung 3 (add `n_a`, `n_b` when `n` exists) |
| 220 | eol warning on touched skills | lint message text | message already says to normalise before commit: already-present |
| use-case / worked-well (214, 219, 221, 222) | notes | n/a | no-change |

## Patch gate (first real use)

`patch_gate()` on the three proposed files: all three `rework-or-defer` (read_lessons.R: 12 edits, 20.5 KB;
triage-method.md: 11 edits, 12.6 KB; archive-checklist.md: 3 edits). Verdicts did not discriminate: the skill-level
trigger (3 proposals in one skill) fired because every entry was about the triage skill itself, and file edit counts
include rework and new-content commits.

Outcome: apply 3 patches, defer reworks of read_lessons.R and triage-method.md (recorded), tune per-skill trigger to 4 or more distinct files.
