# Triage run 2026-11-18

## 1. Issues (41 new entries, 12 parked from earlier runs stay parked)

| Issue | Entries | Research (skill text read, repro, upstream) | Proposed outcome |
|---|---|---|---|
| Use-case and worked-well notes | 48, 50, 53, 57, 58, 61, 62, 63, 65, 67, 70, 72, 76, 79, 119, 122, 126 | n/a | no-change |
| DLC skill not loaded for benchmark-export analysis | 49, 51 | done: description already names "review or rank a benchmark JSON/export (even analysis-only)" and `prompt_signals` has `benchmark.{0,20}(json\|export)` | already-present |
| Hook dismissed / load-first rule skipped | 55, 68 | done: SKILL.md top line already says load hpc-cluster-docs and hpc-job-scripts first; skill right, assistant did not follow | already-present |
| Generated defaults, hist_eq off, CTD `ctd_conditions`, extend generator | 52, 69, 75, 77 | done: `pytorch-config-tuning.md` holds the 3.0.2 values; `training-sweeps.md` "What default means" has no pointer, no hist_eq or CTD note. DLC not installed locally, so not reproduced (error text quoted in entry) | add-note (training-sweeps.md, merged into existing bullets) |
| GPU peaks not comparable | 64, 71 | done: batch-size bullet has no caveat; one project | add-note (merge into batch-size bullet) |
| lesson helper ignores `project` | 56 | reproduced: `usecase_add(project="anon")` writes `project: anon` in both the file and the fallback text; not reproduced | reject |
| Step 7: bash for moves; entry in two outcome lists | 120, 123 | done: SKILL.md step 7 has the NA check only | fix (two small merges into step 7) |
| Benchmark export schema, noisy build output, scratch read, dry-run stub, dlcrnet defaults/build errors | 54, 59, 60, 66, 73, 78 | not reproduced (needs DLC); low or unsure | park |
| Postponed-run outcomes keyed by number | 121 | done: step 7 already says key by `L$n` on the same read | park |
| CRLF after edits | 125 | done: pitfalls.md CRLF bullet | already-present |
| Local Python missing, renamed columns, tool slip | 74, 80, 124 | n/a | reject |

## 2. Log

- 2026-11-18: ledger written; table approved; edits applied (training-sweeps.md, triage SKILL.md step 7), run archived.
