# Stage s6: report

Contents: what the report contains; chat summary; discovery; periodic use.

`jw_render_report(week)` writes `summary.md` (small; the next conversation reads this, not the HTML) and renders
`report.html` into the run folder: a standard, self-contained Quarto HTML document (`format: html`), not a
Quarto dashboard. It is headless; the assistant only summarises it in chat. If any earlier stage is not `done`
the report says INCOMPLETE; say so too.

Not a dashboard, and not an htmlwidget: an earlier version used `format: dashboard` with `reactable` tables.
Chromium browsers (Chrome, Edge) refuse to execute `<script type="module">` tags loaded from a `data:` URI when
the page is opened via `file://` (treated as cross-origin), so every `reactable` table came up blank (only its
card title rendered) while the dashboard's static value boxes still showed numbers. Switching to plain
`format: html` removed the dashboard's module-script navigation, but `reactable` tables stayed blank too: the
widget's own JS (also loaded as a `<script>` tag pointing at an embedded `data:` payload under
`embed-resources: true`) hits the same `file://` restriction, so **any** htmlwidget (`reactable`, `DT`, `plotly`
with its default renderer, ...) is unreliable in a self-contained report meant to be opened straight from disk.
The report now builds every table with `knitr::kable()` + `kableExtra::kable_styling()`/`scroll_box()`, which
emit only HTML and CSS, no JS, so it renders correctly regardless of how the file is opened. The trade-off is no
in-table search or column sort; use the browser's find-in-page, or query the parquet files with `arrow` /
`summary.md` for anything that needs filtering. If a future change reintroduces an htmlwidget, either serve the
report over `http(s)://` (e.g. `quarto preview`, a local server, or publish it) instead of opening the file
directly, or keep tables static.

## Chat summary (short; the ledger holds the detail)

Lead with what is new since the last run, then deadlines within about 14 days, then source health.

1. Audit line: links unique, probed, flagged `weak` or `nav_only`, sources needing a manual check.
2. Primary employment: new items, class D/E first, each with employer, title, country, deadline, contract,
   final status, one line on why and one on the weakest dimension, and the link.
3. Fellowship hosts, then supplementary opportunities (separate lists; never rank unpaid items against salaried
   employment).
4. Class A/B items only as one-line rejections or open questions the user might disagree with; near-misses with
   the rule that excluded them and what relaxing it would cost.
5. Limitations: what was not readable, assumptions, facts versus inference. A baseline week is labelled as such.

## Discovery

Additional discovery (species, mechanisms, local-language terms, institutions, early signals) happens only when
asked, after the supplied links are processed, in stage s5 ([stage-s5-discover.md](stage-s5-discover.md)).

## Periodic use

The assistant cannot wake itself. Offer, do not install without a yes: a check at session start (`jw_due()`);
the headless DAG on a schedule (`pipeline.md`, "Scheduling notes"; it stops at s4 and the user starts the s4
conversation); or the older model-free `Rscript scripts/run_probe.R <data-folder>`. A `SessionStart` reminder
hook is possible (check the hooks docs first; hooks add start-up time).
