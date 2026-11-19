# Triage run 2026-11-20 (fifth run)

Input: 26 new entries (3 files, one project; 3 use-case, 4 worked-well), 25 parked/earlier. Watermark was 2026-11-19T22:05:09.
Research = skill text grepped/read on 2026-11-20. Slurm/kpms facts are first-hand from the reporting sessions (cluster, not reproducible locally).
Entry numbers are valid for this run only (keys: file, skill, title). Parked-recheck flagged 24 of 25 by term overlap (11 likely_stale); not read individually.

## Existing text found

| Topic | Where | Finding |
|---|---|---|
| GPU OOM is a plain MemoryError | keypoint-moseq/references/common-problems.md l.43 | present (entry 116 = already-present) |
| sacct `<array>_<task>`, JobName truncation | hpc-resource-allocation/SKILL.md, hpc-job-scripts logs-and-output | present (entry 117) |
| float32 not the NaN cause from 0.8.6; jitter caveats | common-problems l.35, hpc-and-troubleshooting l.57, workflow l.45 | present; jax-moseq version check and "jitter likely no effect with parallel sampler" absent (second claim only from the entry, not verified) |
| capacity benchmark: only GPU OOM is a ceiling, NaN inconclusive | hpc-resource-allocation/references/capacity-benchmark.md | present; known-good control run and check against production file-selection rule absent |
| silent data-loading looks hung | grep whole set | absent; parked #108 plus entry 119 = two sessions, one project |
| sourcing batch helpers that `exit` in a login shell | hpc-job-scripts grep | absent |
| per-submission files read by array tasks need unique names | hpc-job-scripts/SKILL.md l.88 (per-task files), arrays-and-scratch l.33 | concurrent tasks covered; two submits sharing a batch id absent |
| triage step 7 chained mv/cp/rm | skill-feedback-triage/SKILL.md step 7; references/work-copy.md l.15-18 | work-copy.md covers a blocked rm; step 7 checklist does not say to split commands |
| variant leftover work folders | work-copy.md l.18 | present (entry 215); lessons-work2/3 exist again today |
| parked_recheck is a hint only | triage-method.md l.116-117 | present (entries 216, 221) |
| CRLF in working copy | github-skill-maintenance/SKILL.md l.110 | present (entry 218) |

## Log

- 2026-11-20: ledger written before presenting the table.
