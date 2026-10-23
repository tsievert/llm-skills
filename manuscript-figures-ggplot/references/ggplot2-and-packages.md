# ggplot2 4.x features and package notes

## Contents
- ggplot2 4.0 changes that matter for figures
- Sizing and units cheat sheet
- Text, fonts and devices
- Packages: what each is for and how far it was tested
- Alternatives considered

Checked 2026-10-23: ggplot2 4.0.3 (CRAN current), patchwork 1.3.2, ragg 1.5.2, R 4.6.0 on Windows.
The ggplot2 4.0.0 release post is at https://tidyverse.org/blog/2025/09/ggplot2-4-0-0/ ; before suggesting an
argument from memory, run `?ggplot2::theme` or read https://ggplot2.tidyverse.org/news/index.html.

## ggplot2 4.0 changes that matter for figures

- **Theme-level layer defaults:** complete themes accept `ink`, `paper`, `accent` (for example
  `theme_gray(paper = "cornsilk")`); `theme(geom = element_geom(...))` sets default point shape, line widths, etc.
  Useful for a lab-wide look in one place.
- **Theme-level palettes:** `theme(palette.colour.discrete = ..., palette.colour.continuous = ..., palette.shape.discrete = ...)`.
  Tested with Okabe-Ito colours (renders). Scales still take explicit `values` for control.
- **Absolute panel size:** `theme(panel.widths = unit(40, "mm"), panel.heights = unit(30, "mm"))`, also via
  `theme_sub_panel(widths =, heights =)`. Tested: with `ggsave(width = 89, height = 60, units = "mm", dpi = 300)`
  the canvas stayed 89 x 60 mm and the panel was set to 40 x 30 mm. Remember `ggsave()` size is for the whole
  plot (labels included); with `panel.*` the legend and axes add to it.
- **Labels:** `labs(dictionary = c(var = "Label (unit)"))` or `attr(x, "label")` give consistent axis titles from
  a data dictionary; pairs with the `data-repository-readme` data dictionary. Labels stop applying when the aesthetic
  is an expression (for example `log(x)`).
- **Boxplot parts:** `median.linewidth`, `whisker.linetype`, `staplewidth`, `box.colour` etc. Violin quantiles are now
  computed from the data, drawn with `quantile.linetype` (default off).
- **facet_wrap(dir = "br")** and 8 direction options; `facet_wrap(space = "free_x")` when one row.
- **S7 internals:** extensions that touch plot internals may need updates; plain plotting code does not.
- **Theme shortcuts:** `theme_sub_axis_x()`, `theme_sub_legend()`, `theme_sub_panel()`, `margin_auto()`, `rel()` for spacing.

## Sizing and units cheat sheet

| Quantity | ggplot2 unit | Convert |
|---|---|---|
| Theme text (`base_size`, `element_text(size=)`) | pt | Final printed size when saved at final width |
| `geom_text(size=)`, `annotate("text", size=)` | mm by default | Use `size.unit = "pt"` to use pt (tested); otherwise pt = mm x 2.845 |
| `linewidth=` | mm | PDF stroke in pt = linewidth x 2.134 (read from the PDF stream: 0.3 gave 0.64 pt). `pt_to_lw()` and `lw_to_pt()` in the helper |
| `size=` for points | mm-ish | Check visually; set per geom |
| `ggsave(units = "mm")` | mm | 89 mm = 3.504 in |

Theme defaults at `base_size = 7`: axis text 5.6 pt (0.8 x base), titles 7 pt, theme line = base_size/22 mm
(0.68 pt). Nature's 5 to 7 pt text and 0.25 to 1 pt strokes are met by default except where you add geoms with
default `linewidth = 0.5` (1.07 pt) or points with strokes; run `check_pdf()` to see actual values.

## Text, fonts and devices

- Build at the final size and set text there: `theme_ms(base_size = 7)`, `ggsave(width = 89, units = "mm")`.
  Scaling a finished figure in Word or Inkscape changes the printed font size and line widths.
- `ggsave(..., device = cairo_pdf)` embeds fonts (verified: ArialMT and Arial-BoldMT with FontFile2 entries). The
  default `pdf()` device can fall back to Helvetica without embedding.
- `ragg::agg_png`/`agg_tiff` for raster: consistent anti-aliasing and system fonts across OSes. `agg_tiff` accepts
  `compression = "lzw"` (tested; wrote 600 dpi LZW TIFF, 2102 x 1417 px for 89 x 60 mm, read back with `tiff`).
- `svglite` for SVG (tested). Text remains text and fonts are not embedded.
- Fonts: Arial exists on this Windows machine (systemfonts finds `C:/WINDOWS/Fonts/arial.ttf`, also for "Helvetica").
  On Linux or a cluster Arial is usually absent: use "Liberation Sans" or "Arimo" (metric-compatible) via
  `systemfonts::match_fonts()` to check what resolves. Not tested on Linux or macOS.
- Greek letters/special symbols: use `expression()`/plotmath or `ggtext::element_markdown()` (tested) with real
  Unicode, and check the PDF.
- Always `bg = "white"` when saving PNG; transparent PNGs look dark in some viewers (community tip).

## Packages

Status key: **T** = used in a script here and the output inspected; **S** = smoke-tested (renders without error,
not visually reviewed); **N** = listed from CRAN/community sources, not run.

| Package | Use | Status |
|---|---|---|
| ggplot2 4.0.3 | everything | T |
| patchwork 1.3.2 | panels, `plot_annotation(tag_levels)`, `plot_layout(widths)` | T |
| ragg 1.5.2, svglite 2.2.2 | raster/SVG devices | T |
| colorspace 2.1-4 | CVD simulation, HCL palettes | T (simulation) |
| ggbeeswarm 0.7.3 | raw points without overplotting | T |
| ggdist 3.3.3 | half-eyes, intervals, quantile dotplots | S |
| scico 1.5.0 | scientific colour maps | S |
| ggrastr 1.0.2 | rasterise dense layers, keep vector axes | S |
| ggh4x 0.3.1 | `facet_grid2(independent=)`, nested facets | S |
| ggtext 0.2.0 | markdown/italic species names in labels | S |
| ggrepel 0.9.8 | direct labels | N (installed, not run here) |
| cowplot 1.2.0 | `plot_grid()`, `get_legend()`; alternative to patchwork | N |
| marginaleffects 1.0.0, emmeans | model-based predictions/estimates to plot | N for figures |
| ggview 0.2.2 | `canvas()` preview at the saved size (community tip, TidyTuesday) | S |
| geomtextpath | direct labels along lines (`geom_textline`) | S |
| tidyplots 0.4.0 | opinionated wrapper; its author states it bundles ggplot2, patchwork, ggbeeswarm, ggpubr, ggrastr, ggrepel | N |
| ggalign 1.2.0 | heatmaps aligned with annotations ("patchwork on steroids" per a community post) | N |
| gghalves, ggrain | half-violin + points ("raincloud") | N (`gghalves` not on CRAN when checked; `ggrain` 0.1.2 is) |
| ggprism, ggpubr, ggsignif | publication-style themes and significance brackets | N |
| camcorder 0.1.0 | record plots at fixed size while iterating | Tried: recorded 0 files with ggplot2 4.0.3 (warning about print.ggplot) |
| ggpattern 1.3.1 | pattern fills for shape-redundant encoding | N |
| lemon 0.5.2 | symmetric scales, axis helpers | N |
| ggstatsplot 1.1.4 | plots with embedded test statistics | N; hides modelling choices, avoid for inference figures |

## Alternatives considered

- **Hand-written export helper vs a package:** CRAN has no single package that checks journal size, fonts and CVD
  together; `ggview`/`camcorder` cover the preview step, `ggsave` plus `ragg` cover export. The helper stays small
  and relies on those.
- **`cowplot` vs `patchwork`:** patchwork was used because its tagging and `&` theme operator are enough for
  the common case; `cowplot::plot_grid(align = "hv", axis = "tblr")` is a reasonable alternative.
- **`tidyplots` and `esquisse`:** quick or GUI-driven; useful for exploration but less transparent for
  fine control, so not made the default here.
- **Inkscape/Illustrator post-editing:** acceptable for annotations, but any manual edit breaks reproducibility;
  keep a note of what was changed by hand.
