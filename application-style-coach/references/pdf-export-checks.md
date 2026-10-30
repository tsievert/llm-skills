# PDF export checks

The export target for the CV, cover letter, research statement or plan, teaching portfolio and publication list is PDF.
The assistant does not produce or edit the PDF; it can run read-only checks on the final file and name what to look at
by eye.

## Contents

- Why the PDF is what counts
- Checks
- Running the script
- Call-specific facts seen
- What the checks do not cover

## Why the PDF is what counts

Page limits, margins and fonts are judged on the submitted PDF, not on the word-processor file. Font substitution,
different line breaks and moved tables can add a page. Some funder systems reject a file whose page count or structure
is wrong. So measure in the PDF, after the last edit.

## Checks

| Check | Why | Who checks |
|---|---|---|
| Page count against the call (and against the whole-package limit when one PDF is required) | Overlong documents may be cut off or rejected | script |
| Paper size A4 (Finland) | Funder templates are A4 | script |
| All fonts embedded; the font the template or call names | Text can reflow or look wrong on the reviewer's computer; some templates fix the font (the fonts named in Academy templates changed between years) | script, then by eye |
| Text is selectable (no scan or page image) | Systems and reviewers search and copy text; accessibility | script |
| No password or encryption | Systems must be able to process the file | script |
| File size under the call's limit | Some universities set per-file limits | script |
| Metadata (title, author, creator) holds no old file name or someone else's name | CVs and lists can be public documents | script prints it; the user edits |
| File name exactly as the call says (for example `cv_<year>_<surname>.pdf`) | Naming rules are often strict | the user |
| Name and page numbers on each page when documents are merged into one PDF | Reviewers read a merged package | by eye |
| Links work (ORCID, DOI, open-access links) and are not cut by line breaks | Links in a CV are checked by readers | by eye |
| No tracked changes, comments or hidden text left in the source before export | They can travel into the PDF or its metadata | by eye in the source file |
| Export method: use the application's Save/Export as PDF (or Quarto/LaTeX output), not a virtual printer, unless the call says otherwise | The Research Council of Finland says "do not print to PDF" for one of its appendices because it makes processing harder; follow the call | the user |

## Running the script

```r
source("<skill-dir>/scripts/pdf_checks.R")   # needs pdftools
pdf_checks("<final.pdf>", max_pages = 2, max_mb = 5)   # limits from the call; expect_size = "A4"
```

The result is a table with `ok`, `check` and `info`. A `check` is a prompt to look, not a verdict. To scan the PDF
text for style flags run `style_flags("<final.pdf>")` from `style_flags.R` (it reads PDFs through `pdftools`).

## Call-specific facts seen (examples, October 2026)

- Research Council of Finland: PDF appendices on templates in Word or LaTeX; named files; CV and plan page limits fixed;
  the system can refuse a submission with page or structure errors; research security appendix must be saved as PDF and
  not printed to PDF.
- University of Helsinki HiLIFE ad: everything in one PDF, whole package at most 10 pages.
- University of Turku: size limits per document (5 MB; 25 MB for the portfolio).
- Aalto: single PDF or separate PDFs with a named file pattern.

Always read the call; these are examples.

## What the checks do not cover

Visual layout, heading wording against a template, readability, whether links point to the right place, PDF/A or
accessibility tagging (no source found that Finnish calls require it, so do not claim it is required), and any rules
that appear only in the Finnish text of the call (see [local-language-sources.md](local-language-sources.md)).
