# Checking cited papers against the text (`.bib` and open full text)

Purpose: let the user check whether what the manuscript says about a cited paper matches that paper. The `.bib` is
read only. Findings are questions, never verdicts, and never edits. Sources and the parser test: ledger sections 8.4
and 12.

## Contents

- Steps
- Reading the `.bib`
- Availability table
- Terms for reading full text
- Comparing text and claim
- Delegation

## Steps

1. Ask which `.bib` (absolute path) and which manuscript sentences or sections the user wants checked.
2. Read the entries (below) and build an availability table.
3. For entries with open full text, read the relevant passage and compare it with the user's sentence.
4. Report mismatches as questions: "your sentence says [x]; the paper reports [y] in [section]. Is that the same
   quantity?" The assistant can misjudge nuance, so say so.

## Reading the `.bib`

- Parse with `bibtex::read.bib()` (light, handles quoted and unbraced values). It silently drops entries that fail
  validation and returns raw DOI strings, so also scan the raw file for keys and duplicates with
  `check_bib_duplicates()` from `manuscript-writing-quarto/scripts/check_manuscript.R` (read-only) and report dropped or
  duplicate entries instead of losing them.
- Normalise DOIs before any lookup: strip `https://doi.org/`, lowercase.
- Entries without a DOI need a title-based lookup, which belongs to the `openalex` skill.
- Do not use `bib2df` for this (an unbraced year plus a quoted DOI came back empty in testing). Not yet tested on Zotero
  or Better BibTeX output, `@string` or `@comment`.
- Never add, fix or reorder entries.

## Availability table

One row per entry: key, normalised DOI, open-access status (gold, hybrid, bronze, green, closed), licence, version
(published, accepted, submitted), where. Use the full-text script in the `openalex` skill (OpenAlex locations, then
Unpaywall, then Europe PMC XML for PMC records) rather than writing a new fetcher. Its use needs the user's own email
for Unpaywall; never invent one, and ask before any metered call.

## Terms for reading full text

Practical rules, not legal advice:

- Open access is not one permission. Gold or hybrid with a Creative Commons licence allows reading; reuse terms depend on
  the specific licence (for example NonCommercial or NoDerivatives variants). `bronze` (free to read, no explicit licence) and a missing licence mean reuse rights are unclear.
  Green copies may be accepted or submitted versions that differ from the published text.
- Reading a paper to check the user's own sentences against it is the normal use. Storing, redistributing or bulk
  mining is different and depends on the licence and the site's terms.
- So: read only papers with an open licence or that the user opens or pastes. For bronze, no-licence or
  accepted-manuscript copies, report "free to read, licence unclear / version differs" and let the user decide.
- Keep downloaded text inside the user's git-ignored project folder, never in a shared deposit, and delete it after
  the check. Closed papers are reported as unavailable; nothing else is attempted.

## Comparing text and claim

Compare the user's sentence with the paper's abstract and the relevant section. Typical mismatches: a number or unit
that differs, an effect described as causal where the paper reports an association, a result from a different species
or setting, a conclusion from the paper's Discussion presented as its result. The version matters (a preprint may differ
from the published paper), so state which version was read.

## Delegation

With more than about ten entries, give the lookup to a low-effort subagent: input the normalised DOIs and the
project output folder, ask for the availability table only. Do the comparison of text and claim in the main
conversation, because it needs the user's sentences and judgment.
