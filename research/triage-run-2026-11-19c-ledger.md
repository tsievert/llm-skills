# Triage run 2026-11-19 (third run)

Input: 29 new entries (incl. 7+7+3 use-case/worked-well), 24 parked from earlier runs. Watermark was 2026-11-19T13:44:37; 6 usage rows since.
Research = skill text grepped/read on 2026-11-19. No upstream reproduction this run: kpms/Slurm facts are first-hand from the reporting sessions and unverifiable locally (cluster); `grep -U` and sed-backslash behaviour are shell facts seen in the session.
Entry numbers are valid for this run only (keys: file, skill, title).

## Existing text found

| Topic | Where | Finding |
|---|---|---|
| gate/check job after a step | hpc-job-scripts/references/chaining-and-orchestrators.md l.52 | one line (marker-file check job); no stale-status-file rule, no tee note |
| `--export` comma splitting | same file l.103 | present; env-prefix workaround not stated |
| fake sbatch, two-stage test | grep whole repo | absent |
| `grep -U` | hpc-job-scripts/SKILL.md gotchas | present; "tests/scripts must use -U" not stated |
| heredoc truncation | SKILL.md + github-skill-maintenance pitfalls | present; the shell warning as symptom not stated |
| copy verification (ls/wc -c) | hpc-job-scripts | absent |
| NaN in kpms | keypoint-moseq/references/common-problems.md l.35 | general row; seed-on-tiny-fit not stated |
| ledger template entry numbers | skill-feedback-triage/assets/research-ledger-template.md l.20 | says "entry numbers or keys" |
| first-hand research row wording | skill-feedback-triage | absent (triage-run ledgers use "first-hand") |
| stale-flag recheck of 24 parked | grep of distinctive terms | 14 flagged, none actually covered (MOVES/sha256, outlier mapping, dry-run stub, sync message, version filter, scratch read, PAF noise, section helper, no-targets): all stay parked |

## Log

- 2026-11-19: ledger written before presenting the table.
