---
name: social-research-search
description: Searches public Bluesky posts and Mastodon/fediverse hashtag timelines without any API key, login, or payment, using a bundled R httr2 helper. Use when the user wants to see what researchers or the community are discussing about a package, method, tool, or topic (e.g. mgcv, gratia, rstats, DeepLabCut, Slurm) on Bluesky, Mastodon, or the fediverse, or asks to check social media for questions, pain points, or announcements. Does not cover X/Twitter, which has no free keyless access.
compatibility: Requires R with the httr2 package and internet access; the request/retry pipeline comes from the web-fetching-r skill (load it first). Read-only; no accounts or API keys.
---

# Social research search (Bluesky + Mastodon, keyless)

Read-only search of public posts. Use it to find real-world questions, workarounds, announcements and
sentiment around a tool or method, e.g. to see which problems users hit with a package before
updating a skill. Treat results as anecdotal leads, not evidence.

## Run the helper

```r
source("<web-fetching-r skill-dir>/scripts/polite_fetch.R")   # fetch mechanics; load that skill first
source("<skill-dir>/scripts/social_search.R")   # <skill-dir> = folder containing this SKILL.md

bsky_search("mgcv", sort = "latest", since = "2026-01-01", max_posts = 200)
masto_tag("mgcv", instances = c("mastodon.social", "fosstodon.org", "mstdn.science"))
social_search("gratia", tags = c("gratia", "rstats"))   # both platforms in one data frame
```

All functions return the same columns: `platform, source, created_at (UTC POSIXct), author, text, url,
likes, reposts, replies, lang, id`. Sort or filter the data frame yourself, e.g. by `likes`.

Keep queries to one or two words and filter dates locally (see Pitfalls). Print compactly, e.g.
`res |> dplyr::arrange(dplyr::desc(created_at)) |> dplyr::transmute(created_at, author, text = substr(text, 1, 150), url) |> head(20)`.

Show the user the `url` for every post you cite so they can verify it.

## Platform behaviour (tested 2026-10-23)

**Bluesky** (`api.bsky.app/xrpc/app.bsky.feed.searchPosts`)
- Works without login on the `api.bsky.app` host. `public.api.bsky.app` returned 403 for the same call.
- Full-text search over all public posts; `sort = "latest"` (newest first) or `"top"`.
- Max 100 posts per request. The `cursor` parameter returns 403 without login, so the helper pages by moving
  `until` backwards (needs `sort = "latest"`; `sort = "top"` gives one page of at most 100).
- Filters: `since`, `until`, `lang`, `tag` (hashtag, all must match), `author` (handle or DID).

**Mastodon** (`/api/v1/timelines/tag/:hashtag`)
- Public hashtag timelines work without login on the instances listed above (checked mastodon.social,
  fosstodon.org, mstdn.science). Other instances may return 401 if they disabled public preview;
  the helper warns and continues.
- Each instance only holds posts it has received through federation, so coverage differs per instance.
  Query several and let the helper de-duplicate by `uri`.
- Keyless full-text search is NOT available (`/api/v2/search?type=statuses` returned nothing without login).
  Only hashtags (and an account's timeline) work, so people who do not use hashtags are missed.
- Max 40 posts per request; the helper pages with `max_id`.

## Pitfalls

- **Ambiguous words.** "gratia" matches Latin phrases ("ars gratia artis", "exempli gratia"); "bam" and
  "gam" match everything. Combine with `tag = "rstats"` or screen results for context. Bluesky matching is
  fuzzy: in a test, a quoted phrase also returned posts without that phrase (apparently matched through
  related text such as link cards), so filter the `text` column yourself when exactness matters.
- **Multiword queries are AND-matched, and `since` shrinks them further.** Reproduced 2026-10-27: "postdoc
  mammals" gave 67 posts without `since` but 1 with `since` one month back; a four-word query gave 0; the
  single word "Verhaltensbiologie" gave 99 while "Postdoc Verhaltensbiologie Stelle" gave 0. Use at most two
  content words, fetch without `since`, and filter `created_at` and keywords on the data frame. For precision
  combine a short query with `author =` or `tag =` instead of adding words.
- **Non-English queries need single words.** Phrases in German, French, Dutch, Swedish or Finnish mostly return
  nothing. Search one word (e.g. a field term), then screen locally with job words in that language (Stelle,
  vacature, poste, tjänst, tutkijatohtori). Expect low yield: job posts are often link-only cards, or bot posts
  in English.
- **Job-bot accounts.** Some accounts post every vacancy as "<employer> is hiring: <title> #tags". Find them
  first (search "is hiring"), then query `bsky_search("hiring", author = <handle>, tag = <field tag>)`:
  author alone hits the 400-post cap, author + tag is small and repeatable. The bot picks the tags, so niche
  fields often only get generic ones, and yield per run can be near zero. The post is title-only: each lead
  needs a second step to find the employer page and deadline.
- **Mastodon job tags are saturated.** Broad tags (#jobs, #postdoc, #fedihire) return hundreds of unrelated
  posts; topic tags (#rodents, #olfaction) return science news and bot summaries, not vacancies. A useful tag
  needs both a job signal and a topic signal; field-specific job tags are low volume but cleaner.
- **Screen with a job-word AND a topic-word filter, and read the hits.** Single weak words ("chemical",
  "evolution", "animal", "behaviour") match chemistry, genomics and livestock posts, and "job|apply|position"
  matches politics and ranger jobs. Exclude the fields the user rules out and print only the matches.
- **Keep printed output small.** Select a few columns, `substr(text, 1, 150)` and `head()` before printing;
  100+ rows of long text flood the console and the conversation.
- **Hashtag mismatch.** Mastodon posts are tagged `#mgcv`, `#rstats`, `#GAM`; Bluesky users often skip tags,
  so use text search there and hashtags on Mastodon.
- **Bias.** Results over-represent people who post publicly and who use these platforms; small counts say
  little about prevalence. Likes and reposts reflect reach, not correctness.
- **Be polite.** The helper pauses 0.5 s between requests and retries on 429/5xx. Keep `max_posts` modest
  (a few hundred) and do not loop over many queries without need.
- **Privacy and quoting.** Public posts, but still personal. Summarise and link rather than quoting at
  length, and do not compile profiles of individuals.
- **If an endpoint changes** (403/404 warnings, empty results for a term that should match), check
  https://docs.bsky.app/ and https://docs.joinmastodon.org/methods/timelines/ before debugging the script.

## Other platforms

- **X/Twitter:** no free keyless access. Third-party free services and cookie-based scrapers exist but are
  rate-limited, fragile or risk account bans, so they are not bundled. Do not use them unless the user asks.
- **Other Mastodon-compatible servers** (Pleroma, Misskey) use different APIs and are not covered.

## Related skills

- `web-fetching-r`: the shared request/retry mechanics (`pf_perform()`) this skill's `social_search.R` sources; for general HTML page scraping instead of these two APIs, use that skill directly.
- `openalex`: literature search; use it for papers and citation data, not social posts.
- `job-opportunity-watch`: uses this skill for social discovery of positions and keeps a ledger of useful hashtags.

## Explain the reasoning (teaching rule)

Teach, don't replace the user's thinking: say briefly (a sentence or two) why things were or were not done, name the trade-off and which decision is the user's, and point to a reference for depth.

## Capture lessons (self-improvement rule)

Load the `skill-lessons` skill and append a generic, anonymised entry (no project data, IDs or paths) as soon as something unanticipated happens: an error or warning, advice or code that failed, a user correction, a version or API mismatch, missing guidance, or a recommendation that held up (`worked-well`). Also write one `use-case` entry per session. When unsure, record it with `generality: unsure`. Entries are hypotheses for `skill-feedback-triage`.
