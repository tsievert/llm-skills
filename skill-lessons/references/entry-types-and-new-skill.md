# Entry types and the new-skill template

Moved out of SKILL.md; read it when choosing a `type` value or proposing a new skill.

## Type values and mapping

**Only use the nine `type` values above.** Entries have been written in practice with values
not in the list — `new-script-suggestion` (a new helper script, not a whole new skill),
`gap` and `script-change` — and `lesson_add()`'s `match.arg()` rejects anything else, so these
either failed to write or were hand-edited in after the fact; `skill-feedback-triage`'s
validator then flags every one of them (`type missing or not in the allowed list`). Map them
to an existing type instead of inventing one: a new-script idea is `missing-guidance` (the
`suggested-change` field is where the script idea itself goes), a documentation gap is
`missing-guidance`, and a change to an existing script's behaviour is `bug` (if it was wrong)
or `worked-well` (if the change was confirmed correct). For a long staged or multi-conversation
workflow, write one `use-case` entry per stage/conversation rather than one for the whole
workflow — the per-stage granularity is what let triage see which stage actually had friction.

## Proposing a new skill

A `new-skill-suggestion` entry is different from the rest: it proposes a skill that does not
exist yet, so there is no folder to name. Use the reserved pseudo-name `new-skill` as the
heading's skill slot, and put the proposed skill name in the title:

```markdown
## new-skill: chemical-ecology-data
- type: new-skill-suggestion
- symptom: why this came up (e.g. a procedure inside another skill or project memory file
  that has grown past what it should carry)
- context: what triggered the suggestion, and which existing skill or file it would
  otherwise have gone into
- suggested-change: the proposed scope in a sentence or two, close to what would become the
  skill's `description` frontmatter
- confidence / generality: as usual (is this one project's need, or does it look reusable?)
```

`lesson_add(skill = "new-skill", type = "new-skill-suggestion", ...)` enforces the
pseudo-name and skips the skill-folder check. This entry is never acted on immediately;
writing it here instead of calling `create-skill` directly defers the decision to the next
`skill-feedback-triage` run, so a new skill is only built after review, not on the spot
inside whatever session noticed the need. `agents-md-maintenance` uses this path when
restructuring a project's memory file turns up a procedure that has outgrown it.
