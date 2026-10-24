---
name: job-opportunity-watch
description: 'Periodically checks a user-maintained list of job portals and search links for new career opportunities (academic and research jobs, postdocs, fellowship hosts, expert rosters), diffs them against what was seen on earlier runs, verifies and classifies each new candidate against a user profile, and keeps a persistent state so only new or changed items are reported. May propose (and, after confirmation, apply) additions to the links file and profile. Use when the user asks to check, scan, refresh or update job listings, vacancies, postdocs, positions or opportunities, mentions links.txt or a job profile, or asks whether a periodic job check is due.'
compatibility: Requires R with httr2, rvest, xml2, readr, yaml and internet access; the fetch mechanics come from the web-fetching-r skill (load it first), and optional social discovery needs the social-research-search skill. Read-only towards job sites (polite, no logins). The user's links file and profile are personal and stay outside the skill repo.
---

# Job opportunity watch

Find, verify, classify and rank career opportunities against the user's profile, **run after run**.
A one-shot "check every link" prompt degrades over time because it has no memory, re-reads the same
pages, and trusts the model to count and to claim verification. This skill therefore splits the work:

| Step | Who does it | Why |
|---|---|---|
| Parse links, fetch pages, extract links, diff vs. earlier runs, coverage audit | `scripts/jobwatch.R` (no model) | Counting, deduplication and "was it seen before" must be exact and repeatable |
| Read new candidates, open vacancy pages, extract facts, classify A-E | The assistant | Needs judgement and reading |
| Change the links file or the profile | The assistant proposes, **the user confirms** | The inputs are the user's; silent drift is how earlier setups went wrong |

## Where this skill runs

Locally, on the user's computer. Nothing is submitted to any site; no accounts, logins or applications.
Pages behind a bot wall, login or CAPTCHA are recorded as blocked and are not bypassed.

## Step 0: locate the data folder and check what is due

1. Data folder = the folder holding `links.csv`, `job_profile.yml` and `state/` (default `job-watch/` in
   the project; the user may name another). Set `options(jobwatch.dir = "<folder>")`. If the user's memory
   file does not record the folder, ask once and offer to note it there. Files layout:
   [references/state-and-files.md](references/state-and-files.md). Missing files: offer to start from
   `assets/links.template.csv` and `assets/job_profile.template.yml`, filled in with the user. A legacy
   `links.txt` still works; offer the one-time `jw_convert_links_txt(confirmed = TRUE)` (the `.txt` stays).
   A profile saved as `.txt` is YAML: suggest renaming it to `job_profile.yml`.
2. Load the **`web-fetching-r`** skill and `source("<web-fetching-r skill-dir>/scripts/polite_fetch.R")`
   first -- `jobwatch.R` needs its `pf_*` fetch helpers and will stop with a clear message if they are
   missing. Then `source("<skill-dir>/scripts/jobwatch.R")`, then `jw_due(every_days = 7)`. If a run is
   not due, say so and ask whether to run anyway; otherwise continue.
3. Read the profile with `yaml::read_yaml()` and restate in three or four lines the hard requirements and
   exclusions you will apply (contract, FTE, geography, excluded titles and systems). If something needed
   is unknown, use a clearly labelled provisional assumption and continue; ask only when an answer is
   essential for a specific item. Do not interview the user before probing.

## Step 1: parse and probe (every link, mechanically)

```r
links <- jw_read_links()                      # raw/unique counts, sections, duplicates, search-engine URLs
run   <- jw_probe(links, profile = prof)      # polite: one request at a time, 1.5 s per host
res   <- jw_save_run(run)                     # updates state/, returns review queue + audit
res$audit                                     # raw, unique, duplicates, checked, by_status, complete
```

A full run of about 100 links takes 1-2 minutes. `res$audit$complete` must be `TRUE` before saying the
sources were covered; otherwise list `missing_ledger_numbers` and re-probe those. Report the audit in
two lines (raw, unique, duplicates, checked, status counts). Source statuses:
`ok`, `ok_js_suspect` (listing probably rendered by JavaScript, see below), `blocked`, `http_error`,
`error`, `non_html`, `search_engine`.

Handling what the script cannot read (record every attempt, continue; never stop the run for one link):

- **`ok_js_suspect` and `blocked` sources:** try the `webfetch` tool once. If still empty, mark the source
  as "needs manual check" in the report and do not claim it was checked. Sources that stay in this state
  for several runs are candidates for replacement (Step 5).
- **`search_engine` links** (Google and similar): not fetchable. The script returns the decoded query;
  run it (without operators the search tool ignores) through `web_search`. The time filter in the URL
  (e.g. last week) is lost, so check dates in results.
- **`http_error` (404, 410, 5xx) / `error` (DNS, timeout):** retry once at the end of the run (503 and
  timeouts are often transient). If it still fails, look for the moved page, in this order:
  1. `jw_find_replacement(url)`: tries parent paths, the site's sitemaps (robots.txt `Sitemap:` lines and
     common names) and job-like links on the home page; returns scored candidates that answer with
     HTTP < 400. Tested on a moved page (found the new listing address in the sitemap) and on a host that
     did not resolve (found nothing, as it should).
  2. If that gives nothing usable: `web_search` for the employer's name plus "vacancies" or "jobs" in the
     local language, and prefer a result on the same domain; use `webfetch` on the employer's home page.
  3. Probe the best candidate with `jw_probe_one()`; check that it lists vacancies (not a single job, a
     news item or a different department). A DNS failure on every candidate suggests your network, not
     the site: say so instead of replacing the link.
  Propose the replacement in Step 5 with the evidence (old URL status, where the new one was found); do
  not edit silently, and keep the old link until the user agrees.

## Step 2: triage the review queue

`res$queue` holds anchors not seen on earlier runs, minus excluded titles (PhD, technician, full professor
and the profile's excluded titles). Tier 1 = topic words in the title; tier 2 = job-like title only.
The first run is a baseline and the queue is large (about 1,000 titles for 100 portals); later runs are
small.

- Read all tier-1 titles. For tier 2, scan titles in bulk and open only those that could plausibly fit; say
  how many were skimmed. Titles are a weak signal: "Researcher" or "Postdoc" with the species only in the
  description will be missed, and the word filter is multilingual only in part
  ([references/portal-quirks.md](references/portal-quirks.md)). Reject on central duties, not isolated words.
- Titles that are just category pages or the same vacancy listed on several portals are duplicates:
  count one underlying opportunity once (employer, title, reference number, deadline) and cross-reference.

## Step 3: verify and classify each shortlisted opportunity

For each: open the vacancy (follow redirects; search the employer site if the page is generic, moved or
expired), extract the fields, assign class A-E and **one final status**. Details, field list, status
vocabulary, opportunity tracks and default rules:
[references/classification.md](references/classification.md). Key rules:

- The profile file decides; the defaults in the reference apply only where the profile is silent.
- Assess scientific, method, eligibility, contract, geographic fit and strategic value separately; do not
  fold a weak dimension into one score or invent precision where facts are missing.
- A live page does not prove applications are open. Conflicting sources: keep both claims, prefer the
  stronger source, label the conflict. Never claim verification when access failed.
- Keep primary employment, fellowship hosts and supplementary opportunities (rosters, panels, networks)
  separate; never rank unpaid items against salaried employment.

Record results with `jw_opp_upsert()` (columns in the reference) and run `jw_opp_expire()` so passed
deadlines are marked. Already-known open opportunities are not re-reported unless something changed.

## Step 4: report

Lead with what is new since the last run, then deadlines within about 14 days, then source health. Chat
output is short; the full ledger lives in `state/opportunities.tsv`.

1. Audit line (links raw/unique/duplicates/checked/complete; sources needing manual check).
2. Primary employment: new items, class D/E first, each with employer, title, country, deadline, contract,
   final status, one line on why and one on the weakest dimension, and the link.
3. Fellowship hosts, then supplementary opportunities (separate lists).
4. Class A/B items as one-line rejections or open questions (only those the user might disagree with).
5. Limitations: what was not readable, assumptions made, facts versus inference.

Only after supplied links are processed, and only when asked, run additional discovery searches
(species, mechanisms, local-language terms, institutions, early signals); aggregators are for discovery,
not final evidence. Social-media discovery (Bluesky, Mastodon) is Step 4b and uses the `social-research-search` skill.

## Step 4b: social discovery and the tag ledger

Only when asked for discovery (after the supplied links are processed), or when the user wants early
signals (advertised positions, "looking for a postdoc" posts, group announcements). Use the
**`social-research-search`** skill for the searching itself (load it; its helper `bsky_search()`,
`masto_tag()` and `social_search()` are keyless and read-only; follow its pitfalls and privacy notes: link
posts, do not profile individuals). Social posts are leads, never final evidence: every opportunity found
this way goes through Step 3 on the employer's own page.

**Maintain a ledger of hashtags (by platform) that proved useful**, in `state/social_tags.tsv`
(columns in [references/state-and-files.md](references/state-and-files.md)). This is mandatory, not optional:

1. Before searching, `jw_tags_read()`. Search first with `keep` tags, then `candidate` tags; do not use
   `retired` ones. Hashtags are for Mastodon (`masto_tag`); on Bluesky use text search and the `tag` filter,
   and record the term or tag you actually used, with `platform = "bluesky"`.
2. Add at most a few new candidate tags per run, drawn from what you saw (co-occurring tags on relevant posts,
   field and language variants). Do not invent tags that no post uses.
3. After screening, `jw_tags_record(platform, tag, hits = <posts judged job-relevant>, useful = <of those,
   how many led to a verified opportunity or a link the user accepted>)`. Count honestly; zero is a valid result.
4. At the end of the run, `jw_tags_review()` lists suggested status changes (keep after a useful hit; retire after
   several runs with none). **Propose them to the user; apply only with `jw_tags_set_status(..., confirmed = TRUE)`.**
   Never delete rows; retired tags stay so they are not rediscovered and retried.
5. Report the ledger changes in one line in Step 4 (new candidates, suggested keeps/retirements).

Why a ledger: tag usefulness drifts (communities move platforms, tags get spammed), and without a record the
same unproductive searches get repeated. The counts are small, so treat them as a rough guide, not a ranking.

## Step 5: maintain the links file and the profile (propose, then confirm)

Propose changes when you have evidence: a vacancy page links to a portal the file lacks, an official
page replaces a dead or moved one, a source failed three or more runs (`jw_source_health()`), a source
never yields tier-1 hits over many runs, or the user's reaction shows the profile is wrong (e.g. "I would
take this" for a class A item). Protocol and examples:
[references/maintaining-links-and-profile.md](references/maintaining-links-and-profile.md).

- Show the exact change (new line and section, or a profile diff) and the evidence, ask with `AskUser`.
- Apply only after a yes: `jw_add_link(url, section, confirmed = TRUE)`, `jw_replace_link(old, new,
  confirmed = TRUE)` (the old row stays with `enabled = FALSE`, the new row records `replaces`) or
  `jw_write_confirmed()` for the profile; all write a timestamped backup first and refuse without
  `confirmed = TRUE`. Never delete user links; propose retiring or replacing and let the user decide.
  Bump `profile_version` when the profile changes.

## Periodic use

The assistant cannot wake itself. Options, to be offered, not installed without a yes: ask for a check at
the start of a session (`jw_due()`); run the model-free probe on a schedule with
`Rscript scripts/run_probe.R <data-folder>` (writes `digests/<date>.md`, updates `state/`, so the next
conversation starts from a digest); or a `SessionStart` hook that prints a reminder when `jw_due()` is
true (check the hooks docs first, and note hooks cost start-up time).

## Politeness and limits

One request at a time, 1.5 s between requests to a host, identifying user agent, no logins, no bypassing
bot walls, nothing submitted. Respect a site's terms; if a portal offers an RSS feed or API, prefer it
(propose it in Step 5). The word filters are heuristics: they decide what the assistant reads first, not
what is relevant. Findings are as current as the last successful probe.

## Related skills

- `web-fetching-r`: the shared polite-fetch mechanics (`pf_*`) this skill's `jobwatch.R` sources;
  for the one-off, non-recurring "pull a table off a page" case instead, use that skill directly.
- `social-research-search`: social discovery (Step 4b) with the tag ledger.
- `openalex`: checking a group or PI publication record when judging scientific fit.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were done or not done: why this method, setting or tool was chosen, which alternative was rejected and why, which check or step was skipped, and which assumptions were made. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a package version or API differs from what it states, or it lacks guidance the task needs, record a generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
