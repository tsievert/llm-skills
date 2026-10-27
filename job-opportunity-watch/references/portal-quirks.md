# What the probe can and cannot read (tested 2026-10-23)

Contents: test results; filter limits; things to check when it stops working.

## Test on a real list

A links file of 104 unique URLs (Nordic, German, Dutch, Belgian, Austrian, French, Baltic university
and institute career pages, aggregators, three Google searches) was probed twice, one minute each:
85 `ok`, 9 to 10 `ok_js_suspect` (thin or script-rendered listings: an Oracle Cloud careers site,
valtiolle.fi, jobbnorge.no, and several university portals), 4 `blocked` (HTTP 403 or bot wall),
2 to 4 `http_error`/`error` (one 404, one 503 that was intermittent, a DNS failure and timeouts that
changed between runs), 3 `search_engine`. The first run found about 6,400 candidate links, of which
about 1,080 passed the title filter (about 280 tier 1); the second run, a minute later, found 5 to 27
new links and 1 to 2 queue items. So the diff works; a few failures are transient, which is why
`consec_fail` needs three runs before a source is called dead.

## Limits of the title filter

- Role and topic words are English plus parts of German, Swedish, Danish, Norwegian, Finnish, Estonian,
  Dutch and French. Missing languages mean missed items; extend `.role_re` and `.topic_re` in
  `scripts/jobwatch.R` when a language is under-represented in the portals.
- The deadline-cue list and month names in `jw_checks.R`'s `.jw_cue`/`.jw_mon` cover English, German,
  Finnish, Swedish, French and Dutch; a page in another language reads as `no_deadline_found` even
  with a visible deadline. Extend both when a new language's portals show up often as `no_deadline_found`.
- Generic titles ("Researcher", "Postdoc") hide the topic; the queue shows them in tier 2.
- Nav links and page-furniture are filtered by a stoplist of short phrases; some will leak through.
- Some aggregators list unrelated regions (for example US faculty-job PDFs on a general ecology board):
  they appear as candidates and are removed by the geography rules in the profile, not by the script.
- `jw_job_like_check()` reports a count of job-like anchors, not a share: a field-category aggregator can be
  rated `fine` (20+ job-like anchors) while most of them are generic nav or category pages ("Life Science",
  "Research Position") or roles outside the profile's groups, which only a page read or a title read catches.
  A page rated `fine` is not evidence the vacancies behind it are relevant ([classification.md](classification.md)'s
  aggregator-noise note). Not built: a share-of-noise metric or an excluded-system title stop-word pass, so
  budget time for opening plausible tier-2 titles from any field-category aggregator.

## Reading hints for pages the script cannot parse

- JavaScript listings: `webfetch` sometimes gets the rendered text; if not, look for an RSS feed, a
  JSON endpoint named in the page source, or the employer's EURAXESS/Jobbnorge/Academic Positions mirror.
- Pages with a cookie wall or login: record `blocked`, do not bypass.
- Listing pages that change every request (sorted by time, session ids in links) inflate "new" counts:
  the href check keys on the full URL, so normalise away session parameters if one source floods the queue.

## If the probe stops working

Check `jw_probe_one()` first on a single URL; common causes are a changed user agent policy at the site,
a proxy or VPN, an `httr2` or `rvest` release that changed function names (check the NEWS), or encoding
problems (the helper drops invalid bytes with `.clean()`).
