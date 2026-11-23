# Rework proposal: deeplabcut-hpc and hpc-job-scripts SKILL.md (2026-11-23)

Status: PROPOSED, not applied. Needs user approval of the inventory and new shape (rework gate, step 5).

## Requirements

| # | Requirement | Date |
|---|---|---|
| 1 | Propose a rework of both SKILL.md files, starting with a rule inventory and the parked entries | 2026-11-23 |

## Churn evidence

| File | Size | Commits (60 d) | Parked entries | Provenance phrases in text |
|---|---|---|---|---|
| deeplabcut-hpc/SKILL.md | 13.3 KB (over 12 KB) | 27 | 5 (98, 103, 104, 110 plus 1 closed-adjacent) | 5 ("Reported once", "2 sessions", "reported once, corrected twice", "in one report", "Two local sessions") |
| hpc-job-scripts/SKILL.md | 11.8 KB | 23 | 4 (36, 37, 48, 92) | 7, almost all in one Gotchas table cell |

Most commits are earlier triage runs that each appended one fact (dates 2026-10-23 to 2026-11-19).

## Underlying design problem

- **deeplabcut-hpc**: one file mixes four jobs (live-docs lookup procedure, install facts, a pitfall checklist whose detail already lives in references, a script skeleton), so each triage run finds a plausible place to append. Items 4, 7, 8, 12 are summaries of reference text plus provenance.
- **hpc-job-scripts**: the Gotchas table has one cell (CRLF) of about 1,500 characters that duplicates `github-skill-maintenance` pitfalls and the `check_sbatch.sh` CRLF check; the orchestrator bullet in Script rules duplicates `references/chaining-and-orchestrators.md`.

## Rule inventory: deeplabcut-hpc/SKILL.md

| # | Rule | Why (source) | Action |
|---|---|---|---|
| D1 | Load hpc-cluster-docs and hpc-job-scripts before any submit command/orchestrator | triage entry, orchestrator task skipped them | keep, shorten, drop "Reported once" |
| D2 | DLC changes fast; verify against live docs | original | keep |
| D3 | Where this skill runs (5 bullets) | standing repo rule | keep requirement bullet and one sentence; the rest merges (same text in every HPC skill) |
| D4 | Step 1: llms.txt, manifest, docs.jsonl, api.jsonl 404 note, doc page list | research ledger | move to references/docs-and-environment.md, keep two-line pointer |
| D5 | Step 2: load generic skills | duplicates D1 | merge into D1 |
| D6 | Environment: Python versions, headless install, torch before DLC, install on login node, TF avoid, GPU >= 8 GB | docs 3.0.2 | move to references/docs-and-environment.md |
| D7 | uv/python PATH bullet | cross-skill note | move to same reference (not DLC-specific) |
| D8 | Workflow split table | original | keep (short) |
| D9 | Pitfalls 1 to 11 (config path, MPLBACKEND, engine, epochs, workers, batch, resume, shuffles, caching, video I/O, downloads) | docs and ledger | keep as a table: pitfall, rule, detail link; one line each |
| D10 | Pitfall 12 re-split and evaluation fallback | two sessions, unconfirmed on cluster | move to pitfall-details.md (already holds detail), SKILL.md keeps one table row |
| D11 | pytorch_config tuning pointer | original | keep |
| D12 | Sweeps: exhaust `net_type` first | user corrected twice | keep as one line, no provenance |
| D13 | Job script skeleton (sbatch plus train_dlc.py) | original | move to assets/train-job.sh and assets/train_dlc.py; pointer in SKILL.md |
| D14 | Upstream search pointer | original | keep |
| D15 | Not verified paragraph | honesty | keep, shorten, drop session counts |
| D16 | Related, Explain, Capture | standing rules | keep unchanged (canonical text) |

Target: 13.3 KB to about 8 KB.

## Rule inventory: hpc-job-scripts/SKILL.md

| # | Rule | Why | Action |
|---|---|---|---|
| H1 | Where this skill runs | standing rule | keep |
| H2 | Workflow steps 1 to 5 | original | keep |
| H3 | Script rules (directives first, --time, --mem, set -euo, CPUs, login node, arrays, chaining, provenance) | original | keep |
| H4 | Orchestrator paragraph inside chaining bullet (about 8 lines) | 2026-10-24 entry | merge: keep two lines plus pointer (full text is in the reference) |
| H5 | Array concurrency formula N = floor(limit / cpus) | triage 2026-11-11 | keep |
| H6 | Logs summary | original | keep |
| H7 | Arrays/scratch, time limits, requeue summaries | original | keep |
| H8 | Gotchas: CRLF cell (grep -U, file, .gitattributes, edit tool, write tool, heredoc truncation, sed/awk quoting) | 5 separate entries | move whole detail to references/windows-line-endings.md; row becomes one sentence plus pointer. Enforcement already exists (`check_sbatch.sh`), and the repo-level lint now has an eol check |
| H9 | `.slurm` extension row, cause not established | one report | move to the new reference or drop; unverified |
| H10 | Remaining Gotchas rows (log dir, pending, buffering, CPUs, requeue, wrapper tmp file, shared file, afterok, scratch) | various | keep |
| H11 | Related, Explain, Capture | standing | keep unchanged |

Target: 11.8 KB to about 9 KB; one new reference file (about 1.5 KB).

## Parked entries (9, all unresolved)

| Entry | Skill | Proposed disposition | Where |
|---|---|---|---|
| 36 grep evidence has blind spots | hpc-job-scripts | add-note (medium) | chaining-and-orchestrators.md, one bullet |
| 37 untracked folder moves need MOVES.tsv plus revert script | hpc-job-scripts | stay parked (low, one report, generic file-reorganisation, not HPC) | none |
| 48 smoke chain needs one throwaway root | hpc-job-scripts | stay parked (low); reconsider if a second report appears | none |
| 92 parent process of a GPU search must not import JAX | hpc-job-scripts | misfiled: belongs in hpc-gpu-jobs; park there (low, one report) | none |
| 98 older benchmark exports lack split hash | deeplabcut-hpc | add-note (medium) | training-sweeps.md benchmark section |
| 103 PoseConfig.build output is noisy | deeplabcut-hpc | merge with 110 into one bullet | training-sweeps.md |
| 104 assistant R session cannot read scratch | deeplabcut-hpc | reject for this skill: covered by the work-copy note and not DLC-specific | none |
| 110 dry-run needs sibling submit stub | deeplabcut-hpc | add-note, merged with 103 | training-sweeps.md |

## Fix ladder and alternatives

- Rung 2 (structure): move blocks by topic into references, tabulate the pitfalls, remove provenance.
- Rung 3 already exists for CRLF (`check_sbatch.sh`; repo eol lint). For the DLC pitfall list a lint would not help.
- Alternative not taken: split deeplabcut-hpc into two skills (setup, sweeps). Not proposed because trigger overlap would be heavy and the description is already near the limit (987 chars).
- Alternative not taken: retire the "Where this skill runs" copy in every HPC skill via shared text. Standing repo rule requires each skill to state it; shortening is cheaper.

## Verification plan

`lint_skills()`, `skills-ref validate` for both, `check_skill_links()` if related sections change, `bash scripts/check_sbatch.sh` unchanged. Compare new text with inventory: every keep and merge row findable. Not testable: behaviour on a real cluster.

## Log

- 2026-11-23: read both SKILL.md whole, git history (27 and 23 commits in 60 d), 8 parked entries; nothing edited.
- 2026-11-23 (applied, approved by user): deeplabcut-hpc/SKILL.md 13.3 KB to 9.0 KB (docs lookup and environment to `references/docs-and-environment.md`, skeleton to `assets/train-job.sh` and `assets/train_dlc.py`, pitfalls tabulated, provenance removed); hpc-job-scripts/SKILL.md 11.8 KB to 10.4 KB (CRLF and `.slurm` rows to `references/windows-line-endings.md`, orchestrator bullet cut to two lines). Add-notes: 98 and 103/110 in training-sweeps.md, 36 in chaining-and-orchestrators.md. Entries 37, 48, 92 stay parked; 104 rejected for these skills. Checked: `lint_skills()` (no errors or warnings except pre-existing CRLF working copies, normalised), `skills-ref validate` both, `check_skill_links()` clean after one no-backlink row, `check_sbatch.sh` on the new asset script (no errors). Not tested: any real cluster run; trigger behaviour after the rework.
