# Triage run 2026-11-25 (proposal stage, nothing edited yet)

## Inputs

| Item | Value |
|---|---|
| Inbox files copied | 24 (counts matched) |
| Status | new actionable 37, new note-only 13, parked 32, closed 181 |
| Watermark before | 2026-11-24T09:33:28 |
| `parked_recheck` | 16 flagged `likely_stale`; screen only, not verified by reading (not part of this run's table) |
| Uncommitted at start | `gam-interpretation/references/phrasing.md` (user's, not touched) |

## Research rows (checks done this turn: skill text read/grepped, `git log`, patch gate; no cluster or upstream reproduction possible)

| Issue | Entries | Skill text check | Result |
|---|---|---|---|
| gam: n_draws/n_sim, fixef, draw() panels, 3D deps, shape_intervals, difference_smooths sz | 252-254, 256-258 | all in `recent-developments.md`, `visualisation.md`, `uncertainty-and-inference.md` (commit 05666c1, same session) | already-present |
| gam: fixef glmmTMB exception | 255 | line 51 names nlme/lme4 only | add-note |
| gam: Rplots.pdf | 263 | no text | park (unsure) |
| one-device OOM hang | 81 | `--kill-on-bad-exit` present (SKILL l.91, multi-gpu.md); watchdog for single-process multi-device not present | add-note |
| shrunken allocator region | 96, 98, 100, 104, 105, 101 | keypoint-moseq `hpc-and-troubleshooting.md` only has JAX_PLATFORMS for login-node noise; hpc-gpu-jobs l.68 already logs nvidia-smi at start; earlier parked #137 is the same cause as #105 | 105 = cause (2 reports with #137); 96/98/100/104 = superseded hypothesis; 101 already-present |
| nvidia-smi sampler empty CSV | 102 | snippet at hpc-gpu-jobs l.101 | needs-info (cluster) |
| orchestrator hash / passthrough / test pinning | 91, 117, 99, 110 | nothing in chaining reference | fix (reference) |
| replicate/seed collisions | 111 | arrays-and-scratch rule 1 says "keyed by task id" | add-note (merge) |
| scancel id | 82 | arrays-and-scratch l.106 `scancel <jobid>` | add-note |
| kappa scan schedule, bisection, checkpoint snapshots | 95, 109, 112 | workflow l.128-132 only sequential/array scan; `iteration=` at l.85 | fix (one section rewrite) |
| capacity: user owns size, re-measure, disk/quota | 84, 93, 113 | capacity-benchmark.md has none | add-note (one bullet each, merged) |
| du command | 94 | none | add-note |
| command-paste format | 87, 108, 114 | user memory says setup once, later chunks rely on it: contradicts these failures | user-memory outcome |
| bash heredoc | 261 | pitfalls.md already says avoid | already-present |
| check_versions filter | 262 | none | park (unsure) |
| slips, env | 85, 90, 107 | 107 skill already says run `file` | reject / no change |
