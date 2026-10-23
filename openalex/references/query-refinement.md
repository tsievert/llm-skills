# Query refinement and citing-works screening

## Contents

- [General query refinement workflow](#general-query-refinement-workflow)
- [Screening a citing-works list for a topical subset](#screening-a-citing-works-list-for-a-topical-subset)

Lessons learned building literature-search queries and screening citing-works
lists against the live OpenAlex API. Applies whether querying via the MCP
tools (`keyword_search`, `find_keywords`, `group_works`) or raw R/httr2.

## General query refinement workflow

When building or refining a search query (especially a recurring alert),
don't stop at eyeballing a handful of sample titles — use these techniques,
roughly in order of effort:

- **`group_by` (or the `group_works` MCP tool) beats manually scanning
  titles for finding systematic noise.** Grouping matches by
  `primary_topic.id` (or `primary_location.source.id`, `type`, etc.) surfaces
  large false-positive *clusters* in one call — e.g. a query for animal
  "predator-prey" behavior picked up thousands of papers classified under
  "Mathematical and Theoretical Epidemiology and Ecology Models" (pure
  Lotka-Volterra math, zero biology) and under forensic psychiatry (human
  "sexual predator" literature) that word-frequency scanning of a few hundred
  titles never would have surfaced at the right scale. Always sample a
  handful of works from a suspicious cluster before excluding it, since some
  clusters are genuinely mixed (e.g. a "marine animal" topic can contain both
  irrelevant fish/crustacean papers and relevant real marine-mammal papers).
- **Topic-level and publisher-level exclusion filters complement keyword
  exclusion, they don't replace it.** `primary_topic.id:!T123` and
  `primary_location.source.host_organization_lineage:!P123` (publisher, e.g.
  to exclude all of a predatory/low-quality publisher like MDPI) rely on
  OpenAlex's own classification rather than string matching, so they catch
  false positives that bypass keyword `NOT` lists entirely (e.g. a paper
  about a specific bird or insect species named only by common/Latin name,
  with no generic word like "bird" or "insect" anywhere for a keyword filter
  to catch).
- **Wildcards can collide with unrelated words in other languages.** A short
  wildcarded root can silently match foreign-language words sharing the same
  prefix — `vole*` (intended for "vole"/"voles") also matched Czech
  "volební" (electoral) and Spanish "voleibol" (volleyball), surviving even
  an `AND behavior*` requirement because bilingual abstracts often repeat the
  English keyword in parentheses. If a wildcarded root is short (under ~6
  characters) or a common letter sequence, compare counts for the wildcard
  vs. the literal word(s) it's meant to stand in for before trusting it.
- **For a narrow/niche research area, citation-lineage tracking
  (`cites:`/`cited_by:`, or `list_citations`/`oa_snowball()`) can outperform
  keyword search entirely.** When keyword guessing for a specific compound
  family or subfield kept returning noise, pulling the citing/cited works of
  one known seminal paper surfaced the real terminology used in that niche
  (e.g. an anchor phrase like "Grueneberg ganglion") far more reliably than
  guessing synonyms from memory.
- **Pull real abstracts rather than guessing specific terminology from
  memory**, even for things that feel like general domain knowledge (e.g.
  common compound names in a chemical family) — sampling actual abstracts in
  context finds the real terms used, and often shows memory-recalled guesses
  weren't actually present in the retrieved literature. `find_keywords` (MCP)
  does this directly: it returns the real OpenAlex keywords for a topic plus
  how many works carry each.
- Before finalizing a recurring alert, always check: total matches, matches
  in the last 30/90 days (to gauge actual email volume), and a sample of the
  most recent matches (not just top-relevance matches) for noise.

## Screening a citing-works list for a topical subset

When filtering a citing-works list (`cites:W123...`) down to a topical
subset — e.g. finding which papers citing a seminal method paper are about a
specific set of species, industries, or application domains:

- **Keyword lists need both specific names and the category's umbrella
  term.** A pattern listing individual species/items by name will miss
  papers that only ever use the collective noun (e.g. "livestock" instead of
  naming pigs, cattle, or poultry specifically) — add the umbrella term
  alongside specific names, then check whether its hits are genuinely on
  topic or just incidental mentions in an unrelated paper's introduction
  (e.g. a paper on an unrelated species that only name-drops the umbrella
  term as one example application).
- **Short, common English words make risky keywords — test them against the
  actual corpus before trusting them.** A plural/singular variant of a
  common English word that also has an unrelated technical meaning in the
  field (e.g. "layer" meaning both a laying hen and a neural-network layer in
  computer-vision papers) will produce mostly false positives if added on
  its own; only add it as part of a longer, more specific phrase.
- **Topic-based (`group_by=primary_topic.id` / `group_works`) and keyword
  screening catch different false negatives, so run both.** Keyword
  screening misses every paper using only an umbrella/collective term rather
  than a specific name; topic clustering surfaces those immediately, plus
  occasionally papers in topic clusters using an uncommon term the keyword
  list hadn't anticipated.
- **Re-run keyword screening after each round of fixes and diff the hit list
  against the previous round**, rather than re-reading the whole list, to see
  exactly what a pattern change added or removed.
- **To batch-fetch metadata for a known list of work IDs, use
  `filter=ids.openalex:ID1|ID2|ID3`** (pipe-separated, in one request) rather
  than looping one `GET /works/{id}` call per ID.
- **`type == "conference-paper"` is the best available filter for "exclude
  conference papers," but it isn't precise** — OpenAlex doesn't reliably
  distinguish a true abstract-only submission from a short full conference
  paper (`is_paratext` and page-range length are both unreliable signals).
  Flag to the user that this filter removes all proceedings papers, not just
  abstract-only ones.
- **Check for duplicate works (preprint + published version of the same
  study) by title before presenting a final list** — `cites:` results can
  include both a preprint record and its later journal-published counterpart
  as two separate OpenAlex works citing the same seed paper.
