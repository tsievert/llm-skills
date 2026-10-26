---
name: manuscript-writing-quarto
description: Structures a Quarto manuscript for journal submission (project type manuscript, quarto-journals templates for ACM/ACS/AGU/Biophysical Journal/Elsevier/JASA/JSS/PLOS, line numbers, MECA bundles), generates a CRediT author-contribution statement from an author-by-role table (wraps CRediTas), and runs flags-only linting (spelling, grammar via LanguageTool, bibliography duplicate/DOI checks, non-standard characters) before submission. Use when the user asks to set up, structure, format or submit a Quarto manuscript for a journal, wants a CRediT statement or author contributions section, or wants a manuscript spell-checked, grammar-checked or linted before submission. Never writes autonomous prose and never edits the .bib file; figure export belongs to manuscript-figures-ggplot, the data/code deposit to reproducible-research-data, and Git/CITATION.cff to git-for-research-projects.
---

# Manuscript writing with Quarto

Structures the submission artifact and checks it mechanically. It does not write the paper's prose, does not
decide what the results mean, and does not touch files it should not own.

**Standing rules:**
- **No autonomous prose.** Draft text, suggest wording, or flag issues — never silently rewrite a paragraph
  the user did not ask to have rewritten. If a tool here (spelling, bib checks) finds something, report it as
  a finding, not an edit.
- **Never auto-edit the `.bib` file.** It is user-owned; checks here are read-only.
- **Every CRediT role assignment is the user's decision.** The skill never infers who contributed what.

## Workflow

1. **Structure the manuscript.** Work through the decision tree in
   [references/journal-templates.md](references/journal-templates.md): does `quarto-journals`
   (https://github.com/quarto-journals) have the target journal (ACM, ACS, AGU, Biophysical Journal,
   Elsevier, JASA, JSS, PLOS)? If yes, install that template inside a Quarto manuscript project
   (`project: type: manuscript`); if no, use the generic manuscript project plus the journal's own
   Word/LaTeX template. Confirm template options (and the current `quarto-journals` list) against the live
   repo/README before configuring — these change.
2. **CRediT statement**, if the user wants one. Use `scripts/credit.R`
   (walkthrough in [references/credit-helper.md](references/credit-helper.md)): create a fill-in CSV,
   the user fills it in directly (text editor or spreadsheet — never round-trip it through base R's
   `read.csv()` defaults, which mangle role names), then generate the markdown or LaTeX statement from the
   same CSV so it stays in sync. Mention the per-author vs. per-role convention choice and ask if the
   journal wants a lead/equal/supporting qualifier (added by hand; not automated).
3. **Lint before submission.** Run the checks in
   [references/linting-checklist.md](references/linting-checklist.md): spelling
   (`scripts/check_manuscript.R`'s `spell_check_manuscript()`, skips code chunks by design), bibliography
   duplicate-key and missing-DOI flags (`check_bib_duplicates()`, read-only), non-standard punctuation
   (`check_non_standard_chars()`), and grammar if LanguageTool is already set up or the user wants to set it
   up (`scripts/check_grammar.R`'s `check_grammar()` — installs a GitHub package and a ~240 MB external
   tool, so ask first even though general permission to install from GitHub was already given for this
   skill). Report findings as a list for the user to act on; fix nothing silently.
4. **Report** what was checked, what was skipped (e.g. link checking — still out of scope, see the linting
   reference), and which pages/templates were read live vs. taken from this skill's references.

## What this does not own

- Figure sizing, palettes and export for the final manuscript: `manuscript-figures-ggplot`.
- The data/code deposit, repository choice and data availability statement: `reproducible-research-data`.
- Git hygiene, tags, CITATION.cff: `git-for-research-projects`.
- Generic Quarto authoring syntax (cross-references, callouts, code-cell options) not specific to journal
  submission structure: a `quarto-authoring` skill if one is installed; check before claiming this
  territory.
- Automated link checking: still an open gap, noted in
  [references/linting-checklist.md](references/linting-checklist.md) rather than guessed at.

## Reference files

- [references/journal-templates.md](references/journal-templates.md): decision tree, `quarto-journals`
  template table, line-number and MECA notes.
- [references/credit-helper.md](references/credit-helper.md): CRediT taxonomy, per-author/per-role
  convention, the `CRediTas` round-trip gotcha, non-standard role lists.
- [references/linting-checklist.md](references/linting-checklist.md): spelling, grammar, bibliography,
  non-standard characters, a suggested pre-submission order, and what is not yet covered.
- `scripts/credit.R`, `scripts/check_manuscript.R`, `scripts/check_grammar.R`: the R functions referenced
  above.

## Tested and not tested

Tested on Windows 11 with R 4.6.0 (2026-10-26): `credit_template()`/`credit_table()`/`credit_statement()`
round-tripped a two-author example to markdown, LaTeX and per-role markdown output, and reproduced the
`read.csv()` default-settings name-mangling gotcha so the warning in `credit-helper.md` is confirmed, not
assumed. `spell_check_manuscript()` was run on a sample `.qmd` and confirmed to skip a typo placed inside a
code-chunk comment. `check_bib_duplicates()` was run on a two-entry `.bib` with a deliberate duplicate key
and a missing DOI. `check_non_standard_chars()` was run on a line with curly quotes and an em dash.
`check_grammar()` was installed (`remotes::install_github("nevrome/LanguageToolR")` plus
`lato_quick_setup()`, with the user's explicit permission) and run end to end on OpenJDK 26/27: it caught a
subject-verb agreement error, a duplicated word and a misspelling in test sentences, and on a `.qmd` file it
was confirmed to need both of the fixes documented in `linting-checklist.md` (the JDK entity-size JVM flag,
and stripping code chunks/YAML before checking — without the latter it flagged nonsense inside an R code
chunk). Not tested: a real multi-author CRediT statement with a lead/equal/supporting qualifier, any
`quarto-journals` template installed and rendered end to end (`quarto use template ...`), the MECA bundle
output, line-number injection rendered to an actual PDF, link checking, LanguageTool on a non-Windows OS or
with a non-default language variant, and the `contribution` CRAN package (graphical contributions figure)
mentioned as an alternative.

## Related skills

- `manuscript-figures-ggplot`: journal-ready figure sizing, palettes and export for the same manuscript.
- `reproducible-research-data`: the data/code deposit that accompanies the paper.
- `git-for-research-projects`: Git hygiene, tags and CITATION.cff for the manuscript repository.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. Say briefly why a decision was
made: why a journal got the generic manuscript project instead of a `quarto-journals` template (no template
exists yet, or one does and was chosen), why a check only flags instead of fixing, why the CRediT CSV should
be edited by hand rather than scripted, why grammar checking needs a separate ask even though the GitHub
install itself was already approved, and why link checking was left out rather than guessed at. Keep each
explanation to a sentence or two and point to the relevant reference file for depth.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects
it, a package version or API differs from what it states, or it lacks guidance the task needs, record a
generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it
when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are
hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
