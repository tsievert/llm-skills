---
name: social-research-search
description: Searches public Bluesky posts and Mastodon/fediverse hashtag timelines without any API key, login, or payment, using a bundled R httr2 helper. Use when the user wants to see what researchers or the community are discussing about a package, method, tool, or topic (e.g. mgcv, gratia, rstats, DeepLabCut, Slurm) on Bluesky, Mastodon, or the fediverse, or asks to check social media for questions, pain points, or announcements. Does not cover X/Twitter, which has no free keyless access.
compatibility: Requires R with the httr2 package and internet access. Read-only; no accounts or API keys.
---

# Social research search (Bluesky + Mastodon, keyless)

Read-only search of public posts. Use it to find real-world questions, workarounds, announcements and
sentiment around a tool or method, e.g. to see which problems users hit with a package before
updating a skill. Treat results as anecdotal leads, not evidence.

## Run the helper

```r
source("<skill-dir>/scripts/social_search.R")   # <skill-dir> = folder containing this SKILL.md

bsky_search("mgcv", sort = "latest", since = "2026-01-01", max_posts = 200)
masto_tag("mgcv", instances = c("mastodon.social", "fosstodon.org", "mstdn.science"))
social_search("gratia", tags = c("gratia", "rstats"))   # both platforms in one data frame
```

All functions return the same columns: `platform, source, created_at (UTC POSIXct), author, text, url,
likes, reposts, replies, lang, id`. Sort or filter the data frame yourself, e.g. by `likes`.

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
