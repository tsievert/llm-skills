# Triage run 2026-11-26 research ledger

Generic wording only (public repo). Created 2026-11-26. 305 entries read, 228 closed, 48 open (23 worked-well or use-case notes), 29 parked.

## Section index

1. Requirements
2. Round 2026-11-26: issues A-L
3. Open research items
4. Log

## 1. Requirements

| # | Requirement | Date |
|---|---|---|
| R1 | Apply issues A-H and K(292) as proposed; do the triage-skill rework (J) as a separate change | 2026-11-26 |

## 2. Round 2026-11-26

Research basis: the entries themselves (one DLC benchmark session, one kpms session, one cluster session, one triage session) and a read of each target file. No upstream reproduction was run; claims below are carried from the entries and marked as such.

| Issue | Checklist result | Placement |
|---|---|---|
| A default-run definition (DLC) | Skill text read: `benchmark-interpretation.md` said batch size is a model parameter; user ruled otherwise. Rule recast as per-project ruling. Not reproduced (user decision). | `benchmark-interpretation.md` |
| B benchmark parsing | Skill text read. `bind_rows` type error is a standard dplyr behaviour; other notes from logs of one session. | `benchmark-interpretation.md` |
| C scheduler rescale | Rule E//2 from the rtmpose model template comments (entry 202, source not re-fetched here); `pytorch_cfg_updates` list replacement from entry 203. Effect claim (190) parked as untested. | `pytorch-config-tuning.md`, `training-sweeps.md` |
| D CTD conditioner | Already stated in the pre-flight file for evaluation; added ranking restriction. | `training-sweeps.md` |
| E Git Bash CRLF recipe | Not reproduced; the sed `\r` and CRLF-in-edit-tool traps are consistent with the existing file text. | `hpc-job-scripts/references/windows-line-endings.md` |
| F cluster paste and quota | Skill text read; generic fallback commands. | `hpc-cluster-docs/SKILL.md` |
| G QOS minimum | Single report, unresolved at the time. Command `sacctmgr show qos` is standard Slurm. | `hpc-job-scripts/SKILL.md` |
| H kpms seed spread | One report; consistent with the existing parallel-grid note. SKILL.md was 14.7 KB; moved the helper table, jitter, bodypart-order and read-date text out (to references) to get 13.0 KB. | `keypoint-moseq` |
| I nvidia-smi buffering | needs-info: `stdbuf -oL` untested, cluster-only. | none |
| K check_versions filter | Example added. | `github-skill-maintenance/SKILL.md` |
| L bash description slip | reject, assistant-side. | none |
| J triage tooling | Separate rework change (see log). | `skill-feedback-triage` |

## 3. Open research items

| # | Item | Status |
|---|---|---|
| 1 | Test `stdbuf -oL nvidia-smi -l 30 -f` on the cluster | open (needs user) |
| 2 | Verify the rtmpose SequentialLR rule against DLC source | open |

## 4. Log

- 2026-11-26: edits A-H, K applied; lint pending at time of writing.
