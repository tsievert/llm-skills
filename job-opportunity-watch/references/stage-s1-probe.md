# Stages s0-s3: setup, probing and what the headless stages cannot read

## Contents

- [Data folder](#data-folder)
- [Before the first run](#before-the-first-run)
- [Reading the source table](#reading-the-source-table-s1_sourcesparquet)
- [What the script cannot read](#what-the-script-cannot-read) (JavaScript pages, `search_engine` links, feeds, aggregator noise)
- [Dead or moved links](#dead-or-moved-links-http_error-error)
- [Related](#related)

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
  giving up (propose it as a `type = sitemap` link or a replacement; `jw_find_replacement()` checks
  `robots.txt` sitemaps too). Do not silently simplify a long filtered search URL to get a probe-able page: a
  shortened URL searches something different from what the user asked for, so propose the plain and the
  simplified version separately rather than swapping one in. For a source that stays JavaScript-only, run
  `jw_discover_endpoints(url)` (feeds, JSON-LD, API URLs in the page's scripts, with a `robots.txt` verdict); an
  endpoint whose host disallows robots is reported to the user, not used. EURES and Oracle portals can be
  switched to a JSON source with `json:eures` / `json:oracle` in the link note, once the user has accepted the
  terms in [portal-quirks.md](portal-quirks.md).
- **`search_engine` links:** not fetchable (Google answers plain HTTP with a CAPTCHA or nothing; not bypassed).
  The probe's note holds the decoded query with all operators plus the URL's time filter, for example
  `(olfaction OR smell) research (job) -wiley -site:msu.edu  [time filter: past month]`. The key ignores
  tracking parameters (`sxsrf`, `ved`, `gs_lp`, `sca_esv`, `client`, fragment), so re-pasting the same search
  from the browser does not create a new source. To run it: pass the query to `web_search` **with** the
  operators, because the exclusions define the search; `web_search` may honour them only partly, so
  afterwards drop results that match an excluded term or `-site:` domain yourself, and keep only results
  within the time filter (check the dates; the filter itself cannot be sent). Tell the user the exact query used
  and which exclusions you applied by hand. If the tool returns mostly off-topic results with the operators,
  also try the query without only the `-site:` terms and say so; do not drop all operators silently.
  **Caveat (live test 2026-11-03):** `web_search` only partly honours operators (an excluded term still appeared),
  cannot take the time filter, and for a vacancy query returned mostly US commercial job boards, patents and
  papers, with no university vacancy. Always report this to the user in one line (how many results were real
  vacancies, which operators were not honoured, that dates could not be filtered); never present such a run as
  equivalent to the Google search. **Retry loop = diagnostic, not a fix:** after each run call
  `jw_search_refine(query, result_urls, round)`. If it returns `rerun = TRUE`, run `query_next` (it adds
  `-site:` for the noisy domains), at most 2 reruns, and list every round (query, noise share) in the report.
  In the live test (2026-11-03) `web_search` ignored `-site:` completely: the noise share went from 100% to 90%
  and 9 of 10 round-2 results came from the domains just excluded. Expect the loop to end with the verdict
  **weak source** (`jw_search_refine` says "every noisy domain is already excluded"); report that verdict, do
  not keep rerunning, and do not claim the exclusions worked. If a rerun does lower the share, say so; that
  means the tool honoured the operators this time. After a weak verdict propose, via the maintenance protocol, a
  better link (a portal, feed or the Brave API); the user decides. Adding domains to `jw_noise_domains` or to
  the user's saved query is a proposal, not an automatic change.
- **Aggregator noise:** an aggregator lists the same vacancy as many employers' pages and many unrelated roles;
  count one opportunity once (employer, title, reference, deadline), and use aggregators for discovery, not as
  final evidence ([classification.md](classification.md)'s aggregator-noise note has the detail).
- **Feeds (RSS/Atom):** before adding one, verify it rather than trusting the HTTP status: a 200 response with
  an XML content type, or the presence of a sitemap, is not evidence of a usable vacancy feed. Checklist:
  (1) it returns at least one item; (2) item titles read as vacancies, not news or a generic digest; (3) each
  item has a date (`pubDate`/`updated`); (4) each item links to the vacancy page, not a category page; (5) any
  filter in the original search is honoured by the feed, or can be applied locally after fetching (test with
  and without the filter: a feed can look valid yet ignore it). A feed with items but none a vacancy, or an
  empty category feed, fails the checklist and is not added. `jw_probe_one()` reads RSS 2.0, Atom and RDF
  feeds (any XML body whose root is `rss`, `feed` or `RDF`): one anchor per item with title and link, note
  `feed: N items`. Items are not filtered by the probe; the job-like flag and profile prefilter do that, and
  dates are not kept, so check the dates by hand (item 3 of the checklist). Tested live on one aggregator feed
  (100 items) and on synthetic RSS and Atom.

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
