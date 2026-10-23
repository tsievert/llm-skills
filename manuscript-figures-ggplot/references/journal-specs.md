# Journal figure specifications (starting point, verify live)

These numbers were gathered on 2026-10-23. Journals change them; many publisher pages block automated
fetching. **Always confirm against the target journal's current "instructions for authors" before building the
final figure**, and tell the user which values were read from an official page and which from a third party.

## Contents
- Table of verified values
- How each value was obtained
- Journals not verified
- How to look up a new journal
- Resolution, format and colour mode in plain terms

## Table of verified values

| Journal / publisher | Widths (mm) | Max height (mm) | Text | Raster resolution | Formats | Source type |
|---|---|---|---|---|---|---|
| Nature | 89 (1 col), 120-136 (1.5), 183 (2 col) | 170 (legend below); page depth 247 | Sans-serif, Arial/Helvetica preferred; 5 to 7 pt; panel labels 8 pt bold lowercase; do not outline text; embed fonts | Photos at least 300 dpi; line art stays vector | Vector (AI, EPS, PDF) for final artwork | Official: research-figure-guide.nature.com "Building and exporting figure panels", plus a third-party summary |
| Elsevier (general) | 90 (1 col), 140 (1.5), 190 (2 col); 30 minimum | Journal-specific | 7 pt normal, no smaller than 6 pt for sub/superscripts (rule of thumb) | 300 dpi halftone, 500 combination, 1000 line art | Journal-specific | Official: elsevier.com artwork sizing |
| Behavioral Ecology (OUP) | 85, 129 or 177 | 238 | Legible at those sizes | Colour figures at least 300 dpi at final size; submission page also says 1200 dpi line drawings, 300 dpi colour/halftone | TIFF for print; low-resolution copies allowed for review | Official: academic.oup.com/beheco "Instructions to authors", "submission online". Asks for colour palettes distinguishable with colour vision deficiency |
| Frontiers (Ecology and Evolution) | 85 (1 col), 180 (2 col) | One page | Smallest visible text at least 8 pt; lines at least 2 pt (this page is old; check) | Not stated numerically on the page read | TIFF, JPEG, EPS on acceptance; advises exporting as PDF then converting | Official guidelines page (about 4 years old) |
| Springer (one journal's standard guideline) | 84 (double-column text area), 174 (single-column text area) for large-format journals; 119 for small-format | 234 (large format) | Lines at least 0.1 mm (0.3 pt); no faint lines | Halftone 300 dpi, combination 600, line art 1200 (bitmap) | EPS vector, TIFF halftone | Official page of another Springer journal (journal id 265 in the URL; it was not checked which title that is); **the Oecologia page itself could not be fetched** |
| Science (AAAS) | 57, 121, 184 (1, 2, 3 columns) | Not stated in the summary | About 7 pt after reduction, not below 5 pt; Helvetica preferred | 300 dpi at initial submission | Journal-specific | Third-party summary only |
| Cell Press | 85, 114, 174 | One page | About 6 to 8 pt; Arial | 300 dpi colour, 500 B&W, 1000 line art | Journal-specific | Third-party summary only |
| Nature Communications | 88, 180 | Not stated | As Nature | As Nature | As Nature | Third-party summary only |

`scripts/figure_helpers.R` carries the width columns as `journal_specs` (same values; unknown cells are NA and
`journal_width()` refuses to guess).

## How each value was obtained

- Official page read in full by the assistant: Nature research-figure-guide (sizes, fonts), Elsevier artwork
  sizing, OUP Behavioral Ecology instructions and submission pages (search extracts), Frontiers author guidelines
  (search extract), a Springer journal's artwork section (search extract).
- Blocked or empty when fetched: nature.com final-submission page (client challenge), science.org (client challenge),
  Springer Oecologia (403), Behavioral Ecology general-instructions page (404). Values for Nature were
  cross-checked against the research-figure-guide page and two third-party summaries; Nature's own pages
  disagree slightly (88/180 on one page, 89/183 on another, 90/180 at initial submission).
- Third-party aggregator sites (conceptviz, scifig, sci-draw, labfig) were used only to cross-check, never as the
  sole source for a number, except Science/Cell/Nature Communications, which are flagged above.

## Journals not verified

Oecologia, Ecosphere, Integrative Zoology, Chemical Senses, Animal Behaviour, Proceedings B, Journal of Animal
Ecology, Ecology Letters: look them up live (see below). Several publishers also require figure files as TIFF or
EPS at acceptance even when review copies can be PDF.

## How to look up a new journal

1. Open the journal homepage, "For authors", then "Instructions", "Artwork" or "Figures". Prefer that page over
   a search snippet.
2. If the site blocks fetching, ask the user to paste the artwork section (it is short).
3. Record: column widths, maximum height, minimum and maximum text size, minimum line width, fonts, raster dpi by
   type, accepted formats, colour mode (RGB vs CMYK), file naming, whether figures go in the manuscript or as separate
   files, alt-text or accessibility requests, panel-label style.
4. Add the row to `journal_specs` in the helper (leave unknown cells NA).

## Resolution, format and colour mode in plain terms

- Pixels = dpi x width in inches. 89 mm at 600 dpi is 2102 px (verified: `save_figure()` wrote 2102 x 1417 for
  89 x 60 mm). "dpi" has no meaning for vector files.
- Vector (PDF, EPS, SVG) keeps text and lines sharp at any size; raster (PNG, TIFF) is fixed-resolution. Keep a
  vector master; rasterise only for a journal that demands TIFF. Do not upscale a low-dpi image; do not save
  line art as JPEG (Wilke ch. 27).
- RGB vs CMYK: most journals accept RGB and convert. Submit what the journal asks for.
- Fonts: embed them or use a face the journal lists. `cairo_pdf` embeds fonts (verified with `check_pdf()`);
  `svglite` references fonts without embedding them, so convert text to paths or embed in a vector editor only
  if the journal requires it.
- EPS: `cairo_ps` works for journals that still want EPS; not tested here. Wilke calls EPS outdated, but several
  publishers still list it.
