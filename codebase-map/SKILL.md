---
name: codebase-map
description: 'Generates and self-updates a navigation aid for a large or multi-file RStudio project (R, Python, or a mix): `.codemap/INVENTORY.md` (every file with language, line count, one-line description), `.codemap/CODEMAP.md` (a greppable heading ledger -- grep it before reading a long file in full), and `.codemap/DEPENDS.tsv` (file-to-file and file-to-package dependency edges, classified internal/external/package). Self-triggers once a project crosses a size threshold and self-updates via a hook after the assistant''s own file edits; adds a pointer section to the project''s AGENTS.md/DATABOT.md so future sessions discover it, and adds `.codemap/` to `.gitignore`. Use when the user asks to inventory, map, outline, index or summarise a project''s files, asks which files depend on which, or when an existing `.codemap/` needs explaining or regenerating. Does not replace `r-package-development` for formal R packages or the pipeline skills'' own DAG (`_targets.R`, `Snakefile`) when one already exists.'
---

# Codebase map

Regex-based, zero-install file inventory, heading ledger and dependency graph for one
RStudio project at a time (the directory containing a `.Rproj` file). Built because large,
loose analysis projects (the common case for this user: `.Rproj` + `scripts/`, no
`DESCRIPTION`) have no single existing tool that gives an agent a cheap map of "what files
exist, what do they contain, what depends on what" without an external toolchain
(ctags, tree-sitter, Node) or a formal package structure. See
`research/codebase-navigation-ledger.md` in this repo for the full design history,
including the tools that were tried and rejected (`pkgapi`, archived and package-only;
`repomix`, Node-only; ctags/tree-sitter, need an external install).

## Scope

RStudio projects only (per the user's own decision, 2026-10-24) — not arbitrary
directories, and not a cross-project index. One project, one `.codemap/`. If the project
has a `DESCRIPTION` file (a formal R package), prefer `r-package-development`'s own
tooling for anything package-specific; this skill still works on it (loose scripts and
packages scan the same way) but doesn't replace package-aware analysis. If the project
already has `_targets.R` or a `Snakefile`, that file is the authoritative dependency graph
for the pipeline it defines — this skill's `DEPENDS.tsv` is a textual approximation
alongside it, not a replacement (hand off to `r-reproducible-pipeline` /
`python-reproducible-pipeline` for the DAG itself).

## What gets generated

Three files in `.codemap/` at the project root — format, classification rules and worked
examples are in `references/artifact-format.md`:

- **`INVENTORY.md`** — one table per directory, every scanned file with language, line
  count and a one-line description (its first extracted heading). Sorted by line count
  within each directory, so the files most worth summarising surface first.
- **`CODEMAP.md`** — a flat, greppable `path:line: heading text` ledger covering RStudio's
  own dash-comment section convention, Python `def`/`class` lines, and Markdown/Quarto/R
  Markdown headings. Grep this for a keyword before reading a long file in full; the line
  number is a starting point for a targeted `read` with `offset`.
- **`DEPENDS.tsv`** — one row per detected `source()`/`library()`/`import`/`here::here()`
  etc. reference, classified as `file-internal` (resolves to a file inside the project),
  `file-external` (resolves outside it — noted, never followed), `package` (not a file at
  all — a CRAN/PyPI/stdlib name), or `unresolved` (couldn't be resolved, kept anyway
  because the raw text is still useful context). See `references/language-rules.md` for
  the exact pattern table per language and its known traps.

Scanned extensions: `.R .py .sh .md .qmd .Rmd`. The scan is a plain-text regex pass, not a
parser — approximate by design (see `references/language-rules.md`'s "deliberately not
covered" section), chosen over ctags/tree-sitter specifically because it needs nothing
beyond base R and runs in well under a second on a multi-hundred-file project.

## Self-triggering and self-updating

A project "qualifies" once it has more than 15 scanned files or any single file over 300
lines; `.codemap/` doesn't exist before that point. Once created, it's refreshed
automatically (not regenerated from scratch by the assistant each time) via a
`PostToolUse` hook that calls `scripts/build_codemap.R` after the assistant's own
`write`/`edit`/`bash` calls. Full mechanics, the two throttles, the `.gitignore` and
`AGENTS.md`/`DATABOT.md` insertion logic (idempotent — never duplicates on repeated
builds), and a documented near-miss from development (the hook correctly, and
alarmingly, auto-edited this very skills repo's own `AGENTS.md` during an isolation
mistake in testing) are all in `references/triggering-and-updating.md`. **Read that file's
"Known gap" and "Opt-out" sections before relying on this for a project with an elaborate
hand-written `AGENTS.md`** — an empty `.codemapignore` file at a project's root disables
the whole mechanism for it.

**The hook is not installed by default.** Wiring it into `~/.posit/assistant/settings.json`
(or a project's own settings file) is a deliberate step — ask the user before registering
it globally, since it means every qualifying RStudio project the user opens gets
auto-generated artifacts and an auto-edited memory file the moment the assistant touches
any file in it. Registration:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "write|edit|bash",
        "hooks": [{ "type": "command", "command": "bash <path-to-this-skill>/scripts/codemap-hook.sh" }]
      }
    ]
  }
}
```

## Manual use

To generate or force-refresh the map for a project without waiting for the hook (e.g. a
project that hasn't crossed the threshold yet, or to see the artifacts immediately):

```r
source("<path-to-this-skill>/scripts/build_codemap.R")
build_codemap("path/to/project")   # finds the enclosing .Rproj automatically
```

`build_codemap()` returns (invisibly) a list with `inventory` and `depends` data frames
for direct inspection in the console, plus `qualifies`/`first_build` flags. Passing a
directory that isn't inside an RStudio project still works (falls back to that directory
literally) — useful for testing, but outside this skill's intended scope.

## Related skills

- r-package-development (a built-in skill, not part of this repo): formal R packages
  (`DESCRIPTION`/`R`/`man`/`tests`) — prefer its own tooling for package-specific
  questions; this skill still scans a package's files the same way as any other project.
- `r-reproducible-pipeline` / `python-reproducible-pipeline`: when a project already has
  `_targets.R` or a `Snakefile`, that's the authoritative dependency graph for the
  pipeline; `DEPENDS.tsv` here is a textual approximation alongside it, not instead of it.
- `git-for-research-projects`: general `.gitignore`/repository hygiene; this skill only
  ever appends one specific, narrow line (`.codemap/`) and reuses the same
  append-if-missing pattern as that skill's `audit_repo.R`, reimplemented here to keep
  this skill's script self-contained.
- `github-skill-maintenance`: the hook architecture (`PostToolUse`, `additionalContext`,
  fail-open, per-session dedupe state under `~/.posit/`) follows the same pattern as this
  repo's own skill-lessons and skill-trigger-hook hooks — see that skill's own
  skill-trigger-hook.md reference for the general hook design this one reuses.
- `agents-md-maintenance`: owns general hygiene of the rest of a project's
  `AGENTS.md`/`DATABOT.md` (bloat, staleness, structure). This skill only ever touches its own
  narrow pointer section to `.codemap/`; hand off for everything else in the file.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this
skill, say briefly why things were or were not done: why a dependency row is `unresolved`
rather than guessed at, why a project crossed (or hasn't crossed) the size threshold, why
an edit landed in `AGENTS.md` rather than `DATABOT.md` (whichever already existed), and
why the hook needs the user's explicit go-ahead before being registered globally rather
than being switched on silently. Keep each explanation to a sentence or two, name the
trade-off, and point to a reference file for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails,
the user corrects it, a package version or API differs from what it states, or it lacks
guidance the task needs, record a generic, anonymised entry by following the
`skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved
and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for
later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
