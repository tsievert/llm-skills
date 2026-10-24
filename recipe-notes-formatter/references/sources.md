# Sources

Everything the skill is based on, with what was read and when. Research log with all rows and test results:
`research/recipe-notes-ledger.md` in the llm-skills repo. Check the live pages before relying on a detail: plugin
behaviour and site markup change.

## Contents

- Obsidian and its plugins
- Upstream skills to use as companions
- Recipe data on the web
- Units
- Formats considered and rejected
- How to look for changes

## Obsidian and its plugins

| Source | Status | Used for |
|---|---|---|
| Recipe View docs: https://obsidian-recipe-view.readthedocs.io/en/latest/usage/formatting.html and `.../usage/scaling.html` | read 2026-10-24 | No strict format, side-column headings, checkable ingredient lists, selectable steps, `---` split, thumbnail rule, quantity formats for scaling |
| Recipe View repo: https://github.com/lachholden/obsidian-recipe-view | partly read | MIT, 179 stars, README defers to the docs |
| Recipe View Plus fork: https://github.com/N1ktra/obsidian-recipe-view | search only | `cover`, `type` filter, `total_time`, timers; not installed, not evaluated |
| Obsidian CLI help: https://obsidian.md/help/cli | search plus local test | Official CLI since 1.12.4; needs the running app; `tags counts`, `base:query`, `property:*` |
| Obsidian Web Clipper templates: https://obsidian.md/help/web-clipper/templates, https://github.com/kepano/clipper-templates | read | `schema:@Recipe` trigger and the kepano recipe template (properties `author`, `image`, `cuisine`, `url`) |
| The user's vault (read-only, 2026-10-24) | read | Template, Bases file, Checklist plugin settings, 111 notes of statistics (see the ledger, sections 9, 10, 20) |

## Upstream skills to use as companions

Not installed by this skill. When the task needs Obsidian syntax details, use an installed copy first; otherwise read
the raw file with `webfetch`. Do not copy their content here.

- `obsidian-markdown` (properties, tags, embeds, callouts, wikilinks):
  https://raw.githubusercontent.com/kepano/obsidian-skills/main/skills/obsidian-markdown/SKILL.md
- `obsidian-bases` (`.base` files, filters, formulas, card views):
  https://raw.githubusercontent.com/kepano/obsidian-skills/main/skills/obsidian-bases/SKILL.md
- Repository (MIT, Agent Skills format, also `obsidian-cli`, `defuddle`, `json-canvas`, `knap`):
  https://github.com/kepano/obsidian-skills

## Recipe data on the web

| Source | Status | Used for |
|---|---|---|
| Google Recipe structured data: https://developers.google.com/search/docs/appearance/structured-data/recipe | read 2026-10-24 | Properties, `HowToStep` and `HowToSection`, ISO 8601 times, image lists |
| `recipe-scrapers` 15.13.0 (PyPI, https://github.com/hhursev/recipe-scrapers) | PyPI read, tested locally | Compared with the R code; see extraction-and-images.md |
| `extruct` 0.18.0 (PyPI) | PyPI read | JSON-LD, microdata and OpenGraph extraction (Python) |
| Obsidian forum thread on schema.org parsing | search | JSON-LD with raw newlines fails in the Web Clipper |
| Copyright notes by recipe authors (davidlebovitz.com, cookistry.com, justhungry.com) | search | Photos and directions are protected; ingredient lists generally are not; credit and link back |

## Units

Swedish, Finnish and German conversion pages and the `pint` check are listed in [units.md](units.md).

## Formats considered and rejected

| Format | Why not |
|---|---|
| Cooklang (`.cook`, `.cook.md`) | One maintainer since 2021; the Obsidian plugin asks for maintainers; whole-file mode expects a raw Cooklang body, so a Markdown image embed does not render; `#cookware` can clash with Obsidian tags; the user's vault uses Recipe View, not Cooklang. The core tools are active and files stay readable, so a Cooklang export could be added later |
| RecipeMD | Smaller community; Recipe View already reads the user's layout |
| Recipe Box, Recipe Vault plugins | Overlap with Recipe View; add import, meal plans and shopping features that the user did not ask for |

## How to look for changes

- Recipe View: its docs pages and the repository releases.
- Obsidian: release notes for properties, Bases and the CLI; re-check the Bases card image property.
- Sites: re-run `rn_extract_recipe()` on a known page; markup changes without notice.
- Packages: `yaml`, `httr2`, `xml2`, `rvest`, `jsonlite`, `cld2` (CRAN).
