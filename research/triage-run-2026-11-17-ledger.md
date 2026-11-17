# Triage run 2026-11-17 (research ledger)

Entry numbers (`L$n`) are positional for this run's read (13 inbox files: 60 closed, 43 new, 8 parked). Proposed
outcomes only; nothing archived until the user approves.

## 1. Research rows per issue

Checks: R = reproduction, U = upstream/docs, C = CRAN, O = OpenAlex, T = skill text read and grepped.
`n/a` = not applicable (reason in the row).

| Issue | Entries | R | U | C | O | T (result) | Proposed outcome |
|---|---|---|---|---|---|---|---|
| Use-case and worked-well notes | 70, 74, 77, 78, 80, 81, 85, 88, 96, 97, 98, 104, 105, 107, 109 | n/a | n/a | n/a | n/a | n/a | no-change |
| Grouped table / keyed outcomes / usage-review mode / frontmatter parse | 71, 72, 75, 76 | n/a | n/a | n/a | n/a | done: SKILL.md step 5/7, references/usage-review.md line 13 | already-present |
| Ledger for parked-entry research | 87 | n/a | n/a | n/a | n/a | done: Gates, research checklist, assets/research-ledger-template.md | already-present |
| Blocked deletion of work copy | 102, 111 | n/a | n/a | n/a | n/a | done: references/work-copy.md line 16 | already-present |
| CRLF breaks exact-match edits | 95 | n/a | n/a | n/a | n/a | done: github-skill-maintenance/references/pitfalls.md CRLF bullet | already-present |
| Loose OpenAlex search noisy | 82, 91 | n/a (tool behaviour, seen in entries) | n/a | n/a | n/a | done: openalex/references/r-workflow.md "Reported ... loose search" bullet already says use one filter per concept and prefer title.search | already-present |
| Boolean precedence matched unrelated words | 83 | not done (needs live API test) | not done | n/a | n/a | done: r-workflow.md has no precedence note; cause unresolved in the entry | park |
| Abstracts missing for some works | 84 | n/a | not checked (cause unknown) | n/a | n/a | done: no text on title-only sources | add-note (openalex/references/query-refinement.md, one line, no cause claimed) |
| fetch_epmc_xml outdir blocked outside project | 93 | entry shows it | n/a | n/a | n/a | done: fulltext.md has no outdir advice | add-note (fulltext.md) |
| oa_ft_grep on XML-derived text is page-less | 94 | entry shows it | n/a | n/a | n/a | done: fulltext.md line 43-46 describes page output only | add-note (fulltext.md; skill column in the entry says skill-lessons, target is openalex) |
| No python in bash for scripted edits | 89 | n/a | n/a | n/a | n/a | done: pitfalls.md has no python note | add-note (pitfalls.md, one line) |
| Parked recheck over-fires after a review | 101 | n/a | n/a | n/a | n/a | done: triage-method.md "Re-checking parked entries" already says it is a screen with false positives | add-note (one clause on same-review text) |
| Review stopping before archive can coexist with dispositions | 100 | n/a | n/a | n/a | n/a | done: usage-review.md says do not write dispositions, nothing on mixed state | add-note (usage-review.md, one line) |
| Postponed run: keep proposals in task file | 103 | n/a | n/a | n/a | n/a | done: work-copy.md covers deletion only | park (one report, process already worked) |
| Section-variant audit helper | 79 | not done | n/a | n/a | n/a | done: lint checks headings only (entry 78) | park (adds a script; one report) |
| check_versions noise; check_sync_setup error text | 108, 110 | n/a | n/a | n/a | n/a | not read in depth | park |
| Bulk validate one-liner | 109 | n/a | n/a | n/a | n/a | n/a | park (convenience; one report) |
| Long doc page fetch truncated | 99 | n/a | n/a | n/a | n/a | n/a | reject (tool behaviour, not skill guidance) |
| Tool-call slips | 86, 90, 106 | n/a | n/a | n/a | n/a | n/a | reject |
| Movable sensitivities block | 54 | n/a | n/a | n/a | n/a | done in task 10 | park |
| Docs-only research for hardware entries | 98 | n/a | n/a | n/a | n/a | n/a | no-change (merged with 29 in hpc-threading-ledger.md) |

Parked entries from earlier runs: 6 (Gantt) reject (low value, task 5); 11 (find-a-study) already-present (routing to
`openalex` added, task 5); 16, 21, 29, 44, 63, 69 stay parked (ledgers gam-mgcv, hpc-threading, manuscript-writing-quarto,
pipeline-resources).

## 2. Log

- 2026-11-17: ledger written when resuming task 11; table not yet approved.
- 2026-11-17: user approved; add-notes applied, run archived (watermark 2026-11-17T22:20:25).
