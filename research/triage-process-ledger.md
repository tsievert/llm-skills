# Triage process ledger

Generic wording only (public repo). Created 2026-11-17 for maintenance review task 13. Append new rounds as dated sections.

## Section index

1. Requirements
2. Round 2026-11-17: why triage rounds bloated SKILL.md files
3. Open items
4. Log

## 1. Requirements

| # | Requirement | Date |
|---|---|---|
| R1 | Find why the process let "reported once" asides and appended paragraphs into SKILL.md bodies, and change the process. | 2026-11-17 |
| R2 | Items (a)-(h) of review task 13: size gate, replace-not-append, single-report routing, lint warnings, one canonical boilerplate, periodic bloat check, keyed outcomes, mandatory research checklist shown in the table. | 2026-11-17 |

## 2. Round 2026-11-17

### Sources

| Source | Status | Facts |
|---|---|---|
| Agent Skills specification https://agentskills.io/specification | read | Instructions (SKILL.md body) recommended under 5000 tokens and under 500 lines; detail goes to references loaded on demand; reference files kept one level deep and focused. No byte budget is given, so 12 KB (info) and 16 KB (warn) are this repo's own thresholds (roughly 3000 and 4000 tokens). |
| Triage skill and `references/triage-method.md` (local) | read | Root cause found: the evidence-threshold table itself instructed wording such as "reported once" for cheap notes and "reported, not reproduced", and step 6 had no placement or size rule, so each round appended provenance to SKILL.md. The line "do not add a lesson's story" existed but contradicted those rows. Research was required only in step 3 and was not shown in the table. |
| `lint_skills()` (local) | read | Had a 500-line check only; no byte budget and no provenance check. |

### Changes (tasks (a)-(h))

| Item | Change |
|---|---|
| a, b, c | New section "Where a change goes" in `triage-method.md` (replace or merge, one-project findings to references, no provenance, 12 KB budget); three-line "Gates" section near the top of SKILL.md. The threshold rows no longer prescribe provenance wording. |
| d | `lint_skills()`: `size_bytes` (info above 12 KB, warn above 16 KB) and `provenance` (info) checks. |
| e | Already handled in task 2 (one short canonical text); stated as a gate rule. |
| f | Usage review mode exists (`references/usage-review.md`); `lint_skills()` now surfaces size, so the manual size view is replaced by the lint output. No separate periodic step added. |
| g | Already in step 7 (task 4). |
| h | New "Research checklist" in `triage-method.md`, the "Research row per issue" gate in SKILL.md, a research column in the step 5 table, and `assets/research-ledger-template.md`. No research row means `park` or `needs-info`. |
| extra | Work-copy bash block moved to `references/work-copy.md`, step 7 and step 1 shortened (SKILL.md 13.8 to 12.6 KB). |

### Facts and limits

- The lint census after the change: one warn (keypoint-moseq, 18.4 KB), nine skills in the 12-16 KB info band, 14 skills with provenance phrases (info). Not cleaned up here: that is a separate trimming pass per skill.
- Not tested: the new gates have not been applied in a real triage run; the research column is a rule, not enforced by a script.
- `skill-lessons`, `agents-md-maintenance` and `create-skill`: no change needed for these gates. `skill-lessons` still contains one provenance phrase.

## 3. Open items

| # | Item | Status |
|---|---|---|
| O1 | Trim keypoint-moseq SKILL.md below 16 KB. | done 2026-11-17 (18.4 to 15.0 KB; species checks and tested-status moved to references) |
| O2 | Optional pass over the 14 skills with provenance phrases (move to ledgers). | open |
| O3 | Apply the gates in the next real triage run and check the table is not too wide. | done 2026-11-17 (applied in the third triage run; research column fit) |

## 4. Log

- 2026-11-17: round 1 done; edits uncommitted.
