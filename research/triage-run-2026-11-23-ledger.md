# Triage run 2026-11-23 (ledger)

## Requirements

| # | Requirement | Date |
|---|---|---|
| 1 | Run target_scan; disposition the open entries; job-opportunity-watch and fetch entries (169-174) are resolved by the jobwatch split and the fetch-ladder commit (3a4c2d9, c61ea38) | 2026-11-23 |

## Target scan

| skill | edits (60 d) | busiest file | edits | new entries |
|---|---|---|---|---|
| github-skill-maintenance | 110 | SKILL.md | 22 | 6 |
| skill-feedback-triage | 56 | SKILL.md | 27 | 18 |
| job-opportunity-watch | 127 | scripts/jobwatch.R | 13 | 5 |
| skill-lessons | 20 | SKILL.md | 10 | 1 |
| web-fetching-r | 8 | SKILL.md | 4 | 1 |

## Research rows

| Issue | Reproduction | Skill text read | Cause |
|---|---|---|---|
| Backslashes collapse (168, 193) | Quoted bash heredoc with `\\(` came back as `\(` when sent through the bash tool; the collapse happens in the tool-call transport, not in bash (quoted vs unquoted heredoc identical). done | pitfalls.md and SKILL.md cover heredoc truncation only, not backslashes | Any backslash text through the bash tool is unsafe; applies to R regex, sed scripts |
| CRLF recurrence (178, 196) | `writeLines()` on Windows wrote `0d 0a`. done | pitfalls.md CRLF bullet says edit/write can reintroduce it; silent on writeLines and on order (normalise last) | Text rule exists but is not enforced |
| sub() backslash (179) | Replacement `"p\\q"` silently drops the backslash (`pqabc`), no warning. Control-byte case not reproduced exactly. partial | no coverage | Same class as 168 |
| reference-toc (180) | lint source reads: check at lint_skills.R:259 | message does not say which forms pass | message wording |
| testthat `_problems` (194) | not reproduced, known testthat behaviour | no coverage | gitignore |
| 167, 182, 183, 184, 186, 187, 192, 189 | skill text read (triage SKILL.md, triage-method.md, rework.md) | see table | see table |
