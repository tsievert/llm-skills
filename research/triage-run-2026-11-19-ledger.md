# Triage run 2026-11-19

## 1. Issues (57 new entries, 19 parked from earlier runs; 105 closed skipped)

| Issue | Entries | Research (skill text read) | Outcome |
|---|---|---|---|
| Gate counts skipped tests as passed; tests assert literal status text | 37, 38 | `staged-assistant-workflow/SKILL.md` gate item had no skip rule | fix (merged into gate item 4) |
| `!expr` in `tbl-cap` needs single quotes | 52 | not in quarto skill | fix (`linting-checklist.md`) |
| CUDA error 303 on login node | 80 | not in `hpc-and-troubleshooting.md` | fix |
| kpms migration checklist (live entry point, old args, capacity ceiling) | 72, 73 | nothing in kpms refs; SKILL.md already over 12 KB, so reference file | fix (`keypoint-moseq-workflow.md`) |
| Clean-clone: untracked-file inventory, deposit contents | 57, 58 | `contents-and-layout.md` step 2 lacked it | fix |
| Debug partition, VRAM per partition | 81, 82 | `hpc-gpu-jobs` line 32 had debug partition; VRAM caveat missing | add-note |
| Orchestrator weaknesses | 76 | `chaining-and-orchestrators.md` covers exit-0 only | add-note |
| MC SE of max-t critical value; null-SD disagreement | 62, 65 | `uncertainty-and-inference.md` covered SD floors only | add-note |
| Already covered | 47, 48, 53, 181 | pitfalls.md heredoc, agents-md-maintenance splice, openalex query-refinement, triage SKILL.md n column | already-present |
| Parked, now covered | 5, 118, 123 | `gam-mgcv/references/coverage-simulation.md`; `training-sweeps.md` dlcrnet row | already-present |
| Assistant slips or user-specific | 42, 43, 54, 75, 77, 173, 174 | n/a | reject |
| tapply array, SVD cost, skip lists, lint filter, kpms 0.8.7 | 41, 49, 60, 179, 79 | one low-confidence report each; 0.8.7 notes unread | park |
| Use-case and worked-well | 28 entries | n/a | no-change |
| Stale-flagged parked entries (10, 88, 94, 104, 105, 111, 131, 155, 160, 162, 166) | | `parked_recheck` flag is a term-overlap screen; targets did not show the suggested text | stay parked |

## 2. Log

- 2026-11-19: table approved ("approve all"); edits applied; stale-flag closure limited to 3 entries verified by reading the target.
