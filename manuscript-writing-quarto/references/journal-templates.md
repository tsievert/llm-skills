# Journal structure: decision tree and reference table

Read 2026-10-26 (see `research/manuscript-writing-quarto-ledger.md` in the skills repo for sources and
dates). Confirm against the live pages before relying on a detail here for a submission — formats and the
template list change.

## Decision tree

1. **Does `quarto-journals` (https://github.com/quarto-journals) have the target journal?** Currently ACM,
   ACS, AGU, Biophysical Journal, Elsevier, JASA, JSS, PLOS. If yes: `quarto use template
   quarto-journals/<name>` and declare that format (e.g. `elsevier-pdf`, `jss-pdf`) inside a manuscript
   project (step 2).
2. **Always use Quarto's native manuscript project type** (`project: type: manuscript`, Quarto 1.4+) as the
   outer structure, regardless of step 1. It produces multiple output formats from one source and a
   manuscript website, and can bundle a MECA archive (a zip for sending to a publisher) on request.
3. **No `quarto-journals` template for this journal?** Most journals fall here. Use the generic manuscript
   project plus the journal's own template:
   - Word-based journals: a reference-doc `.docx` template, edited in Word to carry the journal's styles
     (headings, captions). Expect limitations — cross-references for figures/tables can fail to resolve
     through Pandoc's docx output for some templates; check this early, not at submission.
   - LaTeX-based journals with no quarto-journals entry: a custom LaTeX template via `quarto-journals`'
     `article-format-template` as a starting skeleton, or a plain `format: pdf` with `template:` pointing at
     the journal's `.tex` class file.
   - Neither: generic manuscript project, default formats, reformat at acceptance.
4. **Peer review needs line numbers (PDF only):** no Quarto-native option exists; inject LaTeX directly:
   ```yaml
   format:
     pdf:
       header-includes:
         - \usepackage{lineno}
         - \linenumbers
   ```
5. **Collaborator review on Word/Google Docs:** Pandoc docx output can round-trip to Google Docs via the
   Trackdown package for lightweight non-technical co-author review, then back to the `.qmd` source — useful
   when a co-author cannot or will not work in `.qmd` directly.

## quarto-journals format options (examples seen 2026-10-26)

| Template | Notable options |
|---|---|
| `elsevier` | `model` (1p/3p/5p), `cite-style`, `graphical-abstract`, `highlights` |
| `jss` | `type` (article/codesnippets/bookreview/softwarereview) |

Each template's own README documents its full option set; read it live when configuring, rather than from
this table.

## What this does not cover

- Generic Quarto authoring syntax (code-cell options, cross-references, callouts) belongs to a
  `quarto-authoring` skill if one is installed; this file is journal-structure-specific.
- Figure sizing/export for the final manuscript: `manuscript-figures-ggplot`.
