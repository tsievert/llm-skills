# CRediT author-contribution statements

Wraps the CRAN package `CRediTas` (rOpenSci-reviewed, zero dependencies) via
`scripts/credit.R`. Do not hand-roll the role list or the statement formatting — `CRediTas` already does
both correctly; this skill only adds a LaTeX output path (CRediTas documents markdown/text only) and a
per-role grouping option.

## What CRediT is and is not

CRediT (Contributor Roles Taxonomy) is the ANSI/NISO Z39.104-2022 standard naming 14 roles. It describes
*contributions*, not authorship eligibility — authorship itself is set by the journal's policy (usually
ICMJE criteria), and CRediT is filled in after the author list is already decided. The 14 roles:
Conceptualization, Data curation, Formal analysis, Funding acquisition, Investigation, Methodology, Project
administration, Resources, Software, Supervision, Validation, Visualization, Writing – original draft,
Writing – review & editing.

Two output conventions are both common in published statements:
- **Per author**: "Jane Doe: Conceptualization, Methodology."
- **Per role**: "Conceptualization: Jane Doe, John Smith."

Some publishers (Wiley, Elsevier, Taylor & Francis) accept a lead/equal/supporting degree-of-contribution
qualifier added to a role; Nature/Cell journals usually do not — check the target journal's instructions
before adding one (`CRediTas`/this wrapper do not support degree qualifiers; add them by hand after
generating the base statement if the journal wants them).

## Workflow

```r
source("manuscript-writing-quarto/scripts/credit.R")

credit_template(c("Jane Doe", "John Smith"), "credit.csv")
# Open credit.csv in a text editor or spreadsheet. Put a 1 under every role
# each author contributed; leave 0 otherwise. The user makes every
# assignment — this skill never infers who did what.

tbl <- credit_table("credit.csv")
credit_statement(tbl, "credit_statement.md")                       # per-author, markdown
credit_statement(tbl, "credit_statement.tex", format = "latex")    # per-author, LaTeX
credit_statement(tbl, "credit_statement_by_role.md", by_role = TRUE)
```

Then paste the generated statement into the manuscript's "Author contributions" section (or the journal
submission form), from the same CSV, so it is never retyped by hand.

## The round-trip gotcha

`CRediTas::template_read()` (used inside `credit_table()`) already reads the CSV with
`check.names = FALSE`, so role names like `"Writing - original draft"` survive intact. The failure mode is
reading the CSV through base R's `read.csv()` with its *default* settings in between (for example, to peek
at it or edit it programmatically) and writing it back out: `read.csv()`'s default `make.names()` mangles
spaces, dashes and ampersands into dots, and every downstream step then treats the mangled string as the
literal role label (confirmed by testing: a round trip through default `read.csv()`/`write.table()` turned
`"Writing - original draft"` into `"Writing...original.draft"` in the final statement). Edit the CSV
directly in a text editor or spreadsheet; if you must script an edit, use
`read.csv(file, sep = ";", check.names = FALSE)` explicitly.

## Non-standard role lists

If a journal wants a different or extended role list, pass `roles = c(...)` to `credit_template()`. This is
rare — check the journal's author guidelines before deviating from the standard 14.

## Out of scope

- A graphical contributions figure (as opposed to a text statement) — the CRAN package `contribution` does
  this but was not evaluated in depth; mention it as an option if the user specifically wants a figure.
- Degree-of-contribution qualifiers (lead/equal/supporting) — add by hand per journal policy.
