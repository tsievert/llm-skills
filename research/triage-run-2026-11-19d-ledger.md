# Triage run 2026-11-19 (fourth run)

Input: 27 new entries (2 files, one project; 3 use-case, 4 worked-well), 27 parked/earlier. Watermark was 2026-11-19T16:40:04.
Research = skill text grepped/read on 2026-11-19 plus one local shell test. Slurm/kpms facts are first-hand from the reporting sessions (cluster, not reproducible locally).
Entry numbers are valid for this run only (keys: file, skill, title).

## Existing text found

| Topic | Where | Finding |
|---|---|---|
| gate/check job after a step | hpc-job-scripts/references/chaining-and-orchestrators.md l.56 | present (entry 86 = already-present) |
| `sacctmgr show qos`, MinTRES | hpc-job-scripts/SKILL.md l.56 mentions the command only | MinTRES, named-field query absent |
| sacct array id form `<job>_<task>`, JobName truncation, grep dropping `.batch` | hpc-resource-allocation/SKILL.md l.38-44, hpc-job-scripts logs-and-output l.47-54 | absent; squeue-vs-sacct per-task partly (l.54) |
| capacity benchmark / ladder / bisection | hpc-gpu-jobs l.55 (record partition + GPU model only) | absent; no hpc-resource-allocation references folder |
| `eval "$(cmd)"` failure hiding | whole repo grep | absent. Local test 2026-11-19: `eval "$(false)"` rc=0, `x="$(false)"` rc=1 (reproduced) |
| CRLF after edit tool | hpc-job-scripts/SKILL.md l.115 (table row, grep recipe, `file` for .slurm) | present; "re-check after every tool edit" and exact-once patch scripts absent. SKILL.md is 12092 B, so new text goes to a reference |
| JAX GPU memory sources | keypoint-moseq/SKILL.md l.48 (preallocation) | `peak_bytes_in_use` absent; unverified on a GPU |
| kpms GPU OOM wording | keypoint-moseq/references/common-problems.md l.42, hpc-and-troubleshooting l.56 | MemoryError-with-GPU-wording absent |
| CUDA plugin traceback on CPU | hpc-and-troubleshooting l.21 | present for `cuInit` error 303; `cuda_device_count` SystemError variant absent |
| silent data-loading looks hung | grep whole set | absent; one low-confidence report |
| default #SBATCH memory copied from old runs | grep | absent; one report, generality unsure |

## Log

- 2026-11-19: ledger written before presenting the table. Parked-recheck flagged 15 of 27 as likely_stale by term overlap; not read individually this run.
