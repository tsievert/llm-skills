# What people post about plots (Bluesky and Mastodon)

Collected 2026-10-23 with `social-research-search` (keyless Bluesky `searchPosts` and Mastodon hashtag timelines on
mastodon.social, fosstodon.org, mstdn.science). Anecdotal leads, not evidence. Over-represents R users who share
publicly; Mastodon search is hashtag-only. Posts are linked, not quoted at length.

## Contents
- Method and limits
- Themes seen
- Linked examples
- Re-running the search

## Method and limits

About 680 posts (deduplicated) from queries on ggplot2, patchwork, dataviz, colourblind palettes, figure export,
raincloud/beeswarm, ggplot2 4.0, bar charts. Roughly 130 were on topic after keyword screening; most were
TidyTuesday and 30DayChartChallenge showcases (art and storytelling, rarely journal conventions). Likes are small
(top posts a few dozen), so no claim about prevalence is made.

## Themes seen

1. **Multi-panel composition is almost entirely patchwork**; new helper packages extend it (ggalign for aligned
   heatmaps, `ggh4x::facet_manual()` for arbitrary facet layouts, `ggreveal::reveal_patchwork()` for slides).
2. **Sizing at export is a recurring pain.** Tips: preview at the saved size (`ggview`), set `panel.widths` (ggplot2
   4.0), and one post asks for viewer panes, `ggsave()`, Quarto, Shiny and patchwork to honour absolute dimensions.
   Another post works out per-panel sizes with `patchwork::plot_layout` or `wrap_plots()`.
3. **Small ggplot2 fixes people share:** `guide_axis(check.overlap = TRUE)`, `size.unit = "pt"` in `geom_text()`,
   `rel()` for sizes, `plot.title.position = "plot"`, `bg =` in `ggsave()` (all tested in this skill's smoke test).
4. **Accessible colour:** a Mastodon post asks for an onboarding resource on accessible palettes (current
   answers: `scico`, `colorspace`); an accessible-dataviz library appeared from a Luxembourg observatory team.
5. **Axis truncation:** a user asks how to draw a broken axis on a line chart; this conflicts with FDLF's advice for
   bar plots but is accepted for lines/dots if marked.
6. **Wrappers:** `tidyplots` (its author describes it as bundling existing packages), `ggsql` (SQL-driven plots) are
   new; not evaluated.

## Linked examples

| Topic | URL |
|---|---|
| Quick ggplot2 fixes from a workshop (ggview, etc.) | https://fosstodon.org/@nrennie/117365167359453743 |
| Five lesser-known ggplot2 functions (blog, read) | https://nrennie.rbind.io/blog/five-ggplot2-functions/ |
| Absolute plot dimensions need tool support | https://bsky.app/profile/jbengler.de/post/3lzhe7enxxk2a |
| tidyplots bundles existing packages | https://bsky.app/profile/jbengler.de/post/3lhbar2ztcs2x |
| ggalign for aligned heatmaps | search post "ggalign" on Bluesky, 2025-08 (URL in the saved result set) |

## Re-running the search

```r
source("<repo>/social-research-search/scripts/social_search.R")
bsky_search("ggplot2 figure journal", sort = "top", max_posts = 100, since = "2026-01-01")
masto_tag("dataviz", instances = c("mastodon.social", "fosstodon.org", "mstdn.science"))
```

Filter `text` yourself (the search is fuzzy). Do not compile profiles of individuals; link and summarise.

## TidyTuesday code scan (added same day)

A sparse clone of https://github.com/nrennie/tidytuesday (2025 and 2026, 93 weekly folders) was scanned for idioms:
`camcorder::gg_record` in 50 scripts, `ggview::canvas` in 33, `ggtext` textbox/markdown theme elements in 83,
`clip = "off"` in 40, `scale_*_identity` in 15, `ggh4x::facet_manual` in 4, `showtext` plus Google fonts in 83,
`rcartocolor`/`PrettyCols` palettes in about 11 each. One author's habits, aimed at web and social media, so only some
transfer to journals. Details, status and what was tested: [ggplot2-hacks.md](ggplot2-hacks.md).
