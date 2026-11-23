# Triage run 2026-11-23b (26 new entries, two same-day sessions about triage and skill maintenance)

## Requirements

| # | Decision | Date |
|---|---|---|
| 1 | Triage the inbox (user request) | 2026-11-23 |

## Research rows (checklist: repro / upstream / CRAN / OpenAlex / skill text read / cause)

| Entries (L$n) | Issue | Skill text read | Result |
|---|---|---|---|
| 182, 181, 191 | churn helper, last-rework date, what runs every time | SKILL.md step 3, usage-review.md, churn.R, rework-log.tsv | `usage_churn_table()` exists with `last_rework`/`since_rework` columns, step 3 says every run shows top five: already-present. Upstream/CRAN/OpenAlex n/a (own tooling). |
| 173 | check_sync_setup blocked in assistant session | github-skill-maintenance SKILL.md ~l.90 | already says: ask user to paste settings, pass as `cfg`: already-present |
| 170, 189 | CRLF returns after edit tool | SKILL.md l.110, pitfalls | documented; only "normalise before first lint" absent: add-note in pitfalls |
| 186 | partial close-out | archive-checklist.md (read whole) | no variant exists: fix (reference, +3 lines). Repro n/a. |
| 168 | new count mixes actionable and note-only | SKILL.md step 1 | no split: fix on rung 3 (print split in step 1 snippet / helper) |
| 174 | no-backlink row direction | check_skill_links.R l.73 | message does not print the row: fix rung 3 (script message). Cheap test: run function. |
| 188 | net-size check by hand | rework.md l.31 | rule exists, no check: add-note (before/after file.size in verify) |
| 190 | rm -rf blocked | work-copy.md | already says ask; add "offer before commit": add-note |
| 178, 179 | misfiled parked entry; hook fires on rework reads | not read in depth | one report, behaviour change: park |
| 167 | missing bash `description` | n/a | tool-use slip: reject |
| 183, 185 | likely_stale over-fires | triage-method.md l.150-156 | caveat already present: already-present |
| use-case / worked-well (166,169,171,172,175-177,180,184,187) | notes | n/a | no-change |

## Log

- 2026-11-23: read inbox copy (19 files, 26 new, 23 parked), target_scan, churn top 5, parked_recheck (15 flagged, hand checks outstanding).
