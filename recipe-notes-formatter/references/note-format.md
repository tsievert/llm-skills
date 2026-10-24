# Note format

The output layout, and why each part is there. Decisions are the user's (2026-10-24); the skill follows the profile
when it differs.

## Contents

- Layout
- Properties
- Body rules
- Why this differs from the old template
- Interplay with the user's plugins
- Not verified

## Layout

```markdown
---
aliases: []
source: "https://example.org/page"
tags:
  - recipe
  - recipe/soup
author: <note author from the profile>
lang: fi
servings: 4
time: 30
cover: "[[Picture name.jpg]]"
---
![[Picture name.jpg|300]]
%%Photo: https://example.org/page (image https://example.org/img.jpg)%%

# Title
[[000 Cookbook index|Cookbook index]]

> [!note]
> Only if the source has a remark worth keeping.

## Ingredients
#ingredients
- [x] 1 sipuli
- [x] (optional ingredient in parentheses)

### Group name (only when the recipe has groups)
#ingredients
- [x] ...

---

## Directions
1. First step.
2. Second step.
```

A rendered example is in [../assets/example_note.md](../assets/example_note.md); it is produced by `rn_render_note()`.

## Properties

| Property | Rule | Reason |
|---|---|---|
| `aliases` | `[]` or a list | Existing notes use it; keeps links flexible |
| `source` | Page URL, or empty | In existing notes it is mostly empty; the skill fills it for links so the original can be found |
| `tags` | `recipe` plus known tags only | The Bases filters, the index and the shopping list depend on `recipe/...` |
| `author` | The note author from the profile (the user) | The user's decision: author is the note author |
| `lang` | `de`, `en`, `sv`, `fi` (detected, not translated) | Lets Bases and the user filter by language; the text is never translated |
| `servings`, `time` | Numbers, `time` in minutes; left out when the source does not say | Sortable in Bases; shown by Recipe View under the title |
| `cover` | Wikilink of the picture, only when there is one | A card image; the exact property Bases cards read is not verified |
| `Created_at`, `Modified_at` | **Not written** | Left to Templater (user decision); `rn_check_note()` warns if present |

Frontmatter starts on line 1 (Obsidian ignores it otherwise). Use ISO-style plain values; quote strings that
contain `:`.

## Body rules

- **Ticked checkboxes.** In the user's workflow a ticked ingredient is not on the shopping list and an unticked one is.
  The Checklist plugin watches `#todo`, `#ingredients` and `#shopping` with "show checked" off, so only unticked lines
  appear. New notes are therefore fully ticked; the user unticks what they need to buy. Verified in the user's
  vault settings on 2026-10-24. Never add `✅ date` stamps: the Tasks plugin writes them when ticking in the app.
- **`#ingredients` directly above every list**, no blank line between tag and first item (a blank line ends the
  tagged list for the Checklist plugin). Groups get a `###` heading and their own `#ingredients` line.
- **Headings stay English** (`Ingredients`, `Directions`): Recipe View's side column matches headings by name, and
  headings are structure, not recipe text. Everything else stays in the recipe's language.
- **One `---` rule** before Directions, as in the user's notes. Recipe View uses horizontal rules to split steps with
  their own ingredients; a single rule leaves the layout unchanged.
- **Directions as a numbered list** (selectable steps in Recipe View). A source's own numbering is stripped, not doubled.
- **Optional ingredients** stay in parentheses; the skill never drops them.
- **Callout** only for a real remark from the source (tip, storage). No empty `> [!note]`.
- **Picture first.** The image sits before the title so Recipe View can use it as the thumbnail (first image not
  under a heading). The credit is a hidden `%%...%%` comment, visible when editing.
- **File name** = recipe title; `/` becomes " or ", `:` becomes " - ", `? " * < >` are dropped, umlauts kept.

## Why this differs from the old template

| Old template | New | Why |
|---|---|---|
| Servings and time as free text in a callout, in the recipe's language | Numeric properties | Bases and Recipe View can sort and show them; free text in four languages cannot |
| Empty `## Intro` and `## FINISH:` | Dropped | Empty sections only add noise; the skill adds sections that have content (user default) |
| `Created_at` / `Modified_at` written | Left to Templater | User decision |
| Placeholder text such as `{ tag2 }`, `{ alias1 }` left in properties | Never | They break YAML and the tag list |
| Index link as `[[Cookbook base.base]]` or `[[000 Cookbook index|Cookbook index]]` | The profile's most common form | One consistent link |

## Interplay with the user's plugins

- **Recipe View:** no strict format; ingredient lists become checkable, numbered steps selectable, properties show
  under the title, `---` splits steps. Scaling reads quantities at the start of a line or next to a cooking unit;
  decimal commas (`1,5 dl`) are not listed in its docs.
- **Checklist plugin:** builds the shopping list from unticked `#ingredients` items (see above).
- **Bases and Dataview:** the user's `Cookbook base.base` filters `file.tags.contains("recipe/...")`. A tag that no note
  uses gives an empty view; this is why the profile reports drift between a base file and the notes.
- **Templater:** fills timestamps when the note is created by a template; a file created outside Obsidian may not get
  them. If the user wants them, they should say so.

## Not verified

The thumbnail rule with the image before the H1, the property name Bases cards read for images, decimal-comma
scaling in Recipe View, and whether Templater fills timestamps for files copied in from outside.
