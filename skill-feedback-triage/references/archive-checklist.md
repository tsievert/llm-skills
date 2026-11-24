# Archive checklist (step 7)

Work through this checklist in order, in the real inbox (not the copy):

- [ ] The user has seen the triage table (no archiving or watermark before that).
- [ ] Build the keep list from the triage table: every file that contains a `park` row of this run **and** every file with a parked-status entry from earlier runs (`unique(L$file[L$status == "parked"])`). Do not build it from memory.
- [ ] Move all other processed files with bash `mv ... inbox/processed/` in one command (the R session cannot write to the home folder), naming files directly (strip CRLF with `tr -d '\r'`), before deleting the work folder. A file that mixes resolved and parked entries stays in the inbox whole until every entry in it has a disposition other than `park`. If that keeps every file, nothing moves; that is expected, not an error.
- [ ] Key outcomes by entry number (`L$n`), never by row position of a re-filtered table, and build them on the same `L` that was printed. Build one outcome column on the entry table (one value per row) and check that every row got exactly one
  value (`table(L$outcome, useNA = "ifany")`, and no entry number in two outcome lists) before calling `dispositions_add()`.
- [ ] Record a disposition for **every** entry of this run, including use-case entries and entries in files you archive, so mixed files stay quiet next time. One call per outcome: `dispositions_add(L[rows, ], "fix" | "reject" | ..., ".posit/assistant/lessons-work/dispositions.tsv")`. `park` and `needs-info` keep an entry open. Allowed values: `fix`, `add-note`, `already-present`, `reject`,
  `no-change`, `new-skill`, `park`, `needs-info`; use-case entries get `no-change` (`use-case` is not a value and errors).
- [ ] Record the watermark with `triage_watermark_set(max(U$time))` before deleting the work folder (skip if `U` is empty; if the folder is gone, take the last timestamp from the real `usage.tsv`). Never truncate or edit `usage.tsv`.
- [ ] Copy the ledger back: `cp .posit/assistant/lessons-work/dispositions.tsv ~/.posit/lessons/dispositions.tsv`. The ledger is never committed or truncated.
- [ ] Delete `.posit/assistant/lessons-work` in its own last command (a blocked `rm -rf` chained after `mv`/`cp` cancels them). Check dispositions with `dispositions_read()`, not `read.delim`.
- [ ] Record each deferred rework from the patch gate with `rework_defer(target, reason)` (`scripts/churn.R`); an approved rework gets its `rework-log.tsv` row in its own commit instead.
- [ ] Add a generic-wording Log entry to `HISTORY.md` (counts, outcomes, what was not verified). Commit skill edits, never lesson files; the `AGENTS.md` watermark line and the `HISTORY.md` entry go in the same commit (CRLF-to-LF warnings are harmless).

## Partial close-out (a few entries, run not archived)

When the user closes only some entries (for example parked ones) without archiving the run: record one disposition
per closed entry with `dispositions_add()`, copy the ledger back (`cp ... ~/.posit/lessons/dispositions.tsv`, bash),
and stop. No watermark, no `mv` to `processed/`, no keep list; leave the work folder for the next step and say so.
