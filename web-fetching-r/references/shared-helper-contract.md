# Shared helper contract

`scripts/polite_fetch.R` is sourced by other skills' own scripts, not just by the assistant
directly. Treat its function signatures and return shapes as a contract: a change here can break
`job-opportunity-watch`, `recipe-notes-formatter` and `social-research-search` at once. This file
is the single place the mechanics and the reasoning behind the heuristics are documented; do not
duplicate it into a dependent skill's body.

## Contents

- Why these functions exist
- Contracts
- Heuristic thresholds and where they came from
- Changing this file

## Why these functions exist

Three skills independently hand-rolled the same pattern (found 2026-10-24, see the
`research/skill-roadmap-ledger.md` ledger in the llm-skills repo): a custom user-agent string, a
manual per-host rate limiter (a stored last-request timestamp plus `Sys.sleep`), and an
httr2 request pipeline with retry-on-transient-status and never-throw-on-HTTP-error. Keeping one
tested copy avoids the three drifting apart (for example, one skill's bot-wall phrase list being
fixed and the other two staying stale).

The CRAN `polite` package (`bow()`/`scrape()`/`nod()`) implements a similar idea with built-in
`robots.txt` and crawl-delay handling. It was not adopted here (2026-10-24): none of the three
existing skills used it, it does not cover the JSON-API case (`social-research-search`), and
swapping the transport under three already-tested skills in one pass was judged riskier than
extracting the pattern that was actually there. Revisit if a future skill needs real
`robots.txt`-driven crawl-delay compliance, not just the bot-wall/JS-rendered heuristic below.

## Contracts

- `pf_user_agent(skill, purpose, version = "0.1")` -> character(1). Pure string formatting, no
  I/O. Existing callers keep their historical literal strings where changing them would alter an
  identity already seen by remote servers; new callers should use this builder.
- `pf_host(url)` -> character(1), lower-cased host. No I/O.
- `pf_wait(host, min_interval = 1.5, state = .pf_state)` -> `invisible(NULL)`, side effect only
  (`Sys.sleep`, updates `state[[host]]`). Pass your own `new.env()` for isolation (e.g. tests);
  the shared default `.pf_state` is intentionally global for the R session, so two skills hitting
  the same host in one session still throttle each other.
- `pf_perform(url, ua, timeout = 25, max_tries = 2, retry_on = c(429L,502L,503L,504L), query = list())`
  -> `list(response, error)`. Never throws. Exactly one of `response`/`error` is non-`NULL`.
- `pf_fetch_html(url, ua, min_interval = 1.5, timeout = 25, max_tries = 2, retry_on = c(429L,502L,503L,504L), state = .pf_state)`
  -> `list(url, status, http, content_type, html, doc, problem)`. `status` is `"ok"`,
  `"http_error"` (HTTP >= 400) or `"error"` (request failed before a response). `html` is the raw
  body string (`NA_character_` when not HTML/XML) -- callers that need their own `xml2::read_html()`
  calls on the raw string (as `recipe-notes-formatter` does) can still do so; `doc` is the already
  parsed document, provided so callers that only need parsing do not have to parse twice.
- `pf_blocked_text(text, max_chars = 3000)` -> logical(1). Phrase heuristic on the start of the
  visible text only; a page can still be blocked without matching (treat a `FALSE` as "no evidence
  found", not "definitely not blocked").
- `pf_js_suspect(text_chars, n_scripts, n_anchors, min_anchors = 8, min_chars = 800, min_scripts = 5)`
  -> logical(1). Pure arithmetic on numbers the caller already computed from its own parsed page
  (anchor count, visible-text length, `<script>` count) -- this function does not parse anything
  itself, so callers with a different notion of "anchor" (e.g. a non-job-listing page) pass their
  own counts.
- `pf_tables(doc)` -> `list` of data frames (possibly empty). Thin wrapper, no retry or state.
- `pf_failure_class(resp = NULL, err = NULL)` -> one of `ok`, `challenge`, `forbidden`, `not_found`, `transient`,
  `client_error`, `network`. A challenge (header `cf-mitigated: challenge`, or a body naming a bot wall) wins over a plain 403.
- `pf_ua_compat(ua)` -> the same identity as `ua` in the `Mozilla/5.0 (compatible; <tool>/<ver>; <purpose>)` form some WAF rules
  require (checked 2026-11-23: a research portal answered 403 to the plain form and 200 to this one). It names the tool; it does not
  imitate a browser.
- `pf_url_variants(url, max_n = 3)` -> data frame `label`, `url`: language subdomain or path segment dropped, `www` toggled, http upgraded,
  trailing slash toggled; queries untouched.
- `pf_fetch_ladder(url, ua, timeout = 25, retry_on, min_interval = 1.5, max_variants = 3, state, learned)` -> `list(response, error,
  url_used, route, failure_class, attempts, ok)`. At most 1 + 1 + `max_variants` requests, each rate-limited. A challenge stops it; a 404
  tries only the language-neutral variants. `learned` remembers per host that the compatible user agent works. Callers keep their own
  status mapping (job-opportunity-watch maps `challenge`/`forbidden` to `blocked`).
- `pf_render_html(url, ua, wait_max = 10, settle = 2, allow = NULL)` -> `list(ok, html, note, blocked)`. Needs `chromote` and a Chrome
  install, otherwise `ok = FALSE` with the reason. Images, fonts and media are never loaded; `allow(url)` is called for every page, XHR
  and fetch request and a `FALSE` cancels it. A rendered bot wall is reported, not bypassed. Not for logins or pages needing a click.

## Heuristic thresholds and where they came from

`pf_blocked_text()`'s phrase list and `pf_js_suspect()`'s defaults (`min_anchors = 8`,
`min_chars = 800`, `min_scripts = 5`) are exactly the ones tested against real job-portal pages in
`job-opportunity-watch` (see that skill's own history). They were not re-validated against recipe
pages or arbitrary one-off scraping targets -- a page with legitimately few links (e.g. a single
recipe) could trip the thin-content heuristic. Callers for whom these defaults are a poor fit
should override the threshold arguments rather than add a second heuristic elsewhere.

## Changing this file

Any change to a function's signature or return shape needs a pass over all three dependent
skills' scripts before it ships, not just this skill's own description. `grep -rn "pf_"
job-opportunity-watch recipe-notes-formatter social-research-search` from the repo root finds
every call site.
