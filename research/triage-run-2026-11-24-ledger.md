# Triage run 2026-11-24 (34 new entries: 20 actionable, 14 note-only; 25 parked, 154 closed)

## Requirements

| # | Decision | Date |
|---|---|---|
| 1 | Triage the inbox (user request) | 2026-11-24 |

## Research rows (checklist: repro / upstream / CRAN / OpenAlex / skill text read / cause)

| Entries (L$n) | Issue | Skill text read | Result |
|---|---|---|---|
| 123, 131 | unique bodyparts block top-down/CTD | ctd-topdown-preflight.md l.8 | text added 2026-11-23 14:04 (rework commit 8ab7a7b), same day as the reports; sessions likely loaded the pre-rework text: already-present, verify on next report |
| 130 | CTD conditioner must be bottom-up | ctd-topdown-preflight.md pre-flight list | list says "reference shuffle equals the bottom-up condition shuffle", no explicit task check or error message: add-note |
| 120, 129 | export field map; stale export | benchmark-interpretation.md | schema NULL-safety note only; no field map, no staleness check: add-note (short) |
| 121, 122 | defaults table, default detector | benchmark-interpretation.md "What default means" | procedure to record defaults exists; detector identity unverified: park (needs cluster/DLC check) |
| 124, 132 | PAF evaluation failures | ctd-topdown-preflight, training-sweeps (PAF mentions only for config build) | cause undiagnosed, low confidence, two projects: park |
| 134, 139, 127 | user decision, edit-tool, own R slip | n/a | likely-user-specific: reject |
| 3, 135 | R session cannot write scratch | benchmark-interpretation.md (read side stated) | write side missing: add-note (merge into the same sentence) |
| 137 | several orchestrator generations | n/a | one report, project-specific: park |
| 74 | wrapper ignores CLI option | capacity-benchmark.md | one report, tool-specific: park |
| 75 | margin below measured pass | capacity-benchmark.md l.8 ("ceiling plus a margin") | margin present; short-benchmark time projection is an upper bound absent: add-note |
| 78 | set_mixed_map_gpus mechanics | keypoint-moseq-workflow.md l.172 | only the FAQ mention; from source reading, 2 fake CPU devices, no GPU run: add-note flagged untested |
| 80 | regex in non-raw heredoc string | hpc-python-code SKILL.md l.90 | heredoc escape caution exists; raw-string clause absent: add-note (merge) |
| 211, 213 | ledger gate; wide listings | SKILL.md step 1 (width option) | 213 already-present; 211 one report: park |
| use-case / worked-well / note-only | notes | n/a | no-change |
