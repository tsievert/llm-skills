# What the probe can and cannot read (tested 2026-10-23)

## Contents

- [Test on a real list](#test-on-a-real-list)
- [Limits of the title filter](#limits-of-the-title-filter)
- [Links that redirect to a changing Google Sheet](#links-that-redirect-to-a-changing-google-sheet)
- [Sources that failed in one weekly run (checked 2026-11-03)](#sources-that-failed-in-one-weekly-run-checked-2026-11-03)
- [JSON sources and endpoint discovery (checked 2026-11-03, one machine, one time)](#json-sources-and-endpoint-discovery-checked-2026-11-03-one-machine-one-time)
- [Reading hints for pages the script cannot parse](#reading-hints-for-pages-the-script-cannot-parse)
- [If the probe stops working](#if-the-probe-stops-working)

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

## Links that redirect to a changing Google Sheet

Some community job boards are a stable URL that redirects to a new public Google Sheet each year, with one
tab per job type. A plain probe sees a redirect and no anchors. Do not replace the link by the resolved
sheet or per-tab CSV export URLs: the sheet id changes yearly, so they go stale (a user correction). Keep the
stable link and resolve at run time with `jw_resolve_gsheet(url, tabs = "postdoc|faculty")`: it reads the
redirect target without fetching it, the tab names and gids from the public `/htmlview` page, and downloads
each chosen tab as CSV (`/export?format=csv&gid=`). Tested live on one board (400 and 194 rows; banner in
row 1, headers in row 2, duplicate header names made unique with `make.unique`); the function stops with a
clear message if the link is not a sheet redirect, the sheet is not public, or the tab list is not found
(Google may change the page).

In the probe: a link with the word `resolver` in its `note` column gets `type = resolver`, and a portal link
whose redirect ends on a sheet is resolved the same way without the flag. `jw_probe_one` then returns one
anchor per sheet row that has a URL (text from institution, subject, rank or PI, location; href from the
URL column), so rows flow through s1 to s3 like any other listing. Tabs come from
`options(jobwatch.gsheet_tabs = "<regex>")`, default `postdoc|faculty|permanent`. Rows carry no per-row
status or date in the anchors: the profile's geography rules do the filtering (such boards are often
US-heavy, so expect many rejected titles) and the deadline check reads the target pages. Tested live on one
board: 594 rows, 593 with a link, identical result by flag and by redirect; a non-sheet link under
`resolver` gives `status = error` with a clear note. Not tested: a sheet that stops being public mid-run,
tab names that match no pattern (returns zero anchors), `jw_probe()` end to end over a whole links file.

## Sources that failed in one weekly run (checked 2026-11-03)

- RSS feed read as "unparseable html": fixed, see `stage-s1-probe.md` (XML bodies are no longer sent to the HTML parser).
- A Cloudflare "Just a moment" challenge (HTTP 403, also on `sitemap.xml` and `/rss`): the site's
  `robots.txt` allows crawling and lists sitemaps, but the challenge blocks scripted requests. Do not
  bypass; mark it `manual-check` and use a mirror or aggregator that is probeable.
- Connection timeouts to one host that resolves, while other hosts of the same institution work: this can be
  the local network or a firewall rule rather than the site, and no script change fixes it. Test from
  another network (the user's browser, a phone hotspot) before retiring the link.
- "Could not resolve hostname" on the local resolver (`SERVFAIL`) with no second resolver reachable: ask the
  user to open the page in a browser; if it loads there, the problem is the machine's DNS.

## JSON sources and endpoint discovery (checked 2026-11-03, one machine, one time)

A portal that shows only "Loading..." often fills the page from a JSON endpoint that answers without a login.
Two are supported by `jw_probe_one()`, each **opt-in per link**: put `json:eures` or `json:oracle` in the link's
`note` column (the link type becomes `json_eures` / `json_oracle`). The portal URL stays the key; the API call
is built from its query parameters. Add the word only after the user has accepted the terms below.

| Source | Opt-in | How it reads the portal URL | Terms and robots (read 2026-11-03) |
|---|---|---|---|
| EURES job-vacancy search | `json:eures` | `POST /eures/api/jv-searchengine/public/jv-search/search`; maps `keywordsEverywhere`, `locationCodes`, `positionScheduleCodes`, `educationLevel`, `publicationPeriod`, `escoOccupation`, `minNumberPost`, `orderBy`; a `-keyword` is an exclusion applied to titles locally; unknown parameters are listed in the note | The legal notice authorises reuse with acknowledgement of the source (ELA) and says nothing on automated access; `europa.eu/robots.txt` does not disallow `/eures/`. Cite EURES when reusing the data |
| Oracle Candidate Experience (`*.oraclecloud.com/hcmUI/CandidateExperience/<lang>/sites/<site>/...`) | `json:oracle` | `GET /hcmRestApi/resources/latest/recruitingCEJobRequisitions` with `findReqs;siteNumber=<site>` plus the portal's facet parameters (categories, organizations, locations, titles, posting dates, `keyword`); multi-value facets with `;` work; deadline (`PostingEndDate`) is kept when present | The instance served no `robots.txt` (404). Oracle's website terms (oracle.com) forbid robots and scrapers for oracle.com itself; they were read, but whether they cover an employer's hosted career site was not established, and the employer's own terms were not read. Ask the user per portal |
| University of Graz (`jobs.uni-graz.at`) | not built | The app calls `personal.uni-graz.at/api/erec/public/job-postings` (JSON with deadlines) | That host's `robots.txt` is `Disallow: /` for all agents, so it is **not fetched**; `jw_discover_endpoints()` reports it as `robots_allowed = FALSE`. Ask the university or use the page in a browser |
| Jobbnorge | not built | `api.jobbnorge.no` answers 401 | Needs a key: manual check |

Checked live: EURES with a real saved search (2 records after filters and one excluded keyword; not compared with
the portal's own count) and with a single keyword; Oracle with category, organization and date facets (9 postings;
job links resolve). EURES quirk: R's libcurl fails with "Failure when receiving data" when it advertises
compression, so the call sets `accept_encoding = "identity"`. Not tested: more than one page of results, an
Oracle site with a different language code, EURES filter codes beyond those in the saved search.

Helpers for stubborn links (all in `jobwatch.R`, none edits `links.csv`):

- `jw_robots_allowed(url)`: `TRUE`, `FALSE`, or `NA` when `robots.txt` cannot be fetched (longest match wins,
  `*` and `$` supported, cached per host). Check it before using any endpoint found by hand.
- `jw_discover_endpoints(url)`: one page request plus at most three same-site scripts. Lists feeds
  (`rel=alternate`), schema.org JobPosting data, API URLs named in the scripts (`apiUrl`, `/api/`, `/rest/`,
  `/wp-json/`) with robots verdict, HTTP status and content type, the opt-in words for the two known portals, and
  fingerprints for Greenhouse, Lever, Personio, Recruitee and SmartRecruiters (their public job APIs were not
  tested here). Propose a candidate to the user with this evidence.
- JSON-LD: `jw_probe_one()` now also reads schema.org `JobPosting` objects from
  `<script type="application/ld+json">` (including `@graph` and `ItemList`), so a page that exposes vacancies that
  way no longer looks like a menu. Tested on synthetic pages only; the one live page checked (University of
  Iceland) had no JobPosting data.

Other findings from the check: the ECRO job-offers page was not dead (the host resolves elsewhere and appears
in web search; the failure was this machine's DNS), `english.hi.is/vacancies` listed one real vacancy whose
title had no role word, so `nav_only` is a false negative for sparse pages, and UHasselt's English vacancies
page stayed `nav_only` after fetching the HTML.

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
