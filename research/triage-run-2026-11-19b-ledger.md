# Triage run 2026-11-19 (second run)

## 1. Issues (44 new entries incl. 5 use-case, 21 parked from earlier runs)

Research = skill text grepped/read on 2026-11-19 (no upstream reproduction this run; kpms facts are first-hand from the reporting sessions).

| Issue | Entries | Research (skill text read) | Proposed outcome |
|---|---|---|---|
| kpms port checklist: AST sdist-vs-wheel diff, min_duration units, drop pre-0.8.6 knobs, num_iters is end index, PCA frame cap, replay test, ask for last-run tar, unreferenced scripts | 61, 69, 71, 75, 76, 80, 81, 84, 102 | `keypoint-moseq-workflow.md` l.166 says try plain fit first; no `sdist`, `PCA_fitting_num_frames`; l.83-87 uses num_iters without semantics | fix (reference) |
| kpms headless calibration reuse, default error_estimator | 78, 103 | `common-problems.md` l.29 has headless copy of slope/intercept; no default-value check | fix (reference) |
| kpms failure modes: NaN is a warning, jax 0.12 config reads, apply_model verbose clash, plotting needs all coords, density_sample on tiny data, setup_project project_path | 70, 72, 83, 99, 100, 101 | none of the terms in skill folder | fix (reference) |
| Windows Git Bash: python is a Store stub, uv venv, CRLF from write tool | 66, 74, 82, 106 | heredoc truncation in `pitfalls.md`; python3 only used inside scripts | fix (one line each) |
| Accept and ignore deprecated flags | 104 | not in hpc-python-code | fix |
| Version-claim places, table order | 186, 187 | claim sits in SKILL.md and workflow table | fix (reference) |
| Triage: likely_stale only nominates; variant leftover work copies; lint filter one-liner | 181, 183, 185 | triage-method/work-copy/github-skill-maintenance read | fix |
| Low-confidence or untested single reports | 62, 63, 64, 65, 77, 85, 105 | one report, untested on GPU/cluster or unconfirmed | park |
| Outdated fact weak | 71 merged above | | |
| Slips / user-specific | 67, 184 | n/a | reject |
| Use-case, worked-well | rest | n/a | no-change |
