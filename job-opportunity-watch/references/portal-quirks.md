# What the probe can and cannot read (tested 2026-10-23)

## Contents

- [Test on a real list](#test-on-a-real-list)
- [Limits of the title filter](#limits-of-the-title-filter)
- [Links that redirect to a changing Google Sheet](#links-that-redirect-to-a-changing-google-sheet)
- [Unreadable sources: the fetch ladder (generic, by failure class)](#unreadable-sources-the-fetch-ladder-generic-by-failure-class)
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
  `scripts/jw_probe.R` (`.role_re`, `.topic_re`) when a language is under-represented in the portals.
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

## Unreadable sources: the fetch ladder (generic, by failure class)

`jw_probe_one()` no longer treats a failure as final. It classifies the first response once and the class picks the
next routes; no route names a site, so a new problem link needs no new code. The routes are in `pf_fetch_ladder()`,
`pf_render_html()` (web-fetching-r) and `jw_suggest_routes()`; the evidence is in
`research/job-opportunity-watch-refactor-ledger.md` (2026-11-23).

| Class (how it is detected) | Routes tried, in order | Ends as |
|---|---|---|
| `challenge`: `cf-mitigated: challenge` header, or a body such as "Just a moment" / CAPTCHA / WAF page | none: stop at once | `blocked`, note "bot challenge (not bypassed)". Use a mirror or aggregator already in the list, or the browser. `robots.txt` on such a host is usually challenged too |
| `forbidden`: 401/403 without a challenge | a Googlebot-style `Mozilla/5.0 (compatible; <tool>/<version>; <purpose>)` user agent (still names the tool), then the URL variants | `ok` with note `route: ua_compat ...`, else `blocked`. The host remembers a working route for the session. Some WAF rules reject any user agent without the `Mozilla/5.0 (compatible; ...)` token (seen on a European research portal) |
| `not_found` (404/410) | language-neutral variants only (a wrong path will not be fixed by `www` or https) | `http_error`, note "link moved, try `jw_find_replacement()`" |
| `transient` (429/5xx) or `network` | one retry with backoff, then variants: drop the language subdomain (`en.host` to `host`) or path segment (`/en/`), toggle `www`, upgrade to https, toggle the trailing slash (at most 3) | `ok` with the route in the note, else `http_error`/`error`. A language subdomain that fails while the neutral host works was seen once |
| Read but thin, or fewer than 10 vacancy-like links (`jobwatch.render_min_hits`) | **render**: headless Chrome through `chromote` (optional; skipped with a note when missing). It loads the page as a user would, never loads images or fonts, and sends every page, XHR and fetch request through the `robots.txt` check, so a cancelled request is counted in the note | rendered anchors replace the static ones only if they hold more vacancy-like links. Slow: about 5 s per page, a 100-link list took about 7 minutes instead of 2. Opt out with `options(jobwatch.render = FALSE)` |
| Still thin after rendering | `jw_suggest_routes()`: feeds and sitemaps announced by the page or `robots.txt`, JSON-LD, API URLs in the page's scripts (with the `robots.txt` verdict), known portal platforms with their `json:` opt-in word | note `try: ...` for the assistant and user to follow; nothing is switched on automatically |

What stays a decision for the user: the `json:eures` / `json:oracle` opt-in (terms, below), replacing a dead link, and
any source that is a deliberate block. A page whose rendering needs a host that `robots.txt` disallows is read only
as far as the allowed requests give (a university portal whose job API disallows all agents rendered 11 links
instead of a listing). Not covered: pages that need a click or scroll before the list appears, and login walls.

Other failure causes the ladder cannot fix:

- Connection timeouts to one host that resolves, while other hosts of the same institution work: possibly the local
  network or a firewall rule. Test from another network (browser, phone hotspot) before retiring the link.
- "Could not resolve hostname" on the local resolver with no second resolver reachable: ask the user to open the
  page in a browser; if it loads there, the problem is the machine's DNS.
- An RSS body sent to the HTML parser ("unparseable html") is fixed: XML bodies go to the feed reader.

Tested 2026-11-23 on one machine: of 17 sources that were not `ok` in a weekly run, 5 became `ok` (one by the compatible user agent, three by rendering, one when a transient 503 cleared) and 12 stayed (challenge pages, a moved link, three search-engine links, thin pages); the 97 sources that were already `ok` kept their status.

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

Helpers for stubborn links (in `scripts/jw_*.R`, loaded by `jobwatch.R`; none edits `links.csv`):

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
  Iceland) had no JobPosting data. Later, a user report found that reading JobPosting JSON-LD (title, employer,
  deadline, keywords) from the ads of a German job aggregator worked well for judging consultancy and
  planning-office vacancies (one report, not re-tested here).

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
