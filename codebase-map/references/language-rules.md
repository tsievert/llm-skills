# Per-language regex rules

## Contents

- Why regex, not ctags/tree-sitter
- Scanned extensions and known traps
- Heading patterns
- Dependency patterns
- What's deliberately not covered

## Why regex, not ctags/tree-sitter

Prototyped and compared against `universal-ctags`, tree-sitter-based tools (aider's repo
map, `repomix --compress`), and package-aware R tools (`pkgapi`, archived) in
`research/codebase-navigation-ledger.md` (sections 3, 5b). All of them either need an
external binary/toolchain install (ctags, Node for repomix, compiled tree-sitter
grammars) or assume a formal package structure. Given this skill's scope — loose,
non-package RStudio projects (see the user's own R5/R6 decisions in the ledger) — a
zero-install, per-line regex scan is the right default: approximate (it can't resolve
dynamic `source(paste0(...))` calls or truly understand scope), but it needs nothing
beyond base R, runs in well under a second on a multi-hundred-file repo (measured:
168 files / 18,500 lines in under 1s), and — as the prototype run showed — the headings
it needs are usually already there, because this convention (RStudio's dash-comment
sections) is one the user already follows.

## Scanned extensions and known traps

| Extension | Language tag | Trap found in the prototype (round 3) |
|---|---|---|
| `.R` | `R` | **Case matters.** R's own extension is conventionally uppercase. Lowercase the extension for comparison *and* use the lowercase case label in the dispatch (`r = "R"`, not `R = "R"` after lowercasing) — getting this backwards silently drops every `.R` file into "unhandled" with no error. This bit the first prototype run (section 5d of the ledger) and is worth a code comment at the dispatch site, not just this note. |
| `.py` | `python` | — |
| `.sh` | `shell` | — |
| `.md` | `markdown` | — |
| `.qmd` | `quarto` | Run *all* language dependency patterns (R, Python, shell) against `.qmd`/`.Rmd` files too, not just the Markdown heading pattern — a code chunk can use any engine, and there's no cheap way to know which without parsing fence headers. The small risk of a false-positive match inside prose text is acceptable; in practice `source(`, `library(`, `import ` essentially never appear in English prose. |
| `.Rmd` | `rmarkdown` | Same as `.qmd` above. |

## Heading patterns

| Language(s) | Pattern (R regex, PCRE) | Notes |
|---|---|---|
| R, Python, shell | `^\s*#+\s*[-=#]*\s*(.*?)\s*[-=#]{4,}\s*$` | RStudio's own foldable-section convention (`# Title ----`), but this user's scripts often decorate *both* sides (`# ---- Title ----`). The leading `[-=#]*` strip is required — without it the lazy capture swallows the leading dashes into the heading text (ledger 5d, bug 4). Also matches `# Title ====` and `# Title ####` banner styles. |
| Python only | `^\s*(def \|class )` | Keep the whole matched line (trimmed) as the heading text — the signature itself is more useful here than a stripped name. |
| Markdown, Quarto, R Markdown | `^(#{1,6})\s+(.*)$` | Standard ATX headings. Quarto/R Markdown prose and R/Python code-chunk comments can both appear in the same file; this pattern only fires on lines starting with `#` *outside* an indented/fenced code block in spirit, but the scanner does not actually track fence state (see "deliberately not covered" below) — a commented-out Markdown-style line inside a code chunk could false-positive. Rare in practice; not worth the complexity of fence-tracking for a first version. |

A file's "first heading" (used as `INVENTORY.md`'s one-line description) is whichever of
the above fires first, in file order — including a Python `def`/`class` line if the file
has no comment-style heading above it, which is a deliberate fallback, not an error.

## Dependency patterns

| Language | Pattern | Captures |
|---|---|---|
| R | `source\(\s*["']([^"']+)["']` | group 1 = the quoted path |
| R | `\bhere::here\(([^)]*)\)` | group 1 = the raw argument list (joined and quote-stripped before resolution) |
| R | `\b(?:library\|require)\(([A-Za-z0-9._]+)\)` | group 1 = package name (works for both quoted and bare-symbol calls since the character class excludes quotes, which just get skipped) |
| Python | `^\s*import\s+([A-Za-z0-9_.]+)` | group 1 = module path |
| Python | `^\s*from\s+(\.*[A-Za-z0-9_.]*)\s+import` | group 1 = module path, may start with one or more `.` for relative imports (`from . import x`, `from ..utils import y`) |
| shell | `^\s*(?:source\|\.)\s+([^\s;]+)` | group 1 = path |
| any | `#include\s*(["<])([^">]+)[">]` | group 1 = delimiter (`"` → resolve as file, `<` → always `package`), group 2 = path/header name |

**Fixed from the prototype (ledger 5d, bugs 1–2):** extract with `gregexpr()` +
`regmatches()`, not `regexpr()` — a single line with several calls
(`library(a); library(b); library(c)`) only yields one match under `regexpr()`, silently
undercounting. And capture only the **group**, not the whole match text, so `DEPENDS.tsv`'s
`target` column holds a clean path/package name rather than `source("path"` fragments.

## What's deliberately not covered (v1)

- **Fence-aware chunk scanning in `.qmd`/`.Rmd`** — patterns run over the whole file,
  not just inside code fences (see the Quarto/R Markdown trap above).
- **Dynamic references** — `source(file.path(dir, "x.R"))`, `source(params$script)`,
  `importlib.import_module(name)` are invisible to a regex scan. These show up (if at
  all) as `unresolved` rows with the literal non-quoted text, which is honestly labelled
  rather than guessed at.
- **Cross-language calls** — a `reticulate::py_run_file("x.py")` or `uv run` call from R
  is not specifically pattern-matched in v1 (the user's own R7 decision: R and Python
  sides of a project are usually independent, so this wasn't prioritised). Revisit if a
  real project needs it.
- **Resolving `library()`/`import` against what's actually installed** — a `package` row
  is just the name as written; the skill does not check whether it's on CRAN/PyPI,
  already installed, or even spelled correctly. That's `renv`/`uv`/`pkgdepends`'s job.
