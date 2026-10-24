# Tag profile

What the profile file is, what it records, and how tag drift is handled. The profile is a plain YAML file next to
the output folder (`recipe-profile.yml`), written only after the user agrees.

## Contents

- What it is, in practice
- What it records
- How it is learned and updated
- Tag drift
- New tags
- Editing it by hand

## What it is, in practice

On the first run the skill reads the notes in `input/` and writes down which tags, properties and habits it saw. On
every later run it reads that file first, so a new recipe gets tags from the vocabulary the user already uses instead
of invented ones. It is a memory the user can read and correct, not a hidden database. Delete it and the skill learns
again from the notes.

## What it records

| Key | Meaning |
|---|---|
| `learned_from` | Folder name, number of recipe notes, files skipped as non-recipes (index pages, templates), the `.base` file used |
| `author`, `index_link`, `checkbox_default`, `spoons`, `image_width` | Habits; the user's answers win over learned values |
| `heading_ingredients`, `heading_directions` | English structure headings (Recipe View matches them by name) |
| `note_facts` | Languages seen, property keys, level-2 headings, how many ingredient items are ticked or unticked, notes with template placeholders |
| `tag_vocabulary` | Every valid tag some recipe note carries (placeholder debris such as `{ tag2 }` is excluded) |
| `tag_counts`, `tag_counts_rollup` | Notes per exact tag; and counting child tags under their parents, as Obsidian shows them |
| `review` | Drift findings (below) |
| `decisions` | `tag_map` (tag the user does not want to the tag to use) and `approved_new_tags`; kept across relearning |
| `pending_new_tags` | Suggestions waiting for a yes |

## How it is learned and updated

`rn_learn_profile(dir, base, previous)` reads every `.md` file under `dir`, keeps only recipe notes (tag `recipe`, an
`#ingredients` tag, or a checkbox list), and counts tags from the frontmatter. It detects the language of the
directions text with `cld2` when installed. Passing `previous` keeps the user's decisions and pending tags. Checking
a profile against a Bases file adds the drift findings. The summary for the user is `rn_profile_summary()`.

Obsidian's own counts roll child tags into their parents (`recipe/vegetarian` also counts notes tagged
`recipe/vegetarian/vegan`), so numbers from the Obsidian CLI or the tag pane are higher than raw frontmatter counts.
The profile stores both.

## Tag drift

Drift means two spellings for one idea, or a view that filters a tag no note carries. The report lists, from a `.base`
file's filters and the notes:

- **Base tags no note uses**, each with the nearest used tag when it is plausibly the same idea (edit distance on the
  last path segment, at most 0.5). Example found in the user's vault on 2026-10-24: the base filtered
  `recipe/vegepossible`, `recipe/vegan` and `recipe/veganpossible`, while the notes use
  `recipe/vegetarianpossible`, `recipe/vegetarian/vegan` and `recipe/vegetarianpossible/veganpossible`; three card
  views returned no notes (checked with the Obsidian CLI `base:query`).
- **Tags used but not in the base.**
- **Template debris:** notes whose tags or aliases still hold placeholders like `"{ tag2 }":` (YAML reads these as
  one-key mappings, not as tags).

The skill **reports** drift and proposes a fix: either edit the base filters, or add a `tag_map` decision such as
`recipe/vegepossible: recipe/vegetarianpossible` so new notes use the form the notes already carry. It never edits
the vault's notes or base file.

## New tags

`rn_check_tags()` sorts proposed tags into known, mapped, new and invalid (Obsidian allows letters, digits not first
only, `_`, `-`, `/`, no spaces). A new tag is suggested in the report with the reason, kept in `pending_new_tags`,
and used only after the user approves it (`decisions$approved_new_tags`). Learning the existing structure is the main
goal; suggestions are secondary.

## Editing it by hand

Safe to edit: `decisions`, `author`, `index_link`, `checkbox_default`, `spoons`, `image_width`. Counts and the
vocabulary are rewritten on the next learning run. The file is personal: keep it out of Git (see
`git-for-research-projects`).
