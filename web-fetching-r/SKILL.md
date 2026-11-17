---
name: web-fetching-r
description: 'Provides polite, rate-limited web fetching in R (httr2/rvest/xml2): a shared helper for a consistent user agent, per-host throttling, retry/timeout handling, and bot-wall/JavaScript-rendering detection, plus a workflow for pulling a table or list of records from a given page into a data frame for a one-off task. Also the shared fetch mechanics that job-opportunity-watch, recipe-notes-formatter and social-research-search source instead of each re-implementing their own copy. Use when the user wants to scrape, pull, or extract a table or list from a specific webpage for one-off use, or mentions rvest/httr2 web scraping. Not for a recurring watch list of job portals (use job-opportunity-watch), recipe pages (use recipe-notes-formatter), academic literature (use openalex), or Bluesky/Mastodon (use social-research-search).'
compatibility: Requires R with httr2, rvest and xml2, and internet access. Read-only and polite -- per-host rate limiting, an identifying user agent, no logins, no bot-wall or CAPTCHA bypass. scripts/polite_fetch.R has no skill-specific logic; other skills source it for the fetch mechanics and keep their own parsing and state.
---

# Web fetching (R)

Two things live here: a shared polite-fetch helper that other skills reuse instead of
re-implementing, and a workflow for one-off page scraping (pull a table or list into a data
frame for a single analysis task, no recurring state).

## Where this skill runs

Locally, in the user's R session. Nothing is submitted to any site; no accounts, logins or
CAPTCHA bypassing. Pages behind a bot wall or that need JavaScript are reported, not forced.

## Step 1: the shared helper

```r
source("<skill-dir>/scripts/polite_fetch.R")   # <skill-dir> = folder shown when this skill loads
```

| Function | Does |
|---|---|
| `pf_user_agent(skill, purpose, version)` | Builds a consistent, identifying user-agent string |
| `pf_host(url)` | Host name from a URL, for use as a `pf_wait()`/state key |
| `pf_wait(host, min_interval, state)` | Sleeps just long enough that `min_interval` seconds have passed since the last request to `host` |
| `pf_perform(url, ua, timeout, max_tries, retry_on, query)` | One non-throwing HTTP request (retries transient codes, never raises on HTTP/network errors) |
| `pf_fetch_html(url, ua, min_interval, timeout, max_tries, retry_on, state)` | `pf_wait()` + `pf_perform()` + light HTML parsing; returns `list(url, status, http, content_type, html, doc, problem)` |
| `pf_blocked_text(text)` | Heuristic: does the start of the visible text look like a CAPTCHA/bot-wall/"enable JavaScript" page? |
| `pf_js_suspect(text_chars, n_scripts, n_anchors)` | Heuristic: does the page look like it needs JS rendering (thin text/links, many `<script>` tags)? |
| `pf_tables(doc)` | All HTML tables on a parsed page as a list of data frames (thin wrapper over `rvest::html_table()`) |

Full contracts, defaults and the reasoning behind each heuristic:
[references/shared-helper-contract.md](references/shared-helper-contract.md). Treat this file as
the one place these mechanics are documented -- do not copy the heuristics or retry logic into
another skill's body; source the script and link here instead.

## Step 2: one-off extraction

For "pull this table/list off this page" tasks that do not need a recurring watch list or
domain-specific parsing (those belong to the skills named in the description):

1. `r <- pf_fetch_html(url, pf_user_agent("ad-hoc-analysis", "one-off data pull"))`
2. Check `r$problem` first. If `pf_blocked_text(r$html)` or the page looks thin, say so and try
   the `webfetch` tool once before giving up -- do not attempt to bypass a bot wall or CAPTCHA.
3. `pf_tables(r$doc)` for `<table>` elements, or `rvest::html_elements(r$doc, <css selector>)`
   for lists/cards the user points out.
4. Always show the source URL next to anything extracted, and note that a single fetch is a
   snapshot (re-run if the user needs current data later).
5. For more than a handful of pages, or anything that should run again later with state and
   deduplication, that is a recurring job and belongs to a dedicated skill, not this one -- say so
   rather than building an ad hoc loop.

## Related skills

- `job-opportunity-watch`: recurring, stateful watching of a list of job portals; sources this
  skill's helper for the fetch mechanics.
- `recipe-notes-formatter`: recipe pages specifically (JSON-LD/microdata extraction); sources this
  skill's helper for the fetch mechanics.
- `social-research-search`: Bluesky/Mastodon API calls, not HTML scraping; shares the same
  retry/error-handling pattern via `pf_perform()`.
- `openalex`: academic literature search via its own API, not general web scraping.

## Explain the reasoning (teaching rule)

Teach, don't replace the user's thinking: say briefly (a sentence or two) why things were or were not done, name the trade-off and which decision is the user's, and point to a reference for depth.

## Capture lessons (self-improvement rule)

Load the `skill-lessons` skill and append a generic, anonymised entry (no project data, IDs or paths) as soon as something unanticipated happens: an error or warning, advice or code that failed, a user correction, a version or API mismatch, missing guidance, or a recommendation that held up (`worked-well`). Also write one `use-case` entry per session. When unsure, record it with `generality: unsure`. Entries are hypotheses for `skill-feedback-triage`.
