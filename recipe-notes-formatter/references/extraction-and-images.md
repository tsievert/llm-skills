# Extraction and pictures

How a recipe is read from a web page, how a picture is chosen, and what was tested. Tests: 2026-10-24, Windows,
R 4.6.0, against two real pages the user had saved recipes from.

## Contents

- The three tiers
- What the tests showed
- Tier 3: reading a page without recipe markup
- Pictures for a link
- Pictures for an existing note
- Rights and politeness
- Why R and not recipe-scrapers

## The three tiers

| Tier | Source | Function | Trust |
|---|---|---|---|
| 1 | JSON-LD `Recipe` (also inside `@graph`, arrays, nested objects) | `rn_extract_recipe()` | High, but check flags |
| 2 | Microdata (`itemprop` attributes) | same call, `tier = "microdata"` | Medium: times and servings are not read |
| 3 | Visible page text | `x$page_text` (tier `none`), structured by the assistant | Lower: say so in the report |

Reading rules built into the code:

- Strings are decoded (`&amp;`), whitespace collapsed. `recipeYield` gives `servings` (first number) and the raw
  text. `totalTime`, or `prepTime` plus `cookTime`, becomes minutes (ISO 8601 such as `PT1H15M`).
- `recipeInstructions` may be plain text, `HowToStep` objects or `HowToSection` groups; groups are kept.
- A JSON-LD block with raw newlines inside strings (a real failure of other tools) is repaired and re-parsed.
- Ingredient lines that look like a group heading (no digit, at most four words, followed by a line with a
  quantity) are reported as `heading_candidates`. They are only candidates: "Salt" has no digit either, so the
  assistant or user confirms, then `rn_apply_headings(x, idx)` builds the groups and splits flat directions at the
  same headings.

## What the tests showed

| Page | Result |
|---|---|
| koket.se (Swedish recipe site) | Tier 1. Title, 25 servings, 240 minutes, language `sv`, author and image all read. The four ingredient groups were found as heading candidates and the flat step list split correctly. The page has changed since the user's note was saved (some wording differs), which is normal for live sites |
| chocochili.net (Finnish blog) | Tier `none`: the page has JSON-LD for the site and breadcrumbs but no `Recipe`. `page_text` contained the recipe cleanly (title, "4 annosta", ingredient list, steps) followed by 80 comments. `og:image` gave the picture |
| Synthetic pages | `@graph`, `@type` as array, image as list of objects, `HowToSection`, raw-newline JSON, microdata, no markup |

Comparison made before writing the code: `recipe-scrapers` 15.13.0 read koket.se well but put the group headings into
`ingredients()` and `instructions_list()` as if they were items, `ingredient_groups()` returned one unnamed group, and
it raised `NoSchemaFoundInWildMode` on the Finnish blog. The R code reports the same headings as candidates and falls
back to page text instead of failing.

## Tier 3: reading a page without recipe markup

1. `x$page_text` is the article text without navigation, scripts and footers (comments stay in; ignore them).
2. Find the title, servings text, ingredient lines and steps. Copy ingredient and step wording exactly; do not
   translate, shorten or "improve" it.
3. Servings: only if the page states a number. Time: only if stated.
4. Mark the recipe as lower confidence and list what you inferred (for example "ingredients are the lines between the
   servings line and the first sentence").
5. Take the picture from `x$image_candidates` (`og:image`).

## Pictures for a link

`x$image_candidates` is ordered: JSON-LD image(s), `og:image`, `twitter:image`, `image_src`, absolute URLs. Take the
first; if the download fails (status, content type, size above 8 MB) try the next and say so.
`rn_download_image()` accepts jpeg, png, webp, gif and avif only, never overwrites (numbered name) and returns the
file name and MD5 for the report.

## Pictures for an existing note

The user's rule: match the recipe to something online and use its picture.

1. Skip notes that already have a picture; do not replace it.
2. If the note has a `source` URL, read that page first (`rn_fetch_html`, `rn_extract_recipe`).
3. Otherwise search with `web_search`: title plus two or three distinctive ingredients, in the note's language, plus
   the word for "recipe" (Rezept, resepti, recept). Open the top three pages.
4. Score each page with `rn_ingredient_overlap(note_ingredients, page$ingredients)`: the share of the note's
   ingredient words found on the page. Accept at **0.6 or more**; the threshold is a screen, not proof, so the report
   shows the score and the URL and the user can overrule it. Below 0.6: no picture, flag it.
5. A different language page scores low by design; search again in the note's language rather than lowering the bar.
6. Record page URL, image URL and score in the report and in the hidden `%%Photo: ...%%` line.

Not tested: the search step on real notes (the scoring function is tested on synthetic ingredient lists).

## Rights and politeness

- Ingredient lists are generally not protected by copyright; descriptions, directions in an author's own words and
  photographs are. Many authors allow a photo with a credit and a link back; some forbid reuse. This is general web
  guidance, not legal advice. The skill keeps `source` and the credit line with every picture and says this once in
  the report; the user decides whether to keep downloaded pictures.
- One request at a time, 1.5 seconds apart, an identifying user agent, no logins, no bot-wall workarounds, nothing
  submitted. A page that blocks the request is reported as blocked.

## Why R and not recipe-scrapers

The user's project is an R project, the needed parsing is small (JSON-LD with `jsonlite`, HTML with `xml2` and `rvest`),
and the two tools disagree on group headings anyway. `recipe-scrapers` (Python, 300+ site parsers) remains an option if
many pages from one supported site are processed; it would need `uv` or `reticulate`, which this skill does not use.
The CRAN check on 2026-10-24 found no recipe-scraping package (`jsonld` is a general JSON-LD processor and was not needed).
