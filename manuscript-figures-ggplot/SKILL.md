---
name: manuscript-figures-ggplot
description: 'Builds journal-ready figures in R with ggplot2 and patchwork: raw data first, honest uncertainty, colour-blind-safe palettes (viridis and relatives preferred), panels built at the journal column width, text and line sizes in points, vector PDF or TIFF/PNG export, and checks for embedded fonts, text size and colour-vision deficiency. Use when the user asks for a publication, manuscript, thesis or journal figure, figure size, DPI, fonts, panel labels (a, b, c), multi-panel layout, colour-blind-safe colours, "bad plot" advice, bar versus dot or box plots, or revising figures after review. Not for exploratory plots or Shiny; for plotting GAM smooths start with gam-interpretation.'
---

# Manuscript figures with ggplot2

For final figures that go into a paper, thesis or reviewer response. For quick exploration just plot; do not apply
this whole workflow to it.

## Where this skill runs

Everything is local R code. The assistant runs on the user's computer and produces files there. If a figure is
rendered on a cluster, fonts differ (Arial is usually missing); see the font notes in
[references/ggplot2-and-packages.md](references/ggplot2-and-packages.md) and ask the user to paste the output of
`systemfonts::match_fonts("Arial")` rather than guessing.

## Workflow

1. **Currency check (short).** Run `packageVersion("ggplot2")`; ggplot2 4.x has theme-level palettes, absolute
   panel sizes and changed boxplot/violin arguments (see the reference). Journal numbers change: never trust the
   table in this skill without checking the target journal's current page (step 2).
2. **Establish the brief.** Ask only what is missing: target journal and width (1, 1.5 or 2 columns), colour or
   black-and-white print, the message of the figure, the unit of replication (animals, trials, sites), n, and which
   model or test the figure must agree with. Look up the journal live; if the site blocks fetching ask the user to
   paste its artwork section. Procedure and the checked values: [references/journal-specs.md](references/journal-specs.md).
3. **Choose the display.** Raw data visible at small n, summary or model estimate on top, uncertainty defined, one
   panel per question. Chart-type decisions, the unit-of-replication rules and the contested points:
   [references/principles-and-pitfalls.md](references/principles-and-pitfalls.md).
4. **Build at final size.** Source the helpers and use them:
   ```r
   source("<skill-dir>/scripts/figure_helpers.R")   # theme_ms(), okabe_ito, journal_width(), save_figure(), check_pdf(), cvd_preview()
   p <- ggplot(...) + ... + theme_ms(base_family = "Arial")
   fig <- (pa | pb) + panel_tags()                  # patchwork, lowercase tags
   ```
   Full worked example on simulated behavioural data: [assets/example_figure.R](assets/example_figure.R).
   Colour rules and palettes: [references/colour.md](references/colour.md). Layout and styling tricks:
   [references/ggplot2-hacks.md](references/ggplot2-hacks.md).
5. **Export and check.**
   ```r
   save_figure(fig, "fig1", width_mm = journal_width("nature", "two"), height_mm = 70,
               formats = c("pdf", "tiff"), dpi = 600)
   check_pdf("figures/fig1.pdf", font_range = c(5, 7), stroke_range = c(0.25, 1))   # needs qpdf
   cvd_preview(fig, "figures/fig1_cvd.png", width_mm = 183, height_mm = 70)
   ```
   Open the exported file (not the RStudio viewer) and read it at the printed size. `check_pdf()` flags text or
   strokes outside the limits you pass in; some flags are legitimate (for example Nature allows 8 pt panel labels).
6. **Report.** Say what was checked (size, fonts embedded, text and stroke ranges, CVD preview, raw data shown,
   n and interval definition in the legend) and what was not (journal page unread, no print proof, fonts not tested
   on the journal's system). Draft the legend text: what is plotted, n, interval definition, test or model.
7. **Revision rounds.** Keep the figure code in the repository so a reviewer's change is an edit and a re-run; log
   hand edits made outside R.

## Key rules (details in the references)

- Show the data; bars only for counts or proportions with a zero baseline. Summaries and intervals from the model
  that carries the inference, at the unit of replication.
- **Prefer colour-blind-friendly palettes, viridis and relatives first** (viridis/cividis, scico, colorspace; Okabe-Ito for
  a few categories). `theme_ms()` sets viridis as the default for colour and fill. Other palettes only after
  `cvd_preview()`. Colour only when it encodes something; always a second encoding; never rainbow or red-green.
- Theme text is in points: build at the final width so `base_size = 7` really prints at 7 pt. `geom_text()` uses
  mm unless `size.unit = "pt"`. `linewidth` is in mm (1 mm is about 2.13 pt).
- Same colour, symbol and order for the same thing in every figure. Same axis ranges for panels that are compared.
- Save a vector master (PDF via `cairo_pdf`); raster only at the dpi the journal states.
- Handy tricks (direct labels, textbox titles, `clip = "off"`, `facet_manual`, `element_geom` defaults, `ggview::canvas`, alt
  text) with test status: [references/ggplot2-hacks.md](references/ggplot2-hacks.md). Unofficial cheat sheets can be wrong;
  check against the Posit sheet or `layer_data()`.
- Opinionated sources (for example the "Friends Don't Let Friends Make Bad Graphs" repo) are heuristics. Apply
  them with the stated reasoning and flag where the user's field or journal differs.

## Related skills

- `mixed-models-glmm`: model-based means and contrasts to plot; `gam-interpretation`: plotting GAM smooths and
  uncertainty; `animal-behaviour-tracking-analysis`: behavioural summaries to plot;
  `data-repository-readme`: data dictionary whose labels can feed `labs(dictionary = )`;
  `social-research-search`: finding what plotting problems people report (see
  [references/community-notes.md](references/community-notes.md) for what it found on 2026-10-23);
  `manuscript-writing-quarto`: structures the Quarto manuscript these figures go into.

## Tested and not tested

Tested on Windows, R 4.6.0, ggplot2 4.0.3, patchwork 1.3.2, ragg 1.5.2: `theme_ms()` at 7 pt with viridis theme palettes and `element_geom` line defaults, `save_figure()` to
PDF/PNG/TIFF/SVG (TIFF 600 dpi LZW read back; 89 mm gave 2102 px), `check_pdf()` against the real PDF content
stream (fonts embedded; text sizes 5.6, 7, 8 pt; stroke widths), `cvd_preview()` on a bad and a good palette,
the example figure, ggplot2 4.0 theme palettes and `panel.widths`. Smoke-tested only: ggdist, scico, ggrastr, ggh4x,
ggtext, geomtextpath, ggview. `camcorder` 0.1.0 did not record under ggplot2 4.0.3. Not tested: Linux or macOS, fonts on a cluster, EPS output, any journal's upload system, Quarto/Shiny
embedding, `check_pdf()` on PDFs from other devices (it parses cairo output), real study data.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were done or not done: why this chart type or palette was chosen, which alternative was rejected and why, which check or step was skipped, and which assumptions were made. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a package version or API differs from what it states, or it lacks guidance the task needs, record a generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
