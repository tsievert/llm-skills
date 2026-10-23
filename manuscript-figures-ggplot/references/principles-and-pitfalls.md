# Principles and pitfalls for manuscript figures

## Contents
- Where the rules come from, and how opinionated each is
- Show the data (small samples, bars, boxes, violins)
- The unit of replication (repeated measures, pseudoreplication)
- Uncertainty: what to draw and what to state
- Axes, baselines, scales
- Colour use (short; details in colour.md)
- Overplotting, many groups, many panels
- Chart types to avoid or use with care
- Contested points: where sources disagree
- Pre-submission checklist

## Where the rules come from

| Source | Character | Use it for |
|---|---|---|
| Weissgerber et al. 2015, PLOS Biol (doi 10.1371/journal.pbio.1002128) | Evidence-based plea; 3 recommendations: show full data, change journal policy, train authors | Small-n continuous data: univariate scatterplots instead of bars |
| Wilke, *Fundamentals of Data Visualization* (https://clauswilke.com/dataviz/) | Balanced textbook, free online | Colour (ch. 4, 19), uncertainty (16), overplotting (18), multi-panel (21), captions (22), file formats (27) |
| Rougier et al. 2014, PLOS Comput Biol (doi 10.1371/journal.pcbi.1003833) | Ten rules, broad | Audience and message first, captions are not optional, do not trust defaults |
| Chenxin Li, "Friends Don't Let Friends Make Bad Graphs" (https://github.com/cxli233/FriendsDontLetFriends) | **Explicitly opinionated**, 16 rules, R code in `Scripts/` | Concrete do/don't list; see "Contested points" before applying literally |
| Data-to-Viz caveats (https://www.data-to-viz.com/caveats.html) | Catalogue of ~40 pitfalls with fixes | Quick lookup per chart type |
| Allen et al. 2019, Wellcome Open Res (raincloud plots, doi 10.12688/wellcomeopenres.15191.1) | Method paper | Raw data + density + summary in one panel |

Citation details above were checked in OpenAlex (titles, first authors, DOIs) on 2026-10-23. Summaries of the
Weissgerber, Rougier and Wilke pages were read from the live pages; Crameri 2020 and Wong 2011 (Nature sites)
could not be fetched, so claims about them rely on the OpenAlex record plus Wilke's chapter 19.

## Show the data

- With small n, plot every observation (beeswarm or jitter), then add a summary. Bar plots of means hide the
  distribution: very different samples can give identical bars (Weissgerber 2015; FDLF rule 1).
- Box plots hide bimodality and sample size; histograms depend on bin width unless n is large; violins and
  densities are unstable at small n. FDLF puts the thresholds at roughly n < 30 for histograms and about 50
  for stable violin quartiles; these are the author's simulation-based rules of thumb, not standards.
  Practical default in this skill: points for n up to a few dozen per group, then add a box, interval or
  half-eye; switch to density-based displays when n per group is in the hundreds.
- `ggbeeswarm::geom_quasirandom()` or `geom_beeswarm()` for points; `ggdist::stat_halfeye()` /
  `stat_pointinterval()` for distribution + interval; `geom_jitter(width = 0.1, height = 0)` as the base-ggplot2
  fallback (set a seed or use `position_jitter(seed = )` so the figure is reproducible).
- Do not claim a distributional shape from a smoothed curve fitted to a few points.

## The unit of replication

This matters most for behavioural and repeated-measures data (many trials per animal):

- Points that are not independent (trials within an animal) should be visibly linked to their unit: thin lines
  between sessions per individual, or colour/shape for individual only when there are few individuals.
- Summaries and intervals should come from the same model as the inference (for example `emmeans` on a GLMM;
  see the `mixed-models-glmm` skill), not from a t-interval over pooled trials. A t-interval over per-individual
  means is acceptable for a simple design and is what `assets/example_figure.R` uses.
- State n in the legend as "n = X animals (Y trials)" so the reader can see the replication level.
- Many spaghetti lines (more than about 30) turn unreadable; fade them (alpha, thin lines) and let the group mean
  carry the message, or facet by group (Data-to-Viz "spaghetti chart").

## Uncertainty

- Always state in the legend what the bars/bands are: SD, SE, 95% CI, credible interval, or range
  (Wilke ch. 16). SD describes spread of observations; SE and CI describe the precision of an estimate.
- Do not read significance from overlapping error bars; plot the difference with its interval as a separate
  panel when the contrast is the point (the example does this).
- Model-based curves (GAMs): show intervals and, where the question is about shape, consider simultaneous
  bands; wording and diagnostics are in the `gam-interpretation` skill.
- Graded intervals (for example 66% and 95% via `ggdist` `.width = c(.66, .95)`) reduce the "hard limit" reading.
- Do not show SE bars only because they are shorter.

## Axes, baselines, scales

- Bars encode length, so bars need a zero baseline. Dots, lines and intervals do not; truncate the axis if the
  data warrant it and say so. A broken axis on a bar plot is misleading (FDLF rule 9). If you must show a
  non-zero baseline, switch to a dot or line plot.
- Log scales for ratios, latencies, counts spanning orders of magnitude; label the axis "(log scale)" and
  use `scale_y_log10()` (or `scale_y_continuous(transform = "log10")`) rather than plotting `log(y)` with
  unreadable tick labels, unless the model is on the log scale and the statistic is on log units.
- Use identical axis ranges across panels that are compared (small multiples). If you free them, say so in
  the caption. Check the range of the response within each factor level; a narrow level can hide a real effect
  under shared axes (FDLF rule 7).
- Sequential data with a zero or natural midpoint use a diverging scale centred on it; unidirectional data use
  a sequential scale. FDLF rule 3: the lightest and darkest colours should mean something.
- Avoid dual y-axes; they let the author choose the story (Data-to-Viz, Datawrapper).
- Aspect ratio: avoid extreme ratios; give time series enough width to see slopes.

## Colour (summary)

Use colour only to encode something; at most about 3 to 5 categories (hard ceiling about 8); Okabe-Ito for
categories; viridis/scico/cividis for continuous; never rainbow or red-green; always add a second encoding
(shape, line type, direct labels). Full guidance in [colour.md](colour.md).

## Overplotting, many groups, many panels

- Overplotting: alpha, smaller points, `geom_hex()`/`geom_bin2d()`, `ggrastr::rasterise()` to keep the figure
  vector but rasterise the dense layer (keeps the PDF small; test that the layer still looks right at final size).
- More than about 8 groups: direct labels (`ggrepel`) or facets, not a legend of similar colours.
- Faceting vs panels: small multiples share scales and a legend; composite figures (a, b, c) combine different
  plots. Same colour/symbol for the same thing in every panel. Align axes across panels; `patchwork` helps.
  Tag panels lowercase or uppercase per journal; keep them small and consistent (Wilke ch. 21).
- Order categories by a meaningful variable, not alphabetically (Data-to-Viz "order your data").

## Chart types to avoid or use with care

| Chart | Problem | Alternative |
|---|---|---|
| Bar plot of means with SE bars | Hides distribution and n | Points + interval; bars only for counts/proportions |
| Pie / donut / concentric donut | Angles and areas are read poorly; ring order distorts | Bar (stacked or grouped), dot plot |
| Stacked bars with overlaid means | Ambiguous baseline | Separate panels |
| 3D, shadows, gradients as decoration | Distorts and adds ink | 2D |
| Rainbow / jet scales | Non-monotonic lightness, CVD-unsafe | viridis, scico `batlow`, ColorBrewer |
| Heatmaps unordered or with outlier-stretched scale | Pattern invisible, one cell dominates | Cluster/reorder (unless physically ordered), cap or transform the scale |
| Network graphs in one layout | Layout drives perceived structure | Try several layouts, report which |
| Radar/spider charts | Area and axis order arbitrary | Dot plot or parallel coordinates |
| Bubble size by radius | Area scales as radius squared | Map to area (`scale_size_area()`) |

## Contested points: where sources disagree

- **Pie charts.** FDLF and Data-to-Viz reject them outright; Wilke treats them as acceptable for very few
  parts of a simple whole and not for comparisons across groups. Default here: use bars; if the user wants a
  pie for 2 or 3 parts, say what it costs and let them decide.
- **Violin plots.** FDLF rule 2 warns against them for small n. They are fine for large n when the shape is
  the point; pair with the raw points or intervals.
- **Bar plots.** Not wrong for counts, proportions and other length-coded totals with a zero baseline; the
  criticism is about continuous data with small n.
- **Circular layouts / circos.** FDLF argues against them for most uses; they remain standard in some
  genomics subfields where reviewers expect them.
- **Mean separation letters / significance stars.** Common in the user's field; keep them off the plot when
  an interval plot of contrasts carries the information, or put them in the legend or a table.
- **Fixed rules (n < 30, quartiles stabilise above 50, cap at 95th percentile).** Treat as heuristics from one
  author's simulations; check with the user's own data.
- **Absolute sizes in ggplot2 4.0.** Community posts (see community-notes.md) note that viewer panes and some
  tools do not respect `panel.widths`; save and inspect the file, not the viewer.

## Pre-submission checklist

1. Journal and column width known and checked on the live instructions page.
2. Built at final size; text 5 to 8 pt as the journal requires; lines at least the journal minimum.
3. Raw data visible at small n; unit of replication clear; n in legend.
4. Uncertainty defined in the legend; intervals consistent with the analysis.
5. Colour: CVD preview run; second encoding present; same colour means the same thing in every figure.
6. Axes: baselines justified, log scales labelled, ranges comparable across compared panels.
7. Legend/caption: what is plotted, how to read it, n, test or model, abbreviations, scale bars if images.
8. Files: vector PDF/EPS (or SVG) where accepted, TIFF/PNG at the journal dpi otherwise; fonts embedded;
   background white; file names as requested.
9. Alt text for each figure if the journal or publisher recommends it (Springer Nature does).
10. Re-created from code (script in the repo, seeds set), so a reviewer's requested change is a one-line edit.
