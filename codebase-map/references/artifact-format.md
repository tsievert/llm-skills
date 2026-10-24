# Artifact format

## Contents

- Location
- `INVENTORY.md`
- `CODEMAP.md`
- `DEPENDS.tsv`
- Internal / external / package classification
- Path resolution rules
- Regeneration header and staleness

## Location

All three artifacts live together in a single directory at the **RStudio project root**
(the directory containing the `.Rproj` file): `.codemap/`. One project, one `.codemap/`
directory, never nested — a subdirectory with its own `.Rproj` is a different project and
gets its own `.codemap/` if it ever qualifies (see the trigger thresholds in
`triggering-and-updating.md`).

```
.codemap/
  INVENTORY.md
  CODEMAP.md
  DEPENDS.tsv
  .state.json      # internal bookkeeping (thresholds last checked, build time) - not for reading
```

`.codemap/` is added to the project's `.gitignore` the first time it's created, if the
project is under version control (see `triggering-and-updating.md`). These are generated
artifacts, not source: never hand-edit them, and never commit them.

## `INVENTORY.md`

One table per top-level directory (plus one for files at the project root), each row one
scanned file. Sorted by descending line count within each directory, so the files most
worth summarising (or splitting up) surface first.

```markdown
# Codebase inventory — <project name>

Generated <ISO timestamp> by the `codebase-map` skill. 42 files, 6,120 lines scanned.
Regenerate: see `.codemap/.state.json` or just keep editing — it updates itself.

## scripts/

| File | Language | Lines | Description |
|---|---|---|---|
| scripts/build_model.R | R | 410 | Fit the candidate GLMMs and cache the best one |
| scripts/clean_data.py | python | 180 | Tidy the raw sensor export into one long table |

## (root)

| File | Language | Lines | Description |
|---|---|---|---|
| README.md | markdown | 60 | |
```

"Description" is the file's first extracted heading (see `language-rules.md`) if it has
one, a leading `#'`/`"""` docstring-style comment if R/Python has neither, or blank. It is
never invented — an empty cell means the file had no heading-like comment to read, which
is itself useful information (a candidate for adding one).

## `CODEMAP.md`

A flat, greppable heading ledger — deliberately **not** a Markdown table, so `grep -n`
(or the agent's own `grep` tool) works on it directly the same way it would on `grep -n`
output from the files themselves:

```
scripts/build_model.R:1: Fit the candidate GLMMs and cache the best one
scripts/build_model.R:40: 1. Load and join the cleaned tables
scripts/build_model.R:88: 2. Candidate model set
scripts/build_model.R:140: 3. Compare by AIC and refit the winner
scripts/clean_data.py:1: def load_raw(path):
scripts/clean_data.py:25: def tidy(df):
```

Format: `<path>:<line>: <heading text>`, one per line, sorted by path then line number.
Intended use: `grep` this file for a keyword before opening the full source file, then
`read` only the needed line range (the ledger gives you the starting line; the next
ledger entry in the same file is a reasonable end-of-section guess).

## `DEPENDS.tsv`

Tab-separated, one row per detected reference, header row included:

| Column | Meaning |
|---|---|
| `file` | the file containing the reference (project-relative path) |
| `kind` | `file-internal`, `file-external`, `package`, or `unresolved` (see below) |
| `target` | resolved project-relative path (`file-internal`), absolute/foreign path (`file-external`), package or module name (`package`), or the literal text that couldn't be resolved (`unresolved`) |
| `raw` | the matched source text, trimmed, for context and manual verification |

```tsv
file	kind	target	raw
scripts/build_model.R	file-internal	scripts/clean_data.R	source("clean_data.R")
scripts/build_model.R	package	glmmTMB	library(glmmTMB)
scripts/build_model.R	package	emmeans	library(emmeans)
scripts/clean_data.py	package	pandas	import pandas
reports/summary.qmd	file-external	../shared-utils/plotting.R	source("../shared-utils/plotting.R")
scripts/old_draft.R	unresolved	build_params	source(build_params)
```

## Internal / external / package classification

| Pattern (per language, see `language-rules.md` for the full table) | Resolution | `kind` if it resolves inside the project root | `kind` if it resolves outside | `kind` if it can't be resolved at all |
|---|---|---|---|---|
| R `source("path")` / `source('path')` | relative to the *calling file's* directory, then the project root | `file-internal` | `file-external` | `unresolved` |
| R `here::here(...)` | join the quoted arguments, relative to the project root (what `here` itself does) | `file-internal` | — (here() is meant to stay inside the project; treat an out-of-project result as `unresolved` rather than guessing) | `unresolved` |
| R `library(pkg)` / `require(pkg)` | not a file at all | — | — | always `package`, target = `pkg` |
| Python `import mod` / `from mod import ...` where `mod` starts with `.` (relative) or matches a `.py` file/package directory in the project | path-from-module-name, relative to the importing file's package | `file-internal` | `file-external` | `unresolved` |
| Python `import mod` / `from mod import ...`, anything else | not resolved as a file | — | — | always `package`, target = top-level module name |
| shell `source file` / `. file` | same as R `source()` | `file-internal` | `file-external` | `unresolved` |
| `#include "file"` | relative to the including file | `file-internal` | `file-external` | `unresolved` |
| `#include <file>` | system header, not a project file | — | — | always `package`, target = `file` |

A non-resolving `source()`/`import` is common and not a bug in the scanner — the argument
may be a variable, built from `paste0()`, or simply not exist yet. `unresolved` rows are
kept (not dropped) because the raw text is still useful context, and because a cluster of
`unresolved` rows pointing at the same literal name is itself informative.

## Path resolution rules

1. Try the path relative to the directory of the file containing the reference.
2. If that doesn't exist, try it relative to the project root (handles the common R
   habit of `source()`-ing with a path that assumes the working directory is the project
   root, e.g. from an interactive console or a `setwd()`'d script).
3. If neither exists, classify as `unresolved`.
4. A resolved path is `file-internal` if it's inside the project root (after resolving
   `..`), `file-external` otherwise (R8: note it, never scan into it).

## Regeneration header and staleness

`INVENTORY.md`'s header line states the generation timestamp and file/line totals so a
reader can tell at a glance how current it is. `.codemap/.state.json` additionally
records the file count and max line count seen at last build (used by the trigger logic
in `triggering-and-updating.md` to decide whether to regenerate) and is not meant to be
read by a person or the assistant — read the two `.md` files and the `.tsv` instead.
