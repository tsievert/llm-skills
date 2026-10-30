# R workflow: openalexR + httr2

## Contents

- [openalexR for standard fields](#openalexr-for-standard-fields)
- [Batch ID/DOI lookups](#batch-iddoi-lookups)
- [`group_by` for topic clustering](#group_by-for-topic-clustering)
- [Detecting conference papers / paratext — no reliable signal](#detecting-conference-papers--paratext--no-reliable-signal)
- [Deduplication](#deduplication)
- [Known field quirks](#known-field-quirks)

Use this path when the MCP tools don't fit — bulk pagination combined with
local regex/dplyr filtering, a kept/reproducible script, custom joins across
several fetches, or fields the MCP tools don't expose.

## openalexR for standard fields

`oa_fetch()` auto-paginates and returns a tidy tibble with abstracts already
reconstructed from the inverted index (no manual unpacking needed).
`oa_snowball()` builds citation networks (works citing/cited by a set of
works) in one call.

```r
library(openalexR)

citing <- oa_fetch(
  entity = "works",
  cites = "W4223422326",
  options = list(select = c("id", "display_name", "publication_year",
                             "primary_location", "abstract_inverted_index")),
  verbose = TRUE
)
```

`openalexR` is **read-only** (GET only). For anything that creates, edits, or
deletes resources on the user's account — saved searches, alerts
(`POST`/`PATCH`/`DELETE /saved-searches`) — use `httr2` directly, since
`openalexR` has no wrapper for these endpoints.

### Gotcha: `oa_fetch()`'s custom `select` silently drops unmapped fields

`oa_fetch()` only exposes fields it has a built-in column mapping for. Ask
for `primary_topic`, `type`, `is_paratext`, or `doi` alongside other fields
and the returned tibble comes back **without those columns and no error** —
easy to miss. For anything outside openalexR's standard field set, call the
REST API directly with `httr2` and parse the JSON yourself:

```r
library(httr2)
library(purrr)

get_all_works <- function(filter_str, select_str) {
  out <- list()
  cursor <- "*"
  repeat {
    resp <- request("https://api.openalex.org/works") |>
      req_url_query(filter = filter_str, select = select_str,
                    cursor = cursor, `per-page` = 200) |>
      req_url_query(api_key = Sys.getenv("OPENALEX_API_KEY")) |>
      req_perform() |>
      resp_body_json()
    out <- c(out, resp$results)
    cursor <- resp$meta$next_cursor
    if (is.null(cursor) || length(resp$results) == 0) break
  }
  out
}

raw_works <- get_all_works("cites:W4223422326",
                            "id,display_name,publication_year,primary_topic,type,is_paratext,doi")

type_name <- map_chr(raw_works, function(x) if (is.null(x$type)) NA_character_ else x$type)
topic_name <- map_chr(raw_works, function(x) if (is.null(x$primary_topic)) NA_character_ else x$primary_topic$display_name)
```

Raw `abstract_inverted_index` (word -> positions) is not text. Rebuild it when using `httr2`
(`openalexR::oa_fetch()` already does this):

```r
abstract_text <- function(idx) {
  if (is.null(idx) || length(idx) == 0) return(NA_character_)
  words <- rep(names(idx), lengths(idx))
  paste(words[order(unlist(idx))], collapse = " ")
}
```

## Batch ID/DOI lookups

Fetch metadata for a known list of work IDs with one filtered request rather
than looping `GET /works/{id}`:

```r
ids <- c("W4225854610", "W4317419720", "W4389001889")
meta <- get_all_works(paste0("ids.openalex:", paste(ids, collapse = "|")),
                       "id,display_name,type,is_paratext,doi")
```

Same pattern for DOIs: `filter=doi:10.1234/a|10.1234/b|10.1234/c` (up to ~50
per request).

## `group_by` for topic clustering

`group_by=primary_topic.id` (or `primary_location.source.id`, `type`, etc.)
surfaces systematic clusters in one call — faster and more reliable than
scanning titles for finding noise or coverage gaps. Via raw `httr2`:

```r
resp <- request("https://api.openalex.org/works") |>
  req_url_query(filter = "cites:W4223422326", group_by = "primary_topic.id") |>
  req_url_query(api_key = Sys.getenv("OPENALEX_API_KEY")) |>
  req_perform() |>
  resp_body_json()

topic_counts <- do.call(rbind, lapply(resp$group_by, function(x)
  data.frame(key = x$key, name = x$key_display_name, count = x$count)))
```

Always sample a handful of works from a suspicious cluster before excluding
it — some clusters are genuinely mixed (e.g. a broad "marine animal" topic
containing both irrelevant and relevant work).

## Detecting conference papers / paratext — no reliable signal

Neither `is_paratext` nor page-range length (`biblio$first_page`/
`last_page`) reliably separates a true abstract-only submission from a
short-but-complete conference paper. `is_paratext` stays `FALSE` even for a
2-page conference paper, and a 6-page and a 2-page conference paper can both
be legitimate full papers at their venue. `type == "conference-paper"` is the
best available filter for "exclude conference papers," but it removes *all*
proceedings papers, not just abstract-only ones — say so when applying it,
rather than presenting it as a precise filter.

## Deduplication

`cites:`/`cited_by:` result sets can include both a preprint and its later
published version as two separate OpenAlex works citing the same seed paper.
Check for duplicate titles before finalizing any list built this way:

```r
type_df |> count(display_name) |> filter(n > 1)
```

Keep the published version (journal/conference `type == "article"`, not
`"preprint"`) unless the user wants the preprint specifically.

## Known field quirks

- `search=` is stemmed and does not support wildcards.
  `title_and_abstract.search.exact` supports full boolean syntax (`AND`/`OR`/
  `NOT`, parentheses, quoted phrases) plus wildcards (`*`, `?`, minimum 3
  literal characters before a wildcard, no leading wildcards).
- Wildcards need an exact (unstemmed) field. `title.search:workflow*` returns HTTP 400; the API's message says so, but httr2 shows
  only "HTTP 400 Bad Request" by default. To read it, use `req_error(is_error = \(r) FALSE)` and print `resp_body_string(resp)`.
  Checked live 2026-10-23: `title_and_abstract.search.exact` with parenthesised AND groups and a wildcard, and a wildcard inside
  quotes, both returned 200; a report of 400 for unquoted exact+boolean+wildcard was not reproduced. Boolean groups with `OR`/`AND`
  also work in the non-exact `title_and_abstract.search` and `title.search` (no wildcards there).
- OpenAlex's `type` and `is_paratext` fields are coarse — see conference
  papers above.

## Finding use cases among citing works

- `filter=cites:<W-id>,fulltext.search:<term>` returns citing works whose full text mentions the term; page with `cursor` to get all.
  A full-text mention is not proof of use (reference lists and background text match), and some works lack abstracts, so read the
  methods before claiming a paper used the method.
