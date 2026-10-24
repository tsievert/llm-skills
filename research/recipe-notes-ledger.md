# Recipe notes formatter ledger

Research ledger for the planned skill `recipe-notes-formatter` (name accepted by the user 2026-10-24). Started 2026-10-24. Working notes,
not a skill (no SKILL.md). Conventions as in the other ledgers: status **read** = page text read in this session, **partial** = only part
answered, **blocked** = fetch failed, **search** = only a search excerpt, **meta** = metadata or API numbers only, **not researched** = lead
or known only from memory. Versions and counts are dated 2026-10-24; re-check before writing them into a skill. Do not repeat a search that
has a row here; extend the row instead.

## 1. Requirements (user decisions, in order of arrival)

| # | Requirement | Source / date |
|---|---|---|
| R1 | Skill turns sources (plain text, Obsidian MD files, web links) into recipe notes. First idea was Cooklang, but the user is "not set on cooklang" | 2026-10-24 |
| R2 | Check for a better supported ecosystem compatible with Obsidian before writing anything | 2026-10-24 |
| R3 | Skill does **not** need to interact with the vault. Input folder and output folder; user drops files in, reformatted files appear in output | 2026-10-24 |
| R4 | Skill learns the existing tag structure (and similar conventions) from the provided files and keeps track of it (profile file). Main goal: learn existing structure. It may also suggest new tags (user approves) | 2026-10-24 |
| R5 | Languages mixed across German, English, Swedish, Finnish. **No translation.** Recipes stay in source language; mixing happens between files, rarely inside one note | 2026-10-24 |
| R6 | Units: metric. Anything else is converted | 2026-10-24 |
| R7 | Link given: embed a picture. Existing file: try to match the recipe to something online and choose that as the picture | 2026-10-24 |
| R8 | Recipe handling only. No shopping lists, meal plans, pantry | 2026-10-24 |
| R9 | Skill name `recipe-notes-formatter` is fine | 2026-10-24 |
| R10 | Sample notes will be provided after the main research is done. **Remind the user then** | 2026-10-24 |
| R11 | Always keep research in `research/` in a digestible format (rule added to AGENTS.md) | 2026-10-24 |
| R12 | Example recipes copied from the vault into `recipe-samples/` (git-ignored). Read-only on the vault | 2026-10-24 |
| R13 | The skill may depart from the existing note structure if a better one exists; it should make use of the installed plugins | 2026-10-24 |
| R14 | Mention extra plugins that could help, so the user can decide whether to install them (never install them) | 2026-10-24 |
| R15 | Online guides wanted; much of the community knowledge sits in Discord (not accessible to the assistant) | 2026-10-24 |
| R16 | Research unit conversion, JSON-LD extraction and image sourcing; consider whether a separate "interact with Obsidian" skill is needed | 2026-10-24 |
| R17 | **Ticked `[x]` means "not on the shopping list", unticked `[ ]` means "add to the shopping list"** (user, 2026-10-24; verified in section 20). New notes therefore get ticked ingredients | 2026-10-24 |
| R18 | Servings and time as numeric properties; drop empty `## Intro` and `## FINISH`; metric replaces non-metric units (original only in the report); English tbsp/tsp stay; picture downloaded into `output/images/` and embedded with source and credit; kepano skills named as optional companions | 2026-10-24 (defaults accepted) |
| R19 | Tag profile: default accepted (YAML file next to the output folder, git-ignored); the user asked what it means in practice, answer given in chat | 2026-10-24 |
| R20 | Safety: never overwrite; if anything existing would be replaced, copy it to a timestamped backup first so it can be restored. Never edit `input/` | 2026-10-24 |
| R21 | The user will create an R project for the conversion. The skill checks that `input/`, `output/` and the other folders exist and **asks permission before creating missing ones**. Tooling should therefore be R | 2026-10-24 |
| R22 | `author` is the note author (the user); `Created_at` and `Modified_at` are left to Templater (not written by the skill) | 2026-10-24 |

Open questions to the user (not yet answered): output format choice (structured Markdown recommended), image storage (download vs
hotlink), how converted units appear, folder locations (Windows paths), whether old notes get converted in place (default: no, new files).

## 2. Format candidates

| Candidate | Evidence | Status | Verdict so far |
|---|---|---|---|
| Cooklang (`.cook`, `.cook.md`, `.md` with `recipe: true`) | See 3 and 4 | read | Plain text, MIT, specification small. Bus factor one (see 4). Plugin whole-file mode expects a raw Cooklang body, so a Markdown image embed in the body does not render; images come from `image` metadata or sibling files. `#cookware` can be read as an Obsidian tag in `.md` files. Not recommended as primary format |
| Structured Markdown (YAML properties + `## Ingredients` list + numbered steps) | Recipe Box, Recipe Vault, Web Clipper templates all use it (section 5) | read | Recommended primary. Native Obsidian rendering, Dataview/Bases friendly, tool independent |
| RecipeMD | repo `RecipeMD/RecipeMD`: 94 stars, 9 forks, LGPL-3.0, last push 2026-07-27, 12 open issues, Python CLI | meta | Smaller than Cooklang; Recipe Box supports it. Not read in depth |
| schema.org Recipe (JSON-LD) as property vocabulary | Web Clipper variables `schema:recipeIngredient`, `recipeInstructions`, `recipeYield`, `totalTime` etc. | read | Use as naming reference for YAML properties; not as file format |

## 3. Cooklang facts (read)

| Fact | Source |
|---|---|
| `https://cooklang.org/llms.txt` is the LLM entry point: short, covers core syntax (`@ingredient{qty%unit}`, `#cookware{}`, `~timer{}`, `--` comments) and links to spec, CLI, GitHub. Mentions YAML frontmatter | webfetch, read |
| Spec page: YAML front matter only (no `>>` metadata); sections `= Name`; notes start with `>`; comments `--` and `[- -]`; optional `@?name`; recipe references by path relative to recipes root without `.cook`; steps separated by blank lines | `cooklang.org/docs/spec/`, read |
| Conventions: metadata keys `title`, `source` / `source.name`, `author`, `servings`/`serves`, `yield` (`500%ml`), `course`/`category`, `locale` (`en_GB`), `time`/`prep time`/`cook time` (`1h30m`), `difficulty`, `cuisine`, `diet`, `tags` (list), `image`/`images`/`picture`, `introduction`/`description`. Images: sibling file with recipe name, step images `Name.1.jpg`. `.menu`, `.shopping-list`, aisle and pantry config exist (out of scope, R8) | `cooklang.org/docs/conventions/`, read |
| Official skills repo `cooklang/cooklang-skills`: 14 skills + Cook MCP server `@cookmd/mcp`. `recipe-import` needs the MCP `import_recipe` tool, does not save, rules: validate then `write_recipe`, keep `source`, ask before overwrite, do not invent servings/times. Photos and social links need a cook.md account and import allowance (Basic/Pro); plain URL and pasted text work without login | `github.com/cooklang/cooklang-skills`, `.../skills/recipe-import/SKILL.md`, read |
| Community skills seen only as listings: `claudskills.com` "Cooklang Formatting", `mcpmarket.com` "Cooklang Recipe Writing", `stephendolan/dotfiles` cooking skill (writes `.cook`, Dinner/Breakfast folders, optional `?@`) | search |
| `zeshuochen/cooking-skills` (Claude Code skill; YouTube, Xiaohongshu, Bilibili links to Obsidian Markdown recipe notes, opens page in Chrome, optional index file) | search; repo not read |

## 4. Cooklang maintenance (is the format future-proof?)

| Fact | Source / status |
|---|---|
| Built by Alexey Dubovskoy, one person, since 2021. Language, parsers, CLI, Cook Editor open source; funded by Cook Cloud subscriptions (Cook Basic, Cook Pro EUR 12.99/month for CookBot) | `cook.md`, search; Cook Editor page, search |
| GitHub activity (API, 2026-10-24): `cooklang-rs` pushed 2026-10-15 (124 stars, MIT, 30 open issues); `cookcli` pushed 2026-10-22 (1,417 stars, 29 open issues); `spec` pushed 2026-09-30 (698 stars, discussions on); `cooklang-obsidian` pushed 2026-10-20 (368 stars, 14 open issues) | GitHub API, meta |
| Obsidian plugin README/stats say "Looking for maintainers" (stats site quoting README); plugin is `Cooklang Editor` 0.14.0 (2026-09-21), 17k downloads. A second plugin `cooklang-viewer-and-editor` (rveciana) 0.1.0, 3k downloads | `community.obsidian.md`, `obsidianstats.com`, search |
| VS Code extension reports 1 open source maintainer (Socket) | search |
| Obsidian plugin (cooklang-obsidian) formats: `.cook`, `.cook.md` (recognised by name), `.md` with boolean `recipe: true`; Source mode editing; rich preview; embeds `![[Dinner]]` read-only; references resolve from vault root; `.cook` not indexed by Obsidian search/Dataview; raw `#cookware` may become a tag; YAML properties queryable only in Markdown formats | `github.com/cooklang/cooklang-obsidian`, search (README text) |

Conclusion recorded: risk is a single-maintainer ecosystem, not a dead one. Files stay readable either way. Reason enough not to make it the
primary format for this skill; Cooklang export can be an option later.

## 5. Obsidian-side recipe ecosystem (search unless noted)

| Item | Facts | Cooklang? |
|---|---|---|
| Recipe Box (`AdamArcane/obsidian-recipebox`, fork `lumetormi`; community plugin `recipe-box`) | Markdown notes, headings or RecipeMD; import from URL, pasted text, Mealie and schema.org JSON; cook history in frontmatter; Dataview/Bases; GPL-3.0-or-later. Fork page read: no frontmatter schema required, notes in the `Recipes` folder are detected | no |
| Recipe Vault (`taylorsdugger/obsidian-recipe-vault`, v1.2.7, ~1k downloads, MIT) | URL import via JSON-LD, photo import via OpenRouter vision, Handlebars template, frontmatter fields `cssclasses, tags, date_added, meal_type, author, cook_time, url, photo, times_made, last_made` | no |
| Recipe Vault fork `Finnick4/obsidian-recipe-vault` | Optional "Cooklang file" output setting; 227 commits, 0 stars; not separately listed in the directory. Page read | optional |
| Obsidian Web Clipper (official, MIT, v1.7.1 on Firefox store) | Templates with triggers `schema:@Recipe`; variables from schema.org JSON-LD; filters; only gets what the site provides. Known failure: JSON-LD with raw newlines in strings is rejected (forum thread, 2024). Example templates in `kepano` clipper-templates (not read), Polish WPRM template on forum | no |
| Skill: Obsidian Web Clipper Template Creator (mcpmarket listing) | Generates clipper JSON via WebFetch; not read | no |

## 6. How to interact with Obsidian locally (answer to the user's question, 2026-10-24)

None of this is needed for the chosen design (R3); recorded so it need not be searched again.

| Route | Needs Obsidian running | Facts | Source |
|---|---|---|---|
| Plain files (a vault is a folder of `.md` files) | no | Works whenever the assistant can read/write the folder; no plugin. Obsidian picks up changes on disk. Bypasses link updating | search (several) |
| Official Obsidian CLI | yes (first command launches the app) | Shipped early access 1.12.0 (2026-02-10), generally available 1.12.4 (2026-02-27), faster binary 1.12.7; enable in Settings > General > Command line interface and register; on Windows a terminal redirector `Obsidian.com` sits next to `Obsidian.exe`. 100+ commands: `read`, `create` (with `template=`, `overwrite`), `append`, `move` (updates links), `files`, `search`, `tags` (`tags counts`), `property:set/read/remove`, `base:query`, `command id=`, `eval` (runs JS in app). Parameters `key=value`, `vault="Name"` selects vault | `obsidian.md/help/cli`, `dsebastien.net` guide, search |
| Local REST API plugin (`obsidian-local-rest-api`, Adam Coddington) | yes | v5.5.2, 812k downloads, MIT, desktop only. HTTPS 127.0.0.1:27124 (self-signed cert; HTTP 27123 optional), bearer key. Endpoints `/vault/{path}` CRUD incl. binaries, `/active/`, `/search/simple/`, `/search/` (JsonLogic), `/tags/`, `/commands/`, `/open/`; PATCH targets headings, block refs, frontmatter keys. Built-in MCP endpoint `/mcp/` since the 2026 rename "Local REST API with MCP" | community.obsidian.md, obsidianstats, search |
| MCP servers over that plugin | yes | `MarkusPfundstein/mcp-obsidian` (uvx, seven tools, no tagged releases), `cyanheads/obsidian-mcp-server` (npx), others | mcp.directory, search |
| MCP servers working on files | no | `@modelcontextprotocol/server-filesystem`; `bitbonsai/mcpvault` (npx, AST-aware frontmatter, `--read-only` flag); `obsidian-mcp` by StevenStavrakis (file-based) | contextbolt, blakecrosley, search |
| In-app MCP plugins | yes | `MCP Connector` (istefox; 64 tools, per-client tokens, port 27200 broker, headless mode `obsidian-mcp-headless`), `MCP Server` plugin (port 27123, 12 days old, beta), `REST and MCP server` (dsebastien; exposes CLI as REST+MCP) | community.obsidian.md, search |
| Agent-in-vault plugins | yes | Claudian embeds Claude Code/Codex as collaborator | search |
| Obsidian URI scheme (`obsidian://`) | yes | known to exist (referenced by plugin findings); **not researched** | |

Notes: the assistant in this workspace can read and write files in the working directory and use MCP servers registered in
`~/.posit/assistant/settings.json` (openalex is one). Not verified: whether registering an Obsidian MCP server there works on this
machine. Direct file access remains the lowest-dependency path; a vault subfolder can serve as `input/` or `output/` so no copying is needed.

## 7. Open research items (not yet done)

- Unit handling: metric conversion rules (cups, oz, lb, F, US tsp/tbsp vs metric), local abbreviations in de/en/sv/fi (EL/TL, msk/tsk/krm/dl, rkl/tl/dl, prise), density table for volume to weight, rounding conventions.
- Sourcing text from links: JSON-LD `Recipe` extraction (`extruct`, `recipe-scrapers` Python, R options), fallback to page text, bot walls, paywalls; image sources (`og:image`, JSON-LD `image`, `<picture>`); social-video links.
- Matching an existing note to an online recipe and choosing a picture: search method without paid APIs, confidence scoring, how to flag a weak match, image licence/copyright note for personal use.
- Obsidian conventions for the output: Properties types (list, text, number, date), tag syntax in frontmatter, Bases/Dataview-friendly field names, image embed syntax and attachment folders, wikilinks vs Markdown links.
- Tag and property learning: what to record in the profile file, how to detect the vocabulary language per tag, merge/synonym handling, how to store the profile (format and location).
- Prior art to read: `kepano` clipper-templates recipe template, `zeshuochen/cooking-skills`, Recipe Box RecipeMD parsing, cooklang-skills `metadata` skill.
- Skill-maintenance checks for the future build: `check_skill_clashes(new = "recipe-notes-formatter")`, boundary table entry, link audit (neighbours: `openalex` no, `social-research-search` maybe for video links, `data-repository-readme` no).
- Decide Windows path handling and the `.gitignore` rule for the user's input/output/profile folders (same pattern as `job-watch/`).

## 8. Log

- 2026-10-24 round 1: searched Cooklang Obsidian plugin, Obsidian recipe/Web Clipper, Cooklang agent skills; read cooklang.org llms.txt, spec, conventions, cooklang-skills `recipe-import`, two Obsidian recipe plugin repos; GitHub API for five repos. Result: format question reopened (sections 2 and 4).
- 2026-10-24 round 2: Obsidian local entry points (CLI, Local REST API, MCP servers) searched; section 6.
- 2026-10-24 round 3: read-only local probe of the user's Obsidian (section 9). Nothing was written, enabled or changed.

## 9. Local findings about the user's Obsidian (2026-10-24, read-only)

| Check | Result |
|---|---|
| Obsidian running | yes (three `Obsidian.exe` processes) |
| Install folder | `C:\Program Files\Obsidian\` (`Obsidian.exe` and `Obsidian.com`, the CLI terminal redirector); not on PATH in Git Bash |
| Official CLI via full path (`Obsidian.com version`, `vaults verbose`) | returns "Command line interface is not enabled. Please turn it on in Settings > General > Advanced." The user must toggle it; the assistant must not change settings. Not tested beyond that message |
| Local REST API / MCP ports 27123, 27124, 27200 | nothing listening (connection refused); the plugin is not installed |
| Vault registry `%APPDATA%\obsidian\obsidian.json` | two vaults: `C:\Users\thorb\Syncthing\Obsidian\obsidian-notes` (open) and `...\DeepLab Cookbook` (a DeepLabCut documentation vault, not recipes) |
| Vault location | inside a Syncthing folder (`.stfolder`, `.stversions` present). Writes from outside Obsidian are synced to other devices |
| Vault structure | `Cookbook/` with 111 files, `Cookbook base.base` (Bases), `templates/00001 Recipe Template.md`, `Shopping list.md`, `Pictures/`, `templater_scripts/`; about 301 Markdown notes in total |
| Enabled community plugins (35) | notably `recipe-view` (lachholden, v0.3.6: "interactive recipe cards while you cook"), `dataview`, `templater-obsidian`, `tag-wrangler`, `auto-note-mover`, `obsidian-linter`, `supercharged-links-obsidian`, `webpage-html-export`, `obsidian-tasks-plugin`. **No Cooklang plugin, no Recipe Box, no Recipe Vault, no REST API/MCP plugin** |
| Recipe template (read) | frontmatter: `aliases`, `source`, `tags` (`recipe` plus others), `author: Thorbjörn Sievert`, `Created_at` (Templater `tp.file.creation_date()`), `Modified_at`. Body: link `[[000 Cookbook index\|Cookbook index]]`, a `> [!note]` callout, `## Ingredients` with an inline `#ingredients` tag and checkbox list (`- [x]`), `## Intro:`, `## Directions`, `## FINISH:` |
| `Cookbook base.base` (read) | filter `file.folder == "Cookbook"` and `file.tags.contains("recipe")`; table "All recipes" plus card views per tag. Tag vocabulary in use (hierarchical, English, lowercase): `recipe/salad, vegetarian, vegepossible, fish, vegan, veganpossible, chicken, beef, pork, dessert, baking, sidedish, soup, stew, pasta, onepot, casserole, cocktail, mocktail` |
| Recipe file names | mostly German and English titles, spaces and umlauts, no ID prefix (e.g. `Allgäuer Käsespätzle.md`, `Classic Minestrone Soup.md`) |
| Not read | the bodies of any recipe note, `recipe-view` plugin code, `.obsidian` settings other than the plugin list |

Consequences recorded: (1) the user's existing ecosystem is `recipe-view` plus Bases/Dataview, not Cooklang; this settles the format
question in favour of structured Markdown that matches the template and tag hierarchy. (2) The tag profile can start from the `.base`
file and the template, then be refined from the real notes. (3) Vault is Syncthing-synced, which supports keeping the skill file-in/file-out
with separate input/output folders. (4) Obsidian CLI needs a user action in Settings > General > Advanced.

Open items added: read how `recipe-view` identifies ingredients and steps (plugin README/source, `main.js` not read); check whether the
recipe notes use the template headings consistently (needs sample files, R10); check `webpage-html-export`/`templater` interplay only if relevant.

- 2026-10-24 round 4: copied 11 sample notes + template + base into `recipe-samples/`; read 7 notes; vault-wide statistics (section 10); online guides and plugin options (sections 11 and 12). Discord not reachable.

## 10. The user's real recipe notes (2026-10-24, read-only; samples in `recipe-samples/`, git-ignored)

Copied (cp -n, nothing changed in the vault): `Allgäuer Käsespätzle`, `Classic Minestrone Soup`, `Saftigaste kanelbullarna` (sv), `Helppo linssikeitto` (fi), `Lohikiusaus` (fi), `Kürbis-Lasagne`, `Pizza dough (Sorted Foods)`, `Mousse au Chocolat (à la Papa)`, `Erdnuss-Hummus`, `Chili con carne`, `000 Cookbook index`, plus `_template.md` and `_cookbook-base.base`. Read in full: the first five, the index, Mousse.

| Statistic over 111 notes in `Cookbook/` | Result |
|---|---|
| Frontmatter keys | `aliases` 110, `source` 110 (only **7 filled**), `tags` 110, `Created_at` 111, `Modified_at` 111, `author` 45 (always "Thorbjörn Sievert") |
| Image embeds (`![[` or `![`) | **0 notes**; no pictures at all |
| `#ingredients` inline tag | 110 notes; `## Directions` 109; H1 title 111 |
| Tag use | `recipe` 110; `recipe/vegetarian` 70; `recipe/vegetarian/vegan` 28; `recipe/soup` 22; `recipe/baking` 19; `recipe/vegetarianpossible/veganpossible` 17; `recipe/vegetarianpossible` 13; `recipe/pasta` 13; `sidedish`, `pork`, `casserole`, `beef` 10 each; `dessert` 9; `fish` 7; `stew`, `salad`, `onepot` 6; `snack` 5; `pizza` 3; `mocktail`, `chicken`, `asian`, `asian/curry` 2; one each `texmex`, `snack/sandwich`, `sauce`, `asian/ramen` |
| Tag drift found | Base and index use `recipe/vegepossible` and `recipe/veganpossible`; notes use `recipe/vegetarianpossible`, `recipe/vegetarianpossible/veganpossible`, `recipe/vegetarian/vegan` (nested instead of `recipe/vegan`). Three notes contain the unfilled template placeholder tag `"{ tag2 }":`; several have `"{ alias1 }":` placeholders in `aliases`. Some tags (`pizza`, `snack`, `sauce`, `asian/*`, `texmex`) are missing from the base's card views |

Observed note structure (consistent across the samples):

- Frontmatter, then `# Title`, then a link (`[[000 Cookbook index|Cookbook index]]` or `[[Cookbook base.base]]`), then a callout `> [!note]` whose lines hold servings and time as **free text in the recipe language** (`ca. 30 Min`; `25 stycken` / `3h`; `Annoksia: 5` / `Valmistusaika: 1 t 5 min`).
- `## Ingredients`, inline `#ingredients`, checkbox list `- [x] ...` (all ticked in the template and in the notes; some lines carry a Tasks-plugin stamp `✅ 2025-08-03`). Sub-groups use `###` headings, each followed by its own `#ingredients` tag (kanelbullar note).
- `---`, `## Intro` (usually empty), `---`, `## Directions` (numbered list or plain paragraphs; `###` sub-sections in multi-part recipes), `## FINISH` marker at the end. Optional `> [!tip]` callout.
- Sources are links to web pages (koket.se, chocochili.net) or empty.
- Units and language: German (`g`, `ml`, `EL`, `TL`, `Messerspitze`), Swedish (`dl`, `msk`, `tsk`, `krm`, `g`, plus gram equivalents in brackets), Finnish (`dl`, `rkl`, `tl`, `tlk`), English (`tablespoons`, `teaspoon`, `ml`, `mL`, `g`). Evidence of the user's own conversion style in the Minestrone note: cups already replaced by `475 mL`, `950 mL`, `240 mL`, `800 g` (no original kept) while spoon units stayed English words. Decimal comma in Finnish (`1,5 dl`), text fractions (`1/4 tl`) and unicode fractions (`½`, `1 ½ - 2 tl`) all occur.
- Optional ingredients are written in parentheses (`(300 g kasviksia ...)`, `(2 cl Weinbrand ...)`).
- Typos exist in the source text (`qanzen`, `Muskatnus`, `ein einer`): the skill should not silently "correct" recipe text (R5, no rewriting beyond formatting); flag instead.

Open questions this raises (not yet asked): what does a ticked `[x]` mean in the user's workflow (template ships ticked); what feeds `#ingredients` (Checklist plugin shopping list or Dataview); whether the `Created_at` stamp should be kept for new notes (format `YYYY-MM-DD HH:mm`, Templater); whether `author` is meant as note author (always the user) or recipe author; where `FINISH` is used.

## 11. Online guides (round 4)

| Source | Status | Facts |
|---|---|---|
| Recipe View docs, Formatting (https://obsidian-recipe-view.readthedocs.io/en/latest/usage/formatting.html) | read (curl text) | No strict format. Suggested: optional thumbnail image embed first, preamble, `## Ingredients` (bulleted lists, quantity first; bold sub-headings allowed), `## Directions` (numbered list), `## Notes`, `## Nutrition`. Side column: headings matching setting (default `Ingredients\|Nutrition`) go into a side column. Bulleted lists in the side column **or before any heading** become checkable ingredient lists. Numbered lists or paragraph sequences in the main column become selectable steps. Properties show below the title. **First image not under a heading becomes the thumbnail.** `---` or `***` splits steps with their own ingredients |
| Recipe View docs, Scaling (https://obsidian-recipe-view.readthedocs.io/en/latest/usage/scaling.html) | read (curl text) | A number is a quantity if alone at the start of a text or next to a usual cooking unit. Formats: integer, `1/4`, `½`, `3.5`, `2 3/4`, `1 ¾` (space required), `1-1/4`. **Decimal comma not listed.** Scales only checkable ingredient lists by default; `<span data-qty-parse>` and `<span data-qty-no-parse>` for manual control. Which units are "usual" is not listed, not checked in `main.js` |
| Recipe View repo (lachholden, https://github.com/lachholden/obsidian-recipe-view) | partial | MIT, 179 stars, 25 open issues, 9 open PRs; README defers to the docs. Appearance via Style Settings plugin (installed) |
| Recipe View Plus fork (N1ktra, https://github.com/N1ktra/obsidian-recipe-view) | search | Fork of the same plugin: filters recipes by frontmatter `type` (default value `rezept`), `cover` property, `servings` property, writes `total_time` (minutes) back to frontmatter for Dataview/Bases, `@timer{35\|label}`, define-once ingredient highlighting (`@Butter`, `@{brown sugar}`), timer format `de`/`en`. Whether it is in the community directory and whether it can coexist with the original (same plugin id?) **not checked** |
| Obsidian Properties guide (obsidianmate.com, 2026-07) | search | Frontmatter must start on line 1. Recipes example: `type: recipe`, `cuisine`, `prep-minutes`, `cook-minutes`, `servings`, `vegetarian: true`, `rating`. Bases card views for visual collections. Reserve `tags`, `aliases`, `cssclasses`. Use ISO dates. Query by `type`, not folder. Inline `key:: value` fields are invisible to Bases |
| Obsidian forum, recipe manager tutorial (2021) | search | The user's current template is a descendant: `#ingredients` + checkbox list feeds the Checklist plugin shopping list; no line breaks inside the list or the tag must be repeated; minimal tags rule; file name hints at special equipment, alias removes the prefix |
| Obsidian forum, recipe database threads (2020-21) | search | Ingredients as a YAML list of `[name, amount]`, per-portion quantities, Dataview scaling, notes per ingredient; Paprika import template with fields `name, source, ingredients, difficulty, total_time, prep_time, cook_time, servings, rating, categories, photos`. Heavy; dates from 2020-21 |
| `edherrick/obsidian-cookbook` plugin | search | Reads notes tagged `#recipe`, frontmatter `title, cook-time, servings, cover`, `## Ingredients` with `- [ ] 500g beef mince`, parses units and ranges (English units only listed), `---` blocks as steps |
| kepano recipes clipper template (`kepano/clipper-templates`, `templates/recipes-clipper.json`) | read | Properties: `categories` `[[Recipes]]`, `author` (wikilinks), `title`, `image` (URL), `rating`, `cuisine`, `url`, `created` (date), `publisher`, `tags: recipes`. Body: description, `## Ingredients` as task list, `## Instructions` as task list, `## Nutrition` table. Trigger `schema:@Recipe`. Saved to `References` |
| Web Clipper community templates (`obsidian-community/web-clipper-templates`) | search | Public repository, not read. The Obsidian Discord has a Web Clipper channel with more templates (**Discord not accessible**) |
| Recipe Box docs | search | Notes in a `Recipes` folder are detected without frontmatter; RecipeMD (`---` separated) supported |
| Discord servers | blocked | Obsidian Discord and Cooklang Discord are not reachable by the assistant. If useful content is there, the user can paste it |

Not found anywhere: a published, tested convention for recipes in several languages in one vault, or for storing the original language per note. `locale` exists in Cooklang conventions (`en_GB`, `fr`) and could be reused as a property name.

## 12. Plugin options (round 4)

Installed and usable now (from the vault's plugin list, section 9): `recipe-view` (card rendering), `dataview` (index note), Bases (core, `Cookbook base.base`), `templater-obsidian` (template with `tp.file.creation_date()`), `tag-wrangler` (rename or merge tags, useful for the `vegepossible` drift), `obsidian-linter` (frontmatter normalisation), `auto-note-mover` (moves notes by tag or rule), `obsidian-checklist-plugin` (shopping list from `#ingredients`), `obsidian-tasks-plugin` (explains the stamps on ticked items), `supercharged-links-obsidian`, `webpage-html-export`, `obsidian42-brat` (installs beta plugins such as the Recipe View Plus fork), `obsidian-style-settings` (Recipe View appearance).

Candidates to mention (not installed; the user decides): Obsidian Web Clipper (official browser extension, template trigger `schema:@Recipe`); Recipe View Plus fork via BRAT (cover, timers, `total_time`); an image-download helper plugin for remote pictures (**not researched**, no candidate verified); Recipe Box (overlaps Recipe View, adds import and meal planning, out of scope R8).

## 13. Open research items after round 4

- Test in the user's Obsidian how Recipe View treats an image placed before the H1, a `cover` or `image` property, and decimal commas (needs the user to open a test note from `output/`; never write into the vault).
- Which Bases card property shows an image (verify in the Obsidian Bases docs) before deciding between `image` and `cover`.
- Read the Recipe View `main.js` or its issues for the unit list used for scaling (dl, msk, rkl).
- Unit conversion rules and local abbreviations (still open, section 7).
- JSON-LD extraction options and image sourcing (still open, section 7).
- Decide the target note structure (proposal in the chat reply of 2026-10-24) and ask the user to approve it.

## 14. Unit conversion (round 5, 2026-10-24)

| Fact | Source / status |
|---|---|
| Swedish: `krm` (kryddmått) 1 ml, `tsk` 5 ml, `msk` 15 ml, `dl` 100 ml, `kkp` (kaffekopp) 150 ml, `glas`/tekopp 200 ml, `dsk` (dessertsked) 10 ml, `cl` 10 ml, `l` 1000 ml. 1 dl is about 6 2/3 msk | konvertera.nu, raknar.se, hittadinmatkasse.se, tekniksektorn.se, recepten.se (search); koket.se (search) |
| Finnish: `mm` (maustemitta) 1 ml, `tl` 5 ml, `rkl` 15 ml (= 3 tl), `dl` 100 ml (= 6,7 rkl), `kkp` 1,5 dl, `tlk` = can (no fixed volume), `ounce` 28,35 g, `pound` 454 g | kinuskikissa.fi (search) |
| German: `TL` 5 ml, `EL` 15 ml (some sources say 10-15 ml, older cookbooks 12-15 ml; modern default 15 ml), `Tasse` about 250 ml in German convention while a US cup is 240 ml (**ambiguous**), `Messerspitze` and `Prise` have no defined volume (knife tip 5-10 mm; do not convert), level vs heaped spoon (`gestrichen`, `gehäuft`) changes weight not volume | schlanke-rezepte.de, swissmilk.ch, marktimhof.de, ultra-rechner.de, tools.cyberdox.de, grillinstructor.net, grillsportverein forum (search) |
| Danish `spsk` = tablespoon | baktider.se (search) |
| US measures: cup 236.6 ml (often rounded to 2.4 dl), tbsp 14.8 ml, tsp 4.9 ml, fl oz 29.6 ml, pint 473 ml; British tbsp 15 ml; **Australian tbsp 20 ml** (check the recipe's country) | konvertera.nu, hittadinmatkasse.se, raknar.se (search); pint `pint` library check below |
| Local check with `pint` 0.25.x (scratch venv): 1 cup = 236.588 ml, 1 tbsp = 14.787 ml, 1 tsp = 4.929 ml, 1 fl oz = 29.574 ml, 1 pint = 473.176 ml, 1 oz = 28.35 g, 1 lb = 453.592 g, 350 F = 176.7 C. `stick` is **not** defined in pint (US butter stick = 113 g, not verified here) | local test |
| Weight per volume (needed to convert a volume to grams, ingredient-specific): Swedish tables list per dl: vetemjöl 60 g, strösocker 85-90 g, farinsocker 85 g, florsocker 60 g, smör 90-95 g, havregryn 35 g, ris okokt 80-85 g, mjölk/vatten/grädde 100 g, olja 90-92 g, honung 130-140 g, kakao 40-42 g, salt 118-125 g; German per EL: Mehl 8 g, Zucker 12-13 g, Salz 18 g, Honig 20-21 g, Öl 13-14 g. Sources disagree by a few percent (flour 60 vs 65 g per dl) | koket.se, raknar.se, linneasskafferi.se, cornblogs.de, marktimhof.de (search). Treat as ranges |
| `ingredient-parser-nlp` 2.9.1 (2026-10-13, MIT, Python >=3.11, deps nltk, pint, numpy) parses ingredient sentences; the only language classifier is English. Not tested on de/sv/fi | PyPI JSON, meta |
| Recipe View scaling recognises `1/4`, `½`, `3.5`, `2 3/4`, `1 ¾`, but decimal comma is not listed (section 11) | docs |

Design consequences recorded (not yet confirmed with the user):

1. The user already treats `dl`, `msk`, `tsk`, `krm`, `EL`, `TL`, `rkl`, `tl`, `mm` as acceptable, and their Minestrone note converted cups to mL but left spoon words. Proposal: keep these local metric units as written (they are metric by definition: 5, 15, 1, 100 ml) and convert only non-metric units: cup, tbsp/tsp **when the unit is the English abbreviation from an English or US recipe**, fl oz, pint, quart, gallon, oz, lb, stick, inch, F. English `tbsp`/`tsp` could stay (15/5 ml) or become `msk`/`EL`; ask the user.
2. Convert volume to weight only with an ingredient density the skill can name; otherwise convert to ml/dl and say so in a flag. Never invent a density.
3. Round sensibly: cups to ml in steps of 5 or 10 ml (the user's note shows 475 mL for 2 cups, 950 mL for 4, 240 mL for 1), oz to g in steps of 5 g, oven temperatures to the nearest 5 C (350 F is 180 C by convention, not 176.7).
4. `Prise`, `Messerspitze`, `nypa`, `ripaus`, "to taste": leave as written.
5. Mixed forms to handle: decimal comma, `1,5`, ranges (`1 ½ - 2 tl`), unicode and text fractions, quantities glued to units (`150g`, `1dl`), optional ingredients in parentheses, bracketed equivalents (`500g mjölk (5dl)`).
6. Never touch quantities inside directions unless they are unit-bearing and clearly convertible; oven temperatures and pan sizes need the same rule.

## 15. JSON-LD extraction (round 5)

| Fact | Source / status |
|---|---|
| `recipe-scrapers` (hhursev) 15.13.0 on PyPI: MIT, Python >=3.11, core deps `beautifulsoup4`, `extruct`, `isodate`; extra `online` adds `requests`. Parses Schema.org (JSON-LD, Microdata, RDFa) or OpenGraph; 300+ site-specific scrapers incl. koket.se, ica.se, arla.se, recept.se, chefkoch.de, lecker.de, hellofresh.de/.se, kwestiasmaku.com; `wild_mode=True` works on any site with a Recipe schema; API: `title`, `yields`, `total_time`, `image`, `ingredients`, `ingredient_groups`, `instructions_list`, `language`, `category`, `cuisine`, `author`, `canonical_url`, `nutrients`, `to_json` | PyPI JSON (read), GitHub README and docs (search) |
| `extruct` 0.18.0 (2024-11-08, BSD, lxml, rdflib, mf2py, jstyleson): extracts JSON-LD, Microdata, RDFa, OpenGraph, microformat from HTML; `jstyleson` tolerates comments in JSON | PyPI JSON (read) |
| Local test (scratch venv, `uv run --with recipe-scrapers --with requests`, `scrape_html(html=..., org_url=..., wild_mode=True)`), on the user's real sources: **koket.se** (Swedish): HTTP 200, title, yields `25 servings`, total_time 240, image `https://img.koket.se/standard-mega/saftigaste-kanelbullarna.jpg`, language `sv`, author, canonical URL all fine; **ingredients() contains the group heading `Kanelfyllning` as if it were an ingredient**, `ingredient_groups()` returned a single `None` group, and `instructions_list()` also contains headings (`Kanelfyllning`, `Vetedeg`) as steps. **chocochili.net** (Finnish blog): HTTP 200 but **`NoSchemaFoundInWildMode`**: the page has one JSON-LD block (WebSite, Person, BreadcrumbList, no Recipe), but `og:image` is present (`.../linssikeitto.jpg`, 370x555) | local test |
| Google Recipe structured data: required `image` and `name`; recommended `author`, `cookTime`/`prepTime`/`totalTime` (ISO 8601), `description`, `keywords`, `recipeCategory`, `recipeCuisine`, `recipeIngredient` (plain text), `recipeInstructions` (`HowToStep` recommended, `HowToSection`, or plain text split by Google), `recipeYield` (text or integer, several allowed), `nutrition`; images as a list of URLs in several aspect ratios (16x9, 4x3, 1x1, at least 50K pixels) | developers.google.com (read) |
| Obsidian Web Clipper only sees what the site provides in JSON-LD, and fails when JSON-LD has raw newlines in strings (forum 2024) | search (section 5) |
| `defuddle` (kepano; MIT, 9.8k stars, "work in progress"): Node CLI (`npx defuddle parse <url> --markdown --frontmatter --json`), returns main content as Markdown plus metadata (title, author, description, `image`, language, `schemaOrgData`). Not tested here | GitHub page (read) |
| ISO 8601 durations (`PT1H15M`) must be converted to minutes for a numeric `time` property | known, not researched |

Design consequences:

- Tiered extraction is needed: (1) `recipe-scrapers` site scraper or wild mode; (2) raw JSON-LD or microdata via `extruct`; (3) page text read by the assistant (webfetch or `defuddle`), with the assistant structuring ingredients and steps, flagged as lower confidence. The Finnish blog case proves tier 3 is not optional.
- Verify scraper output instead of trusting it: group headings leaking into `ingredients()` and `instructions_list()` (koket.se) must be detected (a line without quantity that matches a heading) and turned into `###` sub-headings.
- Language: `language()` gives the page language; keep the recipe text exactly as scraped (R5), including Finnish and Swedish.
- Python is only the transport; the conversion rules should live in a small script that the skill ships and tests, in the repo's usual style (`uv run`, scratch venv for tests).
- Social-video links (YouTube etc.) have no usable schema in general; out of scope until the user decides (R7 asks for links, not videos).

## 16. Image sourcing and rights (round 5)

| Fact | Source / status |
|---|---|
| For a link, the candidate images are, in order: JSON-LD `Recipe.image` (URL, ImageObject or list), `og:image`, first large `<img>` in the recipe card. Test: koket.se JSON-LD image and `og:image` both present; chocochili.net only `og:image` (370x555) | local test |
| Matching an existing note without a link: the assistant has `web_search` and `webfetch`; no image-search API with a key is needed. Method to design: build a query from title + two distinctive ingredients in the note's language, open top hits, compare ingredient overlap, accept only a strong match, record the URL and a confidence | design, not tested |
| Rights: lists of ingredients are generally not protected, but the descriptive text, directions in the author's words and **photographs are**. Several blogs state that photos may be shown with credit and a link back (David Lebovitz: linking needs no permission; republishing does; same for photos), others forbid reuse. Hotlinking the photo from the author's server is what bloggers notice (justhungry). This is general web guidance, not legal advice | search results 2026-10-24 (davidlebovitz.com, cookistry.com, justhungry.com, bootstrapped.ventures) |
| Practical consequence: store `source` (page URL) and an image credit line with every picture; prefer a link-back; for personal use copying to the vault is common but the skill should say so once and let the user choose download vs hotlink | design |
| Obsidian embed syntax: `![[file.jpg\|300]]` for vault files, `![alt](https://...)` for remote; Recipe View takes the first image not under a heading as thumbnail; `cover` property in the Plus fork | sections 11 and 12 |

Open: whether Bases card views read an `image` property (unverified), size limits for images, how to download safely (content-type check, size cap, file naming), avoiding broken hotlinks over time.

## 17. Is a separate "interact with Obsidian" skill needed? (round 5)

| Fact | Source / status |
|---|---|
| `kepano/obsidian-skills` exists (Steph Ango, Obsidian CEO): skills `obsidian-markdown` (Obsidian Flavored Markdown: wikilinks, embeds, callouts, properties), `obsidian-bases` (.base files), `json-canvas`, `obsidian-cli`, `defuddle`, `knap` (Markdown templates from JSON/CSV, batch generation). MIT, Agent Skills spec, about 49k stars, 49 commits, install via `npx skills add`, plugin marketplace or manual copy; the page does not mention Posit | GitHub README, skills.sh, skillsovermcp (search; README fetched) |
| `obsidian-cli` skill needs the official Obsidian CLI, which is **not enabled** on the user's machine (section 9) | local test |
| The recipe skill is file-in/file-out (R3). It writes Markdown with properties, callouts and embeds, which is exactly what `obsidian-markdown` documents; it may touch `.base` only if the user asks | design |

Recommendation (to be confirmed by the user): **do not write a custom "interact with Obsidian" skill.** Reasons: (1) no vault interaction is wanted; (2) the maintained official-author skills already cover Obsidian syntax, Bases and CLI; copying their advice into our skills would go stale (rule: point to neighbours, do not duplicate); (3) the one custom piece needed is recipe-specific and belongs in `recipe-notes-formatter`. Optional: the user may install `kepano/obsidian-skills` (their decision; GitHub source, so ask first) and the recipe skill would name `obsidian-markdown` and `obsidian-bases` as companions. A thin local skill would only be justified if the user later wants vault operations (CLI or Local REST API) shared across several skills.

## 18. Open research items after round 5

- Test `defuddle` and the assistant's `webfetch` as tier-3 fallback on the chocochili.net page (extraction quality for Finnish text, ingredient/step separation).
- Check `recipe-scrapers` on a German site (chefkoch.de) and a mixed-quality blog to see how often wild mode fails; do not test more of the user's source sites than necessary (polite requests, one per page).
- Verify Bases card view image property in Obsidian docs (needed for `cover` naming).
- Verify what unit list Recipe View uses (still open from section 13).
- Decide: tbsp/tsp from English recipes: keep or map to `msk`/`EL`/`rkl` (user choice).
- Decide: tag profile file format and location (user choice; proposal: a YAML or JSON file next to the output folder).
- 2026-10-24 round 5: unit conversion (section 14), JSON-LD extraction with a local recipe-scrapers test on two of the user's source URLs (15), image sourcing and rights (16), separate Obsidian skill question (17), open items (18).

## 19. Follow-ups (2026-10-24, same day)

- Referencing upstream skills: the raw files `https://raw.githubusercontent.com/kepano/obsidian-skills/main/skills/obsidian-markdown/SKILL.md` and `.../obsidian-bases/SKILL.md` are readable with webfetch (markdown: wikilinks, embeds, callouts, properties, tags, comments, plus references `PROPERTIES.md`, `EMBEDS.md`, `CALLOUTS.md`; bases: about 400 lines, filters, formulas, views, YAML quoting rules). Plan: our skill points to them (installed copy first, else live fetch), never copies their content.
- Obsidian on the user's machine is **1.14.5** (exe ProductVersion, log 2026-10-24); install moved to `C:\Program Files\Obsidian`. The app bundle (`obsidian.asar`, read-only grep) renders the toggle 'Command line interface' (description 'Allow interactions with Obsidian from the command line.') in the same settings list as 'Notify if startup takes longer than expected', only for the desktop app with electron; `Obsidian.com` says 'Settings > General > Advanced'. The user could not find it: to be resolved (settings search 'command line', scroll to Advanced, version in Settings > About).
- 2026-10-24 CLI test (read-only, after the user enabled it): `Obsidian.com version` returns '1.14.5 (installer 1.14.5)'; `vaults verbose` lists both vaults; `vault=obsidian-notes vault` reports 304 files, 33 folders; `files folder=Cookbook total` = 111; `tags counts` works. Counts roll up nested tags (recipe/vegetarian 98 = 70 own + 28 under recipe/vegetarian/vegan; recipe/vegetarianpossible 30 = 13 + 17; #recipe 387 includes all children; #ingredients 144 because several notes carry it more than once), so they differ from raw frontmatter counts (section 10). Not tested: write commands (deliberately), `properties`, `base:query`. The command must be called by full path unless 'Register' put it on PATH.

## 20. Build-phase findings (2026-10-24)

- Shopping workflow verified from the vault: `Shopping list.md` holds ticked items with Tasks stamps (bought); the Checklist plugin (`obsidian-checklist-plugin` data.json) watches the tags `todo`, `ingredients` and `shopping` with `showChecked: false`, so only UNTICKED items tagged `#ingredients` appear in its sidebar, grouped by page. Hence ticked = not on the list, unticked = to buy. The stamp is added by Tasks when ticking in the UI; the skill must not write stamps.
- CRAN check (2026-10-24): no recipe-scraping package. Names matched: `recipes`/`textrecipes` (tidymodels), `jsonld` (a V8-based JSON-LD processor, not needed: only the Recipe node is wanted), `gcookbook`, `ggrecipes`, `shinyrecipes`. Plan: rvest + xml2 + jsonlite + httr2 + yaml (all installed). `units` is not installed and not needed. Installed `cld2` 1.2.6 from CRAN for language detection: correct on full sentences (de, sv, fi, en), NA on a short Swedish ingredient line, so detect on directions text.
- CLI read-only test of the user's Bases file: view 'All recipes' 110 notes, 'Vegetarian' 73, **'Easy Vegetarian' 0, 'Vegan' 0, 'Easy Vegan' 0** because the base filters `recipe/vegepossible`, `recipe/vegan`, `recipe/veganpossible` while the notes use `recipe/vegetarianpossible`, `recipe/vegetarian/vegan`, `recipe/vegetarianpossible/veganpossible` (tag drift is a real bug in the user's views; report it, do not fix the base or notes).
- Agent Skills spec and best practices re-read 2026-10-24: name max 64, description max 1024 (repo guideline about 950), body under 500 lines, references one level deep, TOC for files over 100 lines, scripts should solve rather than punt, plan-validate-execute for batch work.

## 21. Skill built (2026-10-24)

- `recipe-notes-formatter/` written and checked; summary of files, tests and checks is in AGENTS.md (Log, 2026-10-24). Tooling is R (the user is making an R project); Python `recipe-scrapers` was used only as a comparison (it put group headings into ingredient and step lists and failed on the Finnish blog; the R code flags heading candidates and falls back to page text).
- Live end to end (scratch folder, removed afterwards): koket.se gave tier jsonld, 23 ingredient lines, four group headings detected, picture downloaded (image/jpeg, 104989 bytes), note rendered, `rn_check_note()` clean. chocochili.net gave tier none, language fi, page_text with the recipe, og:image candidate.
- Profile learned from the 12 copied samples: 14 tags, author and index link learned, checkbox default ticked, 10 base tags without matching notes, with nearest-tag suggestions for the three vegan and vegetarian views.
- Open: user trial run on a real batch; verify in Obsidian the Recipe View thumbnail with the picture before the H1, the Bases card image property, Templater timestamps for files copied in; picture search on real notes.
