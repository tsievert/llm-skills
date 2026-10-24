---
name: recipe-notes-formatter
description: 'Turns recipes from plain text, existing Obsidian Markdown notes and web links into consistent Obsidian recipe notes: numeric servings and time, metric units, tags taken from the tag structure learned from the user''s own notes, and an embedded picture. Works from an input folder to an output folder in an R project (never inside the vault), keeps each recipe in its source language (German, English, Swedish, Finnish), backs up before replacing anything and maintains a recipe profile file. Use when the user wants to convert, clean up, import or format recipes for Obsidian, drops recipe notes or links into input, asks to fix recipe tags, or to convert cups, ounces or Fahrenheit in a recipe. For general Obsidian syntax or Bases files use the obsidian-markdown and obsidian-bases skills if installed.'
compatibility: Requires R with yaml, httr2, xml2, rvest and jsonlite (optional cld2 for language detection) and internet access for links and picture search. Works on files in the user's R project and never writes into the Obsidian vault. Developed on Windows with Obsidian 1.14.
---

# Recipe notes formatter

Turn recipes from three kinds of source into notes in the user's Obsidian recipe format, **run after run**.
The user drops files or links into `input/`; finished notes, pictures and reports appear in `output/`. The skill
learns the user's tag structure from their own notes and keeps it in a profile file, so tags stay consistent.

| Step | Who does it | Why |
|---|---|---|
| Fetch pages, read JSON-LD, convert units, build and check the note, learn tags, back up, write | `scripts/rn_*.R` (no model) | Must be exact, repeatable and testable |
| Read text recipes and pages without markup, structure them, judge dish type and tags, match a note to an online recipe, pick the picture | The assistant | Needs reading and judgement |
| Create folders, write the profile, approve new tags, approve a picture match | **The user says yes first** | The inputs and conventions are theirs |

## Where this skill runs

Locally, in the user's R project (the working directory). It never reads or writes the Obsidian vault and does not
need Obsidian to be running. Notes reach the vault only when the user copies them. Pages behind a login or bot wall
are recorded as blocked and are not bypassed.

## Step 0: project folders and profile

```r
sd <- "<skill-dir>/scripts"   # the directory shown when this skill loads
for (f in c("rn_units", "rn_core", "rn_profile", "rn_web")) source(file.path(sd, paste0(f, ".R")), encoding = "UTF-8")
rn_project_check()            # input, output, output/images, backup, recipe-profile.yml
```

1. **Missing folders:** list them and ask with `AskUser` before creating anything; only then
   `rn_project_create(confirmed = TRUE)`. The R project itself is the user's.
2. **Profile:** `pf <- rn_profile_read("recipe-profile.yml")`. If it does not exist, learn it from existing notes
   dropped in `input/` (and a `.base` file if given): `pf <- rn_learn_profile("input", base = "input/<x>.base")`.
   Show `rn_profile_summary(pf)` and the drift findings (see [references/tag-profile.md](references/tag-profile.md)),
   explain in two sentences what the profile is (it is a plain YAML file of tags and habits the skill reuses, which
   the user can edit), and write it only after a yes: `rn_profile_write(pf, confirmed = TRUE)`.
   Learning needs examples: if `input/` holds no recipe notes yet, ask for three to five and say why.
3. Without notes to learn from, use the defaults in [references/note-format.md](references/note-format.md) and say so.
   An annotated example of the profile file is in [assets/recipe-profile.example.yml](assets/recipe-profile.example.yml).

## Step 1: sort the inputs

| Input | What to do |
|---|---|
| `.md` note already in a recipe layout | Parse with `rn_read_note()`. Keep the wording; fix structure, units, tags, properties. |
| `.txt` or pasted text | Structure it by hand (ingredients, steps, groups); never add quantities, times or servings that are not stated. |
| URL, or a file listing URLs | Step 2. |
| A page you cannot read (login, JS-only, blocked) | Record it as blocked in the report; do not bypass. |

**Never edit anything in `input/`.** Output is always a new file.

## Step 2: links (three tiers)

```r
pg <- rn_fetch_html(url)                      # polite: one request at a time, 1.5 s apart
x  <- rn_extract_recipe(pg$html, pg$url)      # x$tier is "jsonld", "microdata" or "none"
```

- **jsonld / microdata:** values are raw page data. Check `x$flags`. Group headings often arrive as ingredient
  lines (`x$heading_candidates`); confirm them, then `x <- rn_apply_headings(x, idx = <confirmed>)`.
- **none:** the page has no recipe markup (a normal case for blogs). Read `x$page_text`, structure ingredients and
  steps by hand, and mark the recipe **lower confidence** in the report. Details and the tested cases:
  [references/extraction-and-images.md](references/extraction-and-images.md).
- Never invent servings, times or quantities; leave the property out when the page does not say.
- Do not translate. Keep `lang` from the page or `cld2`; if unsure, detect on the directions text.

## Step 3: build the recipe and convert units

Collect `title`, `source`, `lang`, `servings`, `time` (minutes), `ingredients` (groups), `directions` (groups).
Run every ingredient line and every direction step through the converter, with `decimal = ","` for de, sv, fi:

```r
conv <- rn_convert_lines(lines, decimal = ",")   # conv$lines, conv$report (changes and flags)
```

Rules (full table and reasons: [references/units.md](references/units.md)):

- Only non-metric units change. Local metric units (`dl`, `msk`, `tsk`, `krm`, `EL`, `TL`, `rkl`, `tl`, `g`) and
  English tbsp/tsp stay as written; `Prise`, `Messerspitze` and "to taste" are never converted.
- Ambiguous units (German `Tasse`) and `oz` are flagged, not guessed. Volume is never turned into grams without a
  stated reason; say so in the report if the user wants weights.
- Optional ingredients stay in parentheses. Typos in the source are flagged, not silently corrected.
- Ingredients are **ticked** (`- [x]`): ticked means "not on the shopping list", unticked adds the item to the
  Checklist plugin list. Never write `✅` date stamps (the Tasks plugin adds them) and never write `Created_at` or
  `Modified_at` (Templater does).

## Step 4: tags

Propose tags from the dish (type, diet, main ingredient) using only what the profile knows:

```r
rn_check_tags(c("recipe/soup", "recipe/lunch"), pf)   # status: known, mapped, new, invalid
```

`known` and `mapped` go into the note (mapped uses the user's earlier decision). `new` tags are **not** added: list
them under "suggested tags" in the report with the reason, and add them to `pending_new_tags` only when the profile is
written. The user approves with `decisions$approved_new_tags`. Never invent tags that break Obsidian's rules.

## Step 5: picture

- **Link given:** the candidates from `x$image_candidates` (JSON-LD image, then `og:image`). Take the first one.
- **Existing note without a picture:** search for the same recipe with `web_search` (title plus two distinctive
  ingredients, in the note's language), read the top hits with `rn_extract_recipe()`, and accept a page only when
  `rn_ingredient_overlap(note_ingredients, page_ingredients) >= 0.6`. A weaker match gets **no picture and a flag**.
  If the note has a `source` URL, try that page first. Never replace a picture the note already has.
- **Download and embed:** `img <- rn_download_image(url, "output/images", stem = title, referer = page_url)`; the
  note gets `![[file|300]]`, a `cover` property and a hidden `%%Photo: page (image url)%%` line with the credit.
  Photos belong to their authors; the credit line and `source` keep the origin, and the report says so once.

## Step 6: write and check

```r
txt <- rn_render_note(rec, pf)
p   <- rn_write_text(txt, "output", paste0(rn_safe_filename(rec$title), ".md"))   # numbered name if it exists
rn_check_note(p, pf)       # fix every `error`, re-run until clean
```

`rn_write_text(..., overwrite = TRUE)` first copies the old file into `backup/<timestamp>/`. Layout of the note and the
reasons for each choice: [references/note-format.md](references/note-format.md); a rendered example:
[assets/example_note.md](assets/example_note.md).

## Step 7: report

One table per run, short: file, language, source tier and confidence, conversions and flags, picture (origin and
match score), tags used and **suggested new tags**, problems. Then profile changes proposed (new tag decisions,
drift fixes) and what you could not verify. Offer, do not apply: fixes for tag drift in the user's own vault notes
or `.base` file (the skill only reports them).

## Safety rules

1. Never write into the vault, never edit `input/`, never overwrite: existing files are backed up first or a numbered
   name is used. The profile is written only with `confirmed = TRUE` and backed up first.
2. Ask before creating folders, writing the profile or adopting a new tag.
3. Keep the recipe text and wording; change structure, units and metadata only.
4. Be polite to sites: one request at a time, identifying user agent, no logins, no bot-wall workarounds.

## Optional extras

- The official Obsidian CLI can cross-check the vault's tag counts (`obsidian vault=<name> tags counts`; the app must
  be running; the command is `Obsidian.com` in the install folder on Windows). Read-only use only; not needed here.
- For Obsidian syntax details, properties and Bases, use the `obsidian-markdown` and `obsidian-bases` skills when
  installed, else read the upstream files listed in [references/sources.md](references/sources.md). Do not copy them.

## Not verified

Recipe View's thumbnail rule with the image placed before the H1, the Bases card image property name, the `cover`
property in a real vault, Linux and macOS, German and Swedish sites beyond one Swedish page, and real use over many notes.
Tell the user to open one output note in Obsidian before converting a batch.

## Related skills

- `git-for-research-projects`: `.gitignore` for the project's `input/`, `output/`, `backup/` and profile (personal data, pictures).
- `r-reproducible-pipeline`: if the conversion project should become a re-runnable `targets` pipeline with `renv`.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were done or not done: why this method, setting or tool was chosen, which alternative was rejected and why, which check or step was skipped, and which assumptions were made. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a package version or API differs from what it states, or it lacks guidance the task needs, record a generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
