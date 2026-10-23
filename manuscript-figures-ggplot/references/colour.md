# Colour for manuscript figures

## Contents
- Default preference
- Rules that hold across sources
- Categorical palettes
- Continuous palettes
- Diverging data
- Checking a figure for colour-vision deficiency
- Grayscale and print

## Default preference (user standing preference)

Prefer colour-vision-deficiency (CVD) friendly palettes, with the **viridis family and related perceptually uniform
scales first**: `viridis` (options A to H; "E" is cividis, the most CVD-robust), `scico` (batlow, vik, ...), `colorspace`
HCL palettes, then Okabe-Ito for a few categories. Use anything else (ColorBrewer, rcartocolor, PrettyCols, custom
brand colours) only after `cvd_preview()` shows the groups stay distinguishable, and always with a second encoding.
`theme_ms()` already sets viridis as the default for continuous and discrete colour and fill (ggplot2 >= 4.0:
`theme(palette.colour.continuous = "viridis")`, `palette.colour.discrete = "viridis"` or `"cividis"`; verified against
`viridisLite`). For two groups use two ends of viridis, e.g. `scales::viridis_pal(begin = 0.15, end = 0.8)(2)`; trim the
yellow end (`end` below 1) because pale yellow has low contrast on white.

## Rules that hold across sources

- Use colour only for information (Wilke ch. 19). Colour that encodes nothing is decoration.
- Qualitative colours: about 3 to 5 groups, never more than about 8 to 10; beyond that label directly or facet.
- Never rainbow/jet for numbers (non-monotonic lightness; invents boundaries). Never red-green pairs.
- About 8% of males and 0.5% of females are affected by red-green colour vision deficiency (CVD); blue-yellow
  deficiency is rarer. Behavioral Ecology and Springer Nature both ask for accessible palettes and a second
  visual cue (shape, pattern, direct labels).
- Avoid large areas of saturated colour; use lighter fills for areas and stronger colour for small marks.
- Thin lines and small points lose colour contrast; make them bigger or use shape/linetype as well.
- Keep colour-to-group mapping identical across every figure of a paper.

## Categorical palettes

- **viridis for categories:** `scale_colour_viridis_d(begin = 0.15, end = 0.85)` (ggplot2 built in; tested). Good up to
  about 4 groups; beyond that neighbouring colours look alike, so use direct labels or facets.
- **Okabe-Ito** (8 colours incl. black). Base R: `palette.colors(palette = "Okabe-Ito")` (R >= 4.0), no package
  needed. `scripts/figure_helpers.R` exposes `okabe_ito` (7 colours without black) and `scale_colour_ms()` /
  `scale_fill_ms()`. Black is left out because it is usually reserved for reference marks.
- ggplot2 >= 4.0: set the default palette in the theme, e.g.
  `theme(palette.colour.discrete = unname(okabe_ito))` (tested with ggplot2 4.0.3), or use
  `scale_colour_manual()` for explicit control of which group gets which colour.
- Other options: `ggokabeito` (not tested), `colorspace::scale_colour_discrete_qualitative()`, ColorBrewer
  `Dark2`/`Set2` (check CVD), `scico` (continuous mostly), `paletteer`/`cols4all` for catalogues (not tested;
  `cols4all` includes CVD-aware palette screening).
- Prefer two groups in strongly different lightness (for example sky blue vs vermillion) so grayscale also works.

## Continuous palettes

- `viridis` family (`scale_colour_viridis_c()`, `scale_fill_viridis_c()`; option "D" default, "E" cividis for
  strongest CVD safety).
- `scico` (Crameri's scientific colour maps; `scale_colour_scico(palette = "batlow")`; tested with scico 1.5.0).
  Crameri et al. 2020 (Nature Communications, doi 10.1038/s41467-020-19160-7) argue against rainbow maps and
  for perceptually uniform ones; the paper itself could not be fetched here, so rely on the OpenAlex record and
  Wilke ch. 4 for the summary.
- `colorspace` (HCL-based palettes; `scale_fill_continuous_sequential()`).
- `scale_*_distiller()`/`scale_*_fermenter()` for ColorBrewer ramps.

## Diverging data

Use a diverging scale only when there is a meaningful midpoint (zero change, reference value). Set the midpoint
explicitly (`scale_fill_gradient2(midpoint = 0)` or `scico::scale_fill_scico(palette = "vik", midpoint = 0)`).
Avoid red-green diverging; use blue-orange, purple-green or `vik`/`berlin`. For unidirectional data, a sequential
scale is correct, and a bidirectional scale invites false "above/below" readings (FDLF rule 3).

## Checking a figure for colour-vision deficiency

`scripts/figure_helpers.R` provides `cvd_preview(plot, path, width_mm, height_mm)`. It renders the plot and writes
a 2 x 2 PNG: original, deuteranopia, protanopia, tritanopia (`colorspace::deutan/protan/tritan`, severity 1,
full dichromacy, i.e. the worst case). Tested on a red/green/blue plot (red and green collapsed to the same
olive in deutan and protan) and on the Okabe-Ito example (groups stay distinguishable). Limits: it simulates the
common dichromat models, not every individual; it does not judge contrast against the background; it is a check,
not a replacement for shape and label redundancy.

Other tools (not run here): the `colorblindr` package (GitHub, needs permission to install), `cvd`
(not on CRAN under that name when checked), browser/OS simulators, the Viz Palette site.

## Grayscale and print

Print a figure in grayscale or convert it (`magick` or `colorspace::desaturate()`) and check that groups remain
distinguishable by lightness or shape. Journals that print in black and white (some still do) often ask that
legends do not refer to colour alone.
