# Stages s0-s3: setup, probing and what the headless stages cannot read

Contents: data folder; before the first run; reading the source table; sources the script cannot read; dead or moved links.

The mechanical stages run headless (`targets::tar_make()`, see `pipeline.md`) or from the console with
`jw_stage_run("s1", function() jw_s1_probe(week), week, expected_n = jw_s1_expected_n(week))`. This file is for
the assistant when it has to interpret or repair their output.

## Data folder

The data folder holds `links.csv`, `job_profile.yml`, `runs/<week>/` and `opportunities.parquet` (layout:
[state-and-files.md](state-and-files.md)). Set `options(jobwatch.dir = "<folder>")`. If the user's memory file
does not record the folder, ask once and offer to note it there. Missing files: offer to start from
`assets/links.template.csv` and `assets/job_profile.template.yml`, filled in with the user. A legacy `links.txt`
still works; offer the one-time `jw_convert_links_txt(confirmed = TRUE)` (the `.txt` stays). A profile saved as
`.txt` is YAML: suggest renaming it to `job_profile.yml`.

## Before the first run

1. Load `web-fetching-r` and source its `scripts/polite_fetch.R` first (`jobwatch.R`
   needs its `pf_*` helpers and stops with a clear message without them), then `jobwatch.R`, then
   `jw_report.R` with `jw_load()`. The headless DAG does this itself.
2. `jw_due(every_days = 7)` says whether a run is due; if not, say so and ask whether to run anyway.
3. Read the profile and restate in three or four lines the hard requirements and exclusions (contract, FTE,
   geography, excluded titles and systems). Use a labelled provisional assumption for anything unknown; do not
   interview the user before probing.

## Reading the source table (`s1_sources.parquet`)

Counts must add up: the s1 gate compares unique enabled links with source rows, so say "N of N sources
probed" only when the stage is `done`. Statuses: `ok`, `ok_js_suspect` (listing probably rendered by
JavaScript), `blocked`, `http_error`, `error`, `non_html`, `search_engine`. Flags: `fine`, `weak` (fewer than 3
vacancy-like links), `nav_only`, `not_assessed`. `fine` means the page has vacancy-like links (category and menu
links are excluded), not that the vacancies are relevant. A full run of about 100 links takes 1-2 minutes.

## What the script cannot read

Record every attempt, continue, never stop the run for one link:

- **`ok_js_suspect`, `blocked`, `nav_only`:** try the `webfetch` tool once. If still empty, list the source as
  "needs manual check" and do not claim it was checked. Sources that stay in this state for several weeks are
  candidates for replacement. JavaScript-only listings often have a feed, API or sitemap: look for one before
  giving up (propose it as a `type = sitemap` link or a replacement).
- **`search_engine` links:** not fetchable. The probe returns the decoded query; run it (without operators)
  through `web_search`. The time filter in the URL is lost, so check dates in results.
- **Aggregator noise:** an aggregator lists the same vacancy as many employers' pages and many unrelated roles;
  count one opportunity once (employer, title, reference, deadline), and use aggregators for discovery, not as
  final evidence.
- **Feeds:** before adding an RSS/Atom link, open it once and check it lists vacancies (not news), has dates and
  links to the vacancy pages, and is not truncated. Feed sources are not built into the probe yet.

## Dead or moved links (`http_error`, `error`)

Retry once at the end of the run (503 and timeouts are often transient). If it still fails, in this order:

1. `jw_find_replacement(url)`: parent paths, the site's sitemaps (robots.txt `Sitemap:` lines and common
   names) and job-like links on the home page; returns scored candidates that answer with HTTP < 400.
2. `web_search` for the employer's name plus "vacancies" or "jobs" in the local language; prefer a result on the
   same domain; `webfetch` on the employer's home page.
3. Probe the best candidate with `jw_probe_one()` and check that it lists vacancies (not one job, a news item or
   another department). A DNS failure on every candidate suggests your network, not the site: say so.

Propose the replacement with the evidence (old status, where the new one was found); keep the old link until
the user agrees ([maintaining-links-and-profile.md](maintaining-links-and-profile.md)).

## Related

`pipeline.md` (mechanical stages, sitemap sources), `portal-quirks.md` (per-portal filter notes),
`web-fetching-r` (polite fetching).
