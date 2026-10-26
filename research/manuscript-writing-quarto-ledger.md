# Manuscript-writing-quarto research ledger

Research for the planned `manuscript-writing-quarto` skill (Quarto manuscripts; linting/proofreading only,
no autonomous prose, never auto-edit `.bib`; includes a CRediT author-contribution-statement helper).
Not yet built — this is the first research round. Read this before searching again.

## 1. Requirements / triggering decisions

| # | Date | Decision | Source |
|---|---|---|---|
| R1 | 2026-10-24 | Original scope set in `AGENTS.md` todo table: Quarto manuscripts, linting/proofreading only, no autonomous prose, never auto-edit `.bib` | user, recorded in `AGENTS.md` |
| R2 | 2026-10-26 | Added sub-scope: CRediT author-contribution-statement helper (14 standard roles, markdown/LaTeX table from an author x role matrix), modelled on author-contrib.com | user |
| R3 | 2026-10-24 (clash audit) | Must define its territory against `github-skill-maintenance/references/skill-boundaries.md` before being written; not yet in the ownership table | `skill-boundaries.md` open items |

## 2. Sources (status)

| Source | What it covers | Status |
|---|---|---|
| https://credit.niso.org/ | Official CRediT (ANSI/NISO Z39.104-2022) resource hub, 14-role list | search excerpt |
| https://casrai.org/credit and /credit/roles | Full 14-role list grouped into 4 functional categories, with per-role definitions | search excerpt |
| https://guides.library.iit.edu (IIT LibGuides) | Numbered 14-role list with definitions (used to cross-check casrai's list) | search excerpt |
| https://cran.r-project.org/package=CRediTas (rOpenSci, `CRediTas`) | R package: `template_create()`, `template_read()`, `cras_write()` (text/markdown CRediT statement output) | read (CRAN page) |
| https://github.com/ropensci/CRediTas | README with example workflow (table -> statement), `markdown = TRUE` option in `cras_write()` | read (README excerpt) |
| https://cran.r-project.org/package=contribution | Alternative CRAN pkg: ggplot2-based contribution *table* graphic, includes a `CRediT` dataset/function and GitHub-pull-based contribution estimation | search excerpt, not evaluated in depth |
| https://github.com/Pseudomanifold/latex-credits | Non-R LaTeX package (`\credit{}`, `\insertcreditsstatement`) for CRediT statements/figures directly in LaTeX output | search excerpt |
| https://quarto.org/docs/manuscripts/ | Official Quarto manuscript project docs: `project: type: manuscript`, multi-format output (HTML/PDF/DOCX/JATS), MECA bundle, notebooks | search excerpt |
| https://github.com/quarto-journals (org) | Curated journal templates: acm, acs, agu, biophysical-journal, elsevier, jasa, jss, plos; install via `quarto use template quarto-journals/<name>` | read (org README) |
| https://github.com/quarto-journals/article-format-template | Template-for-templates repo for building a new journal format extension | read |
| https://github.com/quarto-journals/elsevier | Elsevier format options in detail (model 1p/3p/5p, cite-style, graphical-abstract, highlights) | read |
| https://github.com/quarto-journals/jss | JSS format options (type: article/codesnippets/bookreview/softwarereview) | read |
| https://github.com/Morrison-Lab/qmt (and mirrors d-morrison.github.io/qmt, morrison-lab.github.io/qmt) | Independent (non-quarto-journals) manuscript starter template: HTML/PDF/DOCX/JATS, GitHub Actions for spell check, link check, R lint, BibTeX DOI validation, non-standard-char (curly quotes/em-dash) check | read |
| https://meridian.allenpress.com/jfwm (A Reproducible Manuscript Workflow With a Quarto Template, JFWM) | Peer-reviewed worked example of a Word-based journal workflow via Quarto; notes Pandoc docx limitations (cross-refs can break), editing the reference-doc template in Word, Trackdown for Google-Docs collaboration | search excerpt |
| https://biostats-r.github.io/biostats/quarto/07-journal-formatting.html | Practical walkthrough: `quarto use template`, line numbers via `\usepackage{lineno}` + `\linenumbers` in `header-includes` for PDF | read |
| CRAN `hunspell` / `spelling` (rOpenSci) | `hunspell()`/`hunspell_check()`/`hunspell_suggest()` spell-check engine; `spelling::spell_check_files()` parses markdown/latex/html and checks only text blocks, not code chunks — works directly on `.qmd`/`.Rmd` | read (CRAN vignette + package page) |
| https://github.com/nevrome/wellspell.addin | RStudio addin combining `hunspell` (spelling) + `LanguageToolR`/LanguageTool (grammar) as an interactive highlight-and-check workflow, not a batch script | read (README) |

## 3. Facts

- The CRediT taxonomy is fixed at 14 roles: Conceptualization, Data curation, Formal analysis, Funding
  acquisition, Investigation, Methodology, Project administration, Resources, Software, Supervision,
  Validation, Visualization, Writing – original draft, Writing – review & editing
  (<cite index="5-3">The 14 CRediT roles are Conceptualization, Data curation, Formal analysis, Funding acquisition, Investigation, Methodology, Project administration, Resources, Software, Supervision, Validation, Visualization, Writing — original draft, and Writing — review & editing.</cite>). It is now a
  formal standard: <cite index="3-3">CRediT (Contributor Roles Taxonomy) is the ANSI/NISO Z39.104-2022 standard for naming the 14 distinct roles researchers play in producing a published work.</cite>
- CRediT describes contributions, not authorship eligibility: <cite index="49-14,49-16">CRediT is not an authorship rule. ... Authorship is set by your journal's policy, usually the ICMJE criteria.</cite> Two output conventions are common —
  <cite index="49-28,49-29">Per-author output reads 'Jane Doe: Conceptualization, Methodology.' Per-role output reads 'Conceptualization: Jane Doe, John Smith.'</cite> — and some publishers (Wiley/Elsevier/T&F) accept a
  lead/equal/supporting degree-of-contribution qualifier while Nature/Cell usually do not.
- An existing, actively maintained **rOpenSci CRAN package already solves most of this**: `CRediTas`.
  <cite index="42-10">The CRediTas package aims to make this easier by providing a template to be filled in form of a table (csv) and then converting this table to CRediT statement format.</cite> Workflow is
  `template_create(authors = ...)` → fill a table (`fix()` or edit the CSV) → `template_read()` →
  `cras_write(cras_table, file, markdown = TRUE)` for a formatted statement text file. This means the
  skill's CRediT helper should **wrap `CRediTas`** (CRAN, 0 dependencies, rOpenSci-reviewed) rather than
  hand-roll role lists/formatting, and only add a LaTeX-output path (`CRediTas` only documents text/markdown
  output) and a Quarto-manuscript integration point (where the statement goes: an "Author contributions"
  section in `index.qmd`, sourced from the same CSV so it isn't retyped).
  Per the repo's working rule, `CRediTas` is a CRAN install and allowed without asking.
- `contribution` (CRAN) is a different, adjacent tool: a ggplot2-based contribution *table graphic* with a
  bundled `CRediT` dataset, apparently aimed more at visualizing/crediting code contributions (incl. pulling
  from GitHub) than at generating the standard text statement — worth a second look only if the user wants a
  graphical contributions figure, not the default text statement.
- Quarto has a first-class **manuscript project type** (`project: type: manuscript`, Quarto 1.4+) distinct
  from a plain document: <cite index="30-2,30-3">Quarto manuscript projects provide a framework for writing and publishing scholarly articles. A Quarto manuscript lets you: Produce manuscripts in multiple formats (including LaTeX or MS Word formats required by journals), and give readers easy access to all of the formats through a manuscript website.</cite> It can bundle a **MECA archive**:
  <cite index="30-10">a MECA archive, a zip file that is designed to capture your article and its supporting documents into a single file suitable for sending to a publisher.</cite>
- Separately, journal-specific **output formats** (not the same as the manuscript project type) come from
  the `quarto-journals` GitHub org: <cite index="10-3,10-4">The quarto-journals organization collects a curated set of journal templates for Quarto. Use a journal template with the command: quarto use template quarto-journals/<template-name></cite>, currently covering ACM, ACS, AGU, Biophysical
  Journal, Elsevier, JASA, JSS and PLOS. These two features compose: a manuscript project can declare
  `elsevier-pdf`/`jss-pdf`/etc. as one of its output formats.
  A community-maintained starter repo (`Morrison-Lab/qmt`) layers CI on top of this pattern, including
  automated spell check, link validation, R linting and BibTeX DOI validation — useful prior art for what
  "linting/proofreading only" could mean as reviewable checks before a human edits prose.
- Pandoc's docx output has real, documented limitations relevant to the "no autonomous prose" caveat and to
  reviewer workflows: for one Word-based journal template, <cite index="37-31">cross-references for figures and tables do not work with this template.</cite> and the authors
  <cite index="37-43,37-44">found this option to be reasonable... the Trackdown package allows people to share files using Google Drive and edit files using Google Docs</cite> for lightweight collaborator review — a possible reference for a
  "round-trip to a human-edited Word/Google Doc copy" workflow note.
- For PDF line numbers (useful for peer review), the practical recipe is a manual `header-includes` LaTeX
  injection: <cite index="39-15,39-16">If you are creating a PDF, you can include line numbers by adding a header-includes section to the YAML... \usepackage{lineno} \linenumbers</cite> — not a Quarto-native option.
- For the "linting/proofreading" sub-scope, R already has a mature spell-check stack that works on `.qmd`
  text (not code chunks) without external services: <cite index="21-14,21-15">This function parses a file based on the file extension, and checks only text fields while ignoring code chunks and meta data. It works particularly well for markdown, but also latex, html, xml, pdf, and plain text are supported.</cite> (`spelling::spell_check_files()`, which wraps `hunspell`). A
  per-project custom-word allowlist exists natively for packages (`inst/WORDLIST`) but `spell_check_files()`
  takes an `ignore` vector directly, which is the more relevant entry point for a non-package manuscript
  repo. Grammar checking (beyond spelling) would need LanguageTool, which has no first-class CRAN wrapper —
  `wellspell.addin` depends on a GitHub-only package (`LanguageToolR`) and a local LanguageTool install, so
  using it would need the "GitHub source — ask the user first" step in the working rules, and is an
  interactive RStudio addin rather than a scriptable check, which fits less well with a skill's workflow than
  `hunspell`/`spelling` do.

## 4. Candidate skill shape (not yet built, for discussion)

- **Journal templates & manuscript structure**: use Quarto's native `project: type: manuscript` plus
  `quarto-journals` extensions; a reference table of the 8 available journal templates and their format
  options (cite-style, model, graphical-abstract, etc. for Elsevier; type for JSS) so the assistant doesn't
  have to re-fetch each journal's README every time.
  - Open: `quarto-journals` only covers 8 journals; most target journals will need the generic manuscript
    project + the target's own Word/LaTeX template (as in the JFWM worked example), not a `quarto-journals`
    extension. The skill needs a decision tree: "is there a quarto-journals template?" -> use it; else ->
    generic manuscript project with a reference-doc docx template or a custom LaTeX template.
- **Linting/proofreading**: `spelling`/`hunspell` for spell-check as a batch, scriptable check (flags only,
  never auto-edits prose) plus the `Morrison-Lab/qmt` CI pattern (link check, BibTeX DOI check, non-standard
  character check for curly quotes/em-dashes) as inspiration for a pre-submission checklist script. No
  grammar-checking tool recommended yet (LanguageTool path is GitHub-only and interactive) — flag as open if
  the user wants grammar checking, not just spelling.
- **Bibliography**: `.bib` is user-owned and never auto-edited (R2); the skill can validate it (duplicate
  keys, missing DOIs — akin to the `qmt` template's `check-bibliography-dois` Action) without writing to it.
- **CRediT helper**: wrap `CRediTas` (`template_create()` -> user fills -> `cras_write()`); add a LaTeX
  output path on top (CRediTas only ships text/markdown) and wire the result into the manuscript's "Author
  contributions" section.
- Boundary against `skill-boundaries.md` table (not yet added there): would need to state what it does *not*
  own — figure export (`manuscript-figures-ggplot`), the data/code deposit (`reproducible-research-data`),
  Git/CITATION.cff (`git-for-research-projects`), and general Quarto technical authoring syntax if a
  `quarto-authoring`-equivalent skill is installed from elsewhere (not present in this repo; check the user's
  other installed skill directories before claiming generic Quarto syntax territory).

## 5. Open research items

- Whether to also recommend `contribution` (CRAN) for a graphical contributions figure, or leave that out of
  scope entirely — not yet evaluated beyond the CRAN description.
- No evaluation yet of `rticles`-equivalent R Markdown templates as a fallback for journals with neither a
  `quarto-journals` extension nor Quarto-native support — the user's stack is Quarto-first per repo
  conventions, so this is likely out of scope, but worth a one-line decision when the skill is written.
- Grammar-checking tool choice (LanguageTool via `LanguageToolR`, a non-CRAN GitHub package) is unresolved;
  needs explicit user permission per the working rules if pursued, or the skill could scope itself to
  spelling only and say so.
- No live fetch yet of `quarto.org/docs/journals/` itself (only search excerpts and the `quarto-journals` org
  README) — read it in full when the skill is actually drafted, per the "look up current references first"
  working rule.
- Did not check CRAN for a maintained R package wrapping `credit.niso.org`'s machine-readable URIs (ORCID or
  schema.org CRediT markup) — `CRediTas` is text/CSV only, no structured metadata output.

## 6. Log

- 2026-10-26: Round 1 (this file created). Four web searches (CRediT taxonomy, quarto-journals templates, R
  spelling/grammar tooling, Quarto manuscript project format) plus one follow-up search confirming a CRAN
  package (`CRediTas`) already exists for the CRediT statement sub-scope; read the `CRediTas` CRAN page and
  README, the `quarto-journals` org README and two of its member repos (elsevier, jss) in full, the
  `Morrison-Lab/qmt` README, and the `hunspell`/`spelling` CRAN pages. No local tests, no files written
  outside this ledger and the `AGENTS.md` todo-row edit from the same session. Skill itself not started.
