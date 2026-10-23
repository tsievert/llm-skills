# Maintaining the links file and the profile

Contents: when to propose; how to propose; applying; what never to do.

## When to propose

Links file:

- A vacancy or portal page links to a relevant source the file lacks (employer career page, funder
  portal, society job board, RSS feed or API of a source already listed).
- A source returns 404 or redirects to a new address; the official new address was found on the same site.
- A source failed (`error`, `http_error`, `blocked`) three or more consecutive runs (`jw_source_health()`),
  or is `ok_js_suspect` every run: propose a replacement (an RSS feed, the employer's official page,
  a `web_search` query) or marking it as manual-check.
- A source produced no tier-1 candidate over many runs (say how many) while an alternative covers the
  same employers: propose removal, never remove on your own.
- A duplicate or near-duplicate source (same portal with different filters): mention, let the user choose.

Profile:

- The user rejects or accepts an item in a way that contradicts the profile (e.g. wants a class A item).
- A recurring stated preference ("I do not want X") not in the profile.
- A profile rule that produced wrong results, e.g. an exclusion hiding relevant jobs.
- Stale facts (a date, a location bonus) noticed in conversation.

Do not propose from a single ambiguous remark; ask a short question first.

## How to propose

One `AskUser` per change group, with: what changes (exact new line and section, or a diff of the profile
lines), the evidence (URL, run counts, the user's own words), and the effect (what will be searched or
classified differently). Options: apply, apply with edits, not now, never suggest this again. Record
"never suggest again" as a disabled row (`jw_add_link(url, section, enabled = FALSE, note = "never
suggest", confirmed = TRUE)`) so it persists and is not probed.

## Applying

```r
jw_add_link("https://example.org/jobs", section = "Finnland", label = "Example University",
            note = "official page linked from a vacancy", confirmed = TRUE)
jw_replace_link(old_url, new_url, note = "moved; found in sitemap", confirmed = TRUE)  # dead link
jw_write_confirmed(profile_path, new_text, confirmed = TRUE)   # profile: write the full new text
```

Both make a timestamped backup next to the file first. For the profile, edit the YAML text minimally
(keep the user's comments, order and wording), bump `profile_version`, re-read it with
`yaml::read_yaml()` to check it parses, and tell the user which backup to restore from if needed. Section
labels must match the existing label exactly or a new section is created at the end.

## Never

Edit either file without a yes for that exact change; delete links; change hard requirements to make an
item fit; add sources that need a login, are paywalled, or forbid automated access; copy the profile
into the skill or a repo.
