# Data folder, file formats and state

Contents: layout; links file format; profile; state files; privacy; helper functions.

## Layout

```
<data-folder>/              default job-watch/ in the project; never committed
  links.csv                 the user's portals and searches (legacy: links.txt)
  job_profile.yml           the user's profile (YAML)
  state/
    sources.tsv             one row per unique link: status, hash, consecutive failures
    anchors_seen.tsv        every candidate link ever seen, with first_seen
    opportunities.tsv       verified opportunities (written by the assistant)
    runs.tsv                one row per run: counts for the audit trail
    social_tags.tsv         hashtag/search-term ledger per platform (Step 4b of SKILL.md)
  digests/<date>.md         output of the headless run
  *.bak-<timestamp>         backups made before any edit of links or profile
```

In this repo `job-watch/` and `tmp-examples/` are in `.gitignore`. The assistant's R session may only be
able to write inside the project folder; if the user keeps the data elsewhere and R is blocked, write the
files with the `write` tool or ask the user to copy them.

## links.csv

UTF-8 CSV, one row per link, columns `url, section, label, enabled, added, added_by, replaces, note`
(only `url` is required; `enabled` is `TRUE`/`FALSE`, blank means `TRUE`). Disabled rows are kept for
history (retired or replaced links, or links the user does not want suggested again) and are not probed.
Quote fields that contain commas. The user may edit it in a spreadsheet or text editor.

Why CSV and not plain text, JSON or SQLite: the skill must remember per-link facts (when and by whom a
link was added, what it replaced, whether it is retired) that a bare list cannot hold; JSON has no
comments and is awkward to hand-edit; a database is not human-readable. The profile stays YAML (nested
rules and comments) and should be named `job_profile.yml`.

Legacy `links.txt` (a URL per line, `#` comments, plain text lines as section labels) is still read;
`jw_convert_links_txt(confirmed = TRUE)` converts it once and leaves the `.txt` untouched; comment lines
become the `note` of the next link. Exact duplicates (ignoring `#fragment` and a trailing slash) are kept and marked as duplicates, never
dropped from the raw count. Google/Bing/DuckDuckGo search URLs are classified `search_engine`: they are
not fetched; their query is passed to `web_search`.

## Profile

YAML. The helpers read `career_search_profile$target_search$excluded_job_titles` (for the queue filter);
everything else is read by the assistant. See `assets/job_profile.template.yml` for the sections
(hard requirements, preferences, exclusions, geography, contract). Keep a `profile_version` date.
A profile file that ends mid-sentence still parses, but check it for truncation when first loaded.

## State columns

- `sources.tsv`: `id` (hash of the normalised URL, stable across edits), `n` (position in the current
  links file), `section`, `url`, `type`, `status`, `http`, `final_url`, `text_hash`, `n_anchors`, `note`,
  `last_checked`, `consec_fail`, `first_seen`, `changed` (page text hash differs from last run; noisy on
  dynamic pages, a hint only).
- `anchors_seen.tsv`: `source_id`, `text`, `href`, `role_hit`, `topic_hit`, `excluded`, `first_seen`.
  A candidate is new when its (source, href) pair was not seen before.
- `runs.tsv`: `finished`, `raw_links`, `unique_links`, `duplicates`, `checked`, status counts,
  `new_anchors`, `review_queue`.

## Privacy

The links file and profile describe the user's job search (location, citizenship, preferences). Keep
them out of any public repo, never paste them into lesson entries or issues, and do not copy them into
skill files.

## Functions (scripts/jobwatch.R)

`jw_read_links`, `jw_probe`, `jw_save_run`, `jw_audit`, `jw_due`, `jw_source_health`, `jw_opp_upsert`,
`jw_opp_expire`, `jw_add_link`, `jw_replace_link`, `jw_convert_links_txt`, `jw_find_replacement`,
`jw_write_confirmed`, `jw_headless`, `jw_tags_read`, `jw_tags_record`, `jw_tags_review`, `jw_tags_set_status`. Read the file header and the comments
above each function; they are short.

## social_tags.tsv

One row per (`platform`, `tag`); `platform` is `bluesky` or `mastodon`. Columns: `first_used`, `last_used`, `n_runs`,
`n_hits` (posts judged job-relevant), `n_useful` (of those, how many led to a verified opportunity or an accepted
link), `last_useful`, `status` (`candidate`, `keep`, `retired`), `note`. The assistant writes counts with
`jw_tags_record()`; status changes are proposed by `jw_tags_review()` and applied only after the user agrees
(`jw_tags_set_status(confirmed = TRUE)`, backup first). Retired rows are kept. No personal data about post authors
is stored.
