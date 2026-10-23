# ggplot2 hacks worth knowing (TidyTuesday, cheat sheets, styling guides)

## Contents
- Where these came from and how they were tested
- Workflow hacks
- Layout, labels and annotation
- Theme and defaults (ggplot2 4.x)
- Colour and scales
- Lessons from the cheat sheets (and one wrong claim)
- Creative tricks that suit talks and posters more than papers
- What did not work

## Where these came from and how they were tested

- **TidyTuesday code**: a shallow sparse clone of https://github.com/nrennie/tidytuesday (2025 and 2026 folders;
  93 weekly folders) was scanned for idioms. One prolific author, so it reflects one style, not "the community". Counts
  below are numbers of those scripts that use the idiom.
- **Social posts** (Bluesky, Mastodon) via `social-research-search`, 2026-10-23; anecdotal.
- **Guides**: tidyverse "ggplot2 styling" (Teun van den Brand, 2025-10-01), ggplot2 4.0.0 release post, the
  Posit ggplot2 cheat sheet (HTML, updated 2026-08, ggplot2 4.0.3), Nicola Rennie's workshop materials
  (https://nrennie.rbind.io/r-pharma-2026-ggplot2/, landing page only was readable).
- **Testing**: every hack marked "tested" ran in R 4.6.0 with ggplot2 4.0.3 and saved with ragg; this means it
  renders without error, not that every visual detail was inspected. "Not tested" means taken from a source only.

## Workflow hacks

| Hack | Why | Status |
|---|---|---|
| `ggview::canvas(89, 60, units = "mm")` added to a plot | Preview at exactly the size and resolution you will save, so text size is judged as printed (used in 33 TidyTuesday scripts; recommended in a Fosstodon post) | Tested: renders; viewer integration not judged |
| `camcorder::gg_record(width =, height =, units =)` + `gg_playback()` | Records every plot at a fixed size; used in 50 scripts | **Not working here**: camcorder 0.1.0 with ggplot2 4.0.3 wrote 0 files and warned "S3 method print.ggplot was declared but not found" in a non-interactive run. Use `ggview` or `ggsave` + open the file |
| Save, open the file, look at it | The RStudio viewer rescales; absolute sizes are not honoured by all tools (community post) | Principle, tested throughout |
| `set_theme(theme_ms())` at the top of a script | One global look; undo with `reset_theme_settings()` | Not tested; from the styling article |
| `last_plot() + aes(...)`, `base %+% newdata` | Quick variants without retyping | Not tested; from ggplot2 docs |
| Quarto chunk options `fig-width`, `fig-height` in inches (final size / 25.4) and `fig-dpi` | Keep rendered size equal to journal size | Not tested here (base-R cheat sheet "How big is your graph?" only covers `par()`/device sizes) |
| `coord_cartesian(xlim =, ylim =)` to zoom | Zooms without dropping data; setting limits in scales drops points outside, which changes smooths and boxplots (ggplot2 docs discourage scale limits for this) | Tested: renders |

## Layout, labels and annotation

| Hack | Notes | Status |
|---|---|---|
| `coord_cartesian(clip = "off")` + `theme(plot.margin = margin(..., r = 40))` | Put direct labels or annotations outside the panel; used in 40 scripts | Tested |
| `ggtext::element_textbox_simple()` for title, subtitle, caption, tag | Wraps long text at the plot width and allows markdown/italics (species names); used in 83 scripts | Tested (title) |
| `ggtext::element_markdown()` for axis titles like `*Myodes glareolus*` | Italic binomials without `expression()` | Tested earlier |
| `ggh4x::facet_manual(vars(g), design = "AB\nC#")` | Irregular facet layouts (used in 4 scripts); `axes = "x"` repeats axes | Tested |
| `ggh4x::facet_grid2(scales = "free_x", independent = "x")` | Independent axes per panel | Smoke-tested earlier |
| `geomtextpath::geom_textline(aes(label = g))` | Direct labels that follow lines; removes the legend lookup | Tested: renders |
| `scale_x_continuous(guide = guide_axis(check.overlap = TRUE))` or `guide_axis(n.dodge = 2)` | Avoid overlapping tick labels (on the cheat sheet and in posts) | Tested |
| `str_wrap()`, `lineheight`, `glue()` in labels | Multi-line labels with controlled spacing (used in about 60 scripts) | Not tested; standard |
| `labs(alt = "...")` and `ggplot2::get_alt_text()` | Alt text for accessibility; Springer Nature recommends alt text | Tested |
| `labs(dictionary = c(var = "Label (unit)"))` | One dictionary for all axis/legend titles | Tested |
| `guides(colour = guide_colourbar(position = "bottom", theme = theme_sub_legend(key.width = unit(1, "null"), title.position = "top")))` | Colourbar stretched across the panel width, from the styling article | Tested: renders |
| Per-category transparency: `aes(alpha = grp)` + `scale_alpha_manual(values = c(...))` | Highlight one group, fade the rest (post) | Tested |
| `scale_colour_identity()`, `scale_alpha_identity()` | Use colours stored in the data (highlight columns) rather than a legend; used in 15 scripts. No legend, so say in the caption what the colours mean | Tested |
| Small multiples with the other groups in grey (`layout = "fixed"` layer or a second layer with unfaceted data) | Untangles spaghetti charts (post) | `layout =` argument: not tested |

## Theme and defaults (ggplot2 4.x)

- `theme(geom = element_geom(linewidth =, pointsize =, ink =, paper =, accent =))` sets all layer defaults at
  once; `theme(geom.point = element_geom(colour = "grey30"))` targets one geom; `update_theme()` makes it global.
  The styling article says `update_geom_defaults()` is now discouraged. Tested; `theme_ms()` uses it so that
  default lines print at 0.5 pt (see below).
- `theme_sub_axis()`, `theme_sub_legend()`, `theme_sub_panel()`, `theme_sub_plot()`, `theme_sub_strip()` group
  settings by prefix (tested). `margin_auto()` and `margin_part()` for margins.
- `theme_*(header_family = "...", base_family = "...")` pairs a heading font with a body font. Call
  `systemfonts::require_font()` inside theme functions that name special fonts.
- `guide_axis(theme = theme_classic(ink = "red"))` styles a single axis; `from_theme(accent)` reads theme values inside
  `aes()`; `element_rect(fill = <grid pattern>)` allows image backgrounds. Not tested (article only).
- `theme(aspect.ratio = )` for fixed panel shape; `panel.widths`/`panel.heights` for absolute panel size
  (tested; remember `ggsave()` size includes axes and legends).
- **Stroke caveat:** `element_geom(linewidth)` does not change point outlines (`stroke`, default 0.5, about 1.07 pt in
  the PDF). `check_pdf()` therefore still reports 1.07 pt when points are drawn; set `stroke = 0.25` on `geom_point()` if a
  journal limits line weights, or accept it for symbols.

## Colour and scales

- **Prefer colour-vision-deficiency (CVD) friendly palettes: viridis and relatives first** (see
  [colour.md](colour.md)). In ggplot2 >= 4.0 a theme can carry the palette: `theme(palette.colour.continuous = "viridis")`,
  `theme(palette.colour.discrete = "viridis")` and also `"cividis"`; the colours were checked against
  `viridisLite::viridis()` and cividis ends (#00204D to #FFEA46). Fill variants work the same
  (`palette.fill.*`). `theme_ms()` sets these by default.
- `scale_colour_viridis_d(begin = 0.15, end = 0.85)` trims the extremes (the yellow end is hard to see on white);
  `scale_*_viridis_b()` for binned; `option = "E"` is cividis. All tested.
- Many TidyTuesday scripts use `rcartocolor` and `PrettyCols` palettes (11 files each); these are designed for appeal,
  not all are CVD-safe, so run `cvd_preview()` before using one in a paper.
- Highlight with colour, not rainbow: grey for context, one saturated colour for the focus group (with
  `scale_colour_identity()` or `scale_colour_manual()`).

## Lessons from the cheat sheets (and one wrong claim)

- **Posit ggplot2 cheat sheet (updated 2026-08, ggplot2 4.0.3)** is the authoritative one and now includes the new
  items: `labs(dictionary =)`, `labs(alt =)`, `coord_*(reverse =)`, `theme(geom = element_geom())`,
  `from_theme()`, `theme_sub_*()`, `plot.title.position = "plot"`, `guide_axis(n.dodge =)`. Items not on it:
  `stat_manual`, `stat_connect`, facet `dir =` and `layer(layout =)`, which are in the 4.0.0 release post.
- Posit's own cheat sheet page is being migrated; the accessible HTML copy is at
  https://rstudio.github.io/cheatsheets/html/data-visualization.html. Contributed sheets relevant to figures:
  gganimate, bayesplot, survminer, vegan, "How big is your graph?" (base R device sizes only; not useful for ggplot2).
- **A third-party "ggplot2 cheat sheet" (r-statistics.co, April 2026) claims that `scale_x_log10()` on a histogram
  changes only the labels, not the bins. That is wrong:** in a test, 10 bins with `scale_x_log10()` had equal width in
  log space (stats are computed after the scale transform), so the bins are log-spaced. Check claims in unofficial
  sheets against `?` pages or a quick `layer_data()` call before repeating them.
- Same sheet, correct tip worth keeping: `scales::label_comma()`/`label_percent()` for axis labels; the sheet's
  `labels = scales::comma` form is older style.

## Creative tricks that suit talks and posters more than papers

Used a lot in TidyTuesday and mostly irrelevant for journals: `showtext` plus Google fonts (83 scripts; fonts
are rasterised or not embedded, avoid for journal files), emoji fonts, custom background colours, jam-jar or avocado
pictograms, `ggpattern` fills, `ggfx` glows, `imager`/`ggimage` pictures, `ggiraph` interactivity, gif creation with
`magick`. Fine for a presentation; for a manuscript stick to the journal's allowed fonts and plain fills.

## What did not work

- `camcorder::gg_record()` (see table above).
- The Nicola Rennie workshop page lists the tricks only as slides/examples links; only the landing page text was
  readable, so the individual slides were not reviewed.
- Posit's cheatsheets landing page returned only a migration notice and a list of titles, not content.
