# Codebase navigation / large-project map — research ledger

For a planned skill (name tbd, working title `codebase-map`) that makes a large or
multi-file project (R, Python, or mixed) easy for the assistant to navigate: a file
inventory, cross-file dependency notes, and a greppable heading ledger for long files.
Universal across languages, self-triggering, self-updating, gitignored artifacts.
Not a skill yet — research only, per the "Always protocol research" standing rule.

## 1. Requirements (user decisions)

| # | Decision | Date |
|---|---|---|
| R1 | Universal: must work for R projects, Python projects, and mixed R+Python projects — the workflow/tool choice should be determined per project, not fixed to one language. | 2026-10-24 |
| R2 | Self-triggering: the assistant should decide on its own when a project is big/complex enough to warrant the artifacts, not wait for an explicit "make me an inventory" request. | 2026-10-24 |
| R3 | Self-updating: the artifacts should stay in sync with the project as it changes, without the user asking for a refresh each time. | 2026-10-24 |
| R4 | If the project is under version control, add the generated artifacts to `.gitignore`. | 2026-10-24 |
| R5 | Scope is RStudio projects (`.Rproj`-rooted), not arbitrary files across the system; one ledger/inventory per project. | 2026-10-24 |
| R6 | The user's RStudio projects are mostly loose analysis projects (`.Rproj` + `scripts/`, `data/`, `reports/`), not formal R packages (no `DESCRIPTION`/`R/`/`man/`) — package-aware tools (pkgapi-style, `pkgload`) are not the default path. | 2026-10-24 |
| R7 | When a project mixes R and Python, the two sides are usually separate and mostly independent (not a single call chain through reticulate) — so the dependency scan does not need to trace calls *across* the R/Python boundary as a priority; it can treat each language's files with its own regex table. | 2026-10-24 |
| R8 | The ledger always stops at the project root (`.Rproj` directory boundary); a dependency pointing outside the project is noted/flagged but not followed into the other repo. | 2026-10-24 |

## 2. Why this doesn't clash with an existing skill

Checked `github-skill-maintenance/references/skill-boundaries.md` (2026-10-24): no
cluster owns "make an arbitrary codebase legible to the agent". Closest neighbours own
narrower things: `r-package-development` (package structure), `r-reproducible-pipeline`/
`python-reproducible-pipeline` (pipeline DAGs via targets/Snakemake, not arbitrary file
trees), `git-for-research-projects` (gitignore mechanics, not inventories),
`github-skill-maintenance` (this repo's own skills, not the user's other projects). A new
skill needs hand-off sentences to the pipeline skills (defer to `_targets.R`/`Snakefile`
as the dependency source of truth when one exists) and to `git-for-research-projects` for
the gitignore mechanics.

## 3. Existing tools surveyed (status: search only, none installed/tested yet)

| Tool | What it does | Relevant to this skill? |
|---|---|---|
| **Aider repo-map** (`aider.chat/docs/repomap.html`, `2023/10/22/repomap.html`) | <cite index="24-1,24-2">Tree-sitter based repo map that replaced an earlier ctags-based one, extracting symbol definitions and ranking them</cite>; <cite index="2-16">disabled by default for weaker models because a dense map can confuse them</cite>. | Design lesson only — not a tool we'd shell out to (it's bundled inside aider's own chat loop, not a standalone CLI for our use). Confirms: rank/budget the map, don't dump everything. |
| **Repomix** (`repomix.com`, GitHub `yamadashy/repomix`) | <cite index="10-2,10-3">Packs an entire repository into a single AI-friendly file</cite>, <cite index="19-4">respects .gitignore plus a default-ignore set, counts tokens, runs a Secretlint pass</cite>; <cite index="19-9,19-10">a `--compress` mode uses Tree-sitter to keep only function signatures, cutting tokens 50-80%</cite>; <cite index="19-7">has a watch mode (`-w`, v1.15.0)</cite> and an MCP server exposing `grep_repomix_output`. | Node/npx tool (external, non-R/Python dependency) — closest existing match to "self-updating map with watch mode" but out of scope to depend on (adds a Node requirement to R/Python projects; would need explicit user permission like any non-CRAN/PyPI tool). Noted as prior art, not adopted. |
| **Universal ctags** | <cite index="2-11">Extracts symbol definitions from source files</cite> for many languages including R (confirmed live by fetching the ctags-lang-r man page: functions, `globalVar`/`functionVar`, vector/list/dataframe kinds, with scopes) and Python. | Not installed in this session's shell (`ctags: command not found` on Windows/Git Bash here) — would require the user to install a binary (choco/scoop on Windows), an extra non-R/Python dependency. Candidate as an **optional enhancement**, not the default mechanism. |
| **Tree-sitter-based tools** (`tsag`, `treesitter-symbols`, Aider's own) | Richer than ctags (full signatures, imports, call edges) but each language needs a grammar; `aider` ships `py-tree-sitter-languages` to avoid asking users to install anything. `treesitter-symbols` (Go lib) supports R among 17 languages. | Same conclusion as ctags: real capability exists, but it's an extra toolchain (Node or compiled grammars) beyond what a lightweight, zero-install skill should require by default. |
| **grimp** (Python, PyPI) | <cite index="29-3">Builds a queryable graph of the imports within one or more Python packages</cite>; Rust-backed, fast; needs the target to be `pip install`-able and treated as a package (`grimp.build_graph('somepackage')`), not just a folder of loose scripts. | Good for a proper Python *package*, weak fit for a loose `scripts/` folder of analysis code (the common case here) unless we give it a synthetic package root. |
| **pydeps** | <cite index="32-6,32-7,32-8">Builds a graph of dependencies between Python scripts via modulefinder</cite>, `--show-cycles`, needs Graphviz for the visual but can run without it for raw output. | Works on a single script/folder without a formal package; simpler fit than grimp for ad hoc projects, but still Python-only and needs Graphviz for anything but raw text. |
| **mvbutils::foodweb` / `foodwebr`** (R) | <cite index="42-5">Displays a flowchart of function calls</cite> among functions already **sourced into an R session** — operates on live function objects in an environment, not on files on disk. `pkgapi` (r-lib) gives <cite index="40-2">a function call map including file names and positions for all functions and function calls</cite>, aimed at R packages. | Needs the code loaded/sourced first (foodweb) or a package structure (pkgapi); doesn't directly answer "which script sources/depends on which other script" for a folder of loose `.R` files — that's simpler to get via a text scan for `source()`/`here::here()` calls than by loading everything into R. |

**Conclusion from this round:** every actively-maintained tool for rich, cross-language
symbol maps (tree-sitter, ctags) is an external binary/toolchain we'd have to ask
permission to install, and the Python/R dependency-graph packages above all assume either
an installed package or already-loaded code — neither fits "a folder of scripts, maybe
not a package, self-updating, zero extra installs" well. The pragmatic default is a
**plain regex/text-scan approach**, in the same style already used across this repo's own
hook scripts and the pipeline skills' dependency detection: per-language patterns for
`source()`/`library()`/`import`/`from ... import`/`here::here()`/`#include` etc. This is
approximate (misses dynamic imports) but needs no install, works identically for R and
Python, and is cheap enough to re-run on every save. ctags can be offered later as an
**optional, better-accuracy path** if the user has it or is willing to install it — not
the default.

## 4. Heading/section convention — already present in this very repo

Grepped this repo's own skill scripts (`*.R`, `*.py`) for section-comment patterns before
inventing a new convention. Finding: **RStudio's own code-section syntax is already used
throughout** — a comment line ending in four or more `-`, `=`, or `#` characters (e.g.
`# ---- 3. Share of time in a ROI ... ---------------------------`), which RStudio
natively recognises as a foldable section and lists in its document outline. Examples
found: `animal-behaviour-tracking-analysis/scripts/stats_demo.R`,
`job-opportunity-watch/scripts/jobwatch.R`, `dlc_metrics.py` (banner-style `# ---...---`
even in a `.py` file). This means a heading-ledger generator doesn't need to invent a
convention: grep `^\s*#+.*[-=#]{4,}\s*$` (R/Python/shell-style comments) plus, for
Python specifically, `^def |^class ` and Jupyter/VS Code `# %%` cell markers, plus
Markdown/Quarto `^#{1,6}\s` headings for `.md`/`.qmd`/`.Rmd`. One regex table, no
per-language parser needed, and it rewards/encourages a convention the user (and this
repo) already follows rather than asking them to adopt a new one.

**Open question:** does the same four-dash convention actually drive RStudio's document
outline in Python/Quarto files the same way, or is that strictly an RStudio-for-R thing?
Not yet checked against RStudio's own docs — note for next round.

## 5. Self-triggering and self-updating — hook capability check

Read `assistant.posit.co/docs/features/hooks/` live (2026-10-24). Relevant facts for this
skill's design, none of them specific to any one language:

- **No file-watcher or periodic/timer event exists.** The event table is `SessionStart`,
  `SessionEnd`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop`, `SubagentStart`,
  `SubagentStop`, `Notification` — all tied either to a conversation lifecycle or to a
  **local tool call Posit Assistant itself executes**. There is no hook that fires when a
  file changes on disk outside of the assistant's own `read`/`write`/`edit`/`bash` calls.
  So "self-updating" cannot mean a background watcher; it has to mean "a `PostToolUse`
  hook regenerates the artifact after the assistant's own edits", the same pattern already
  used by this repo's `lessons-hook.sh` and `skill-file-signal-hook.sh`.
- `PostToolUse` can emit `additionalContext` (non-blocking nudge) — exactly the mechanism
  already proven in `skill-file-signal-hook.sh` for nudging a skill load; the same
  mechanism can tell the assistant "the project just crossed the size threshold, an
  inventory was generated at `<path>`" after a `write`/`edit`/`bash` call.
  `hookSpecificOutput.additionalContext` is capped at 10,000 characters per hook and
  25,000 total per event — plenty for a short nudge, not for dumping the whole map.
- A hook has no state of its own beyond what it reads/writes to disk itself (same as the
  existing hooks' throttle-file pattern, e.g. `~/.posit/state/llm-skills-last-check`), so
  "self-updating" realistically means: the hook script does the regeneration itself
  (deterministic, not the LLM), throttled like `scripts/sync-skills.sh` already is, rather
  than asking the model to do it.
- **Self-triggering** (deciding a project is "big enough") is better done the same way:
  a cheap deterministic check in a `PostToolUse` script (count files, check max line
  count) rather than asking the model to notice and remember — consistent with the
  R1/R2-undertrigger lessons already logged in `github-skill-maintenance` (explicit asks
  and content clues are both unreliable for the model to act on by itself across turns).
- `PreToolUse`/`PostToolUse` only fire for tools Posit Assistant executes locally, so a
  hook can see every `write`/`edit`/`bash` call the assistant makes in *this* session —
  it cannot see edits the user makes directly in the RStudio/Positron editor outside the
  assistant's own tool calls. That's an inherent gap: artifacts can go stale from the
  user's own manual edits between assistant turns; the hook can only re-sync on the next
  assistant-driven tool call, not instantly.

**Conclusion:** the self-trigger/self-update story has to be hook + deterministic script,
same architecture as the two existing hooks in this repo, not a new mechanism. This also
means the skill needs a "Where this runs" caveat similar to the HPC skills' rule, but for
a different reason: the hook only reacts to the assistant's own file operations, not to
changes made outside the assistant.

## 5b. Scope correction from the user (2026-10-24) — RStudio projects, not arbitrary files

User clarified: this is **not** for scanning arbitrary files across the system — it's for
files inside an **RStudio project** (`.Rproj`-rooted), and the ledger/inventory would be
**specific to each project** (one artifact set per project, not a global index). This
narrows "universal" to mean "works for whichever mix of R/Python/Quarto a given RStudio
project contains," not "works outside the RStudio-project boundary." User asked whether
`pkgapi` (r-lib, found in section 3) becomes viable given that narrower scope.

**Checked `pkgapi` directly (GitHub, webfetch 2026-10-24): it's a dead end.** The
repository is labelled "WORK IN PROGRESS!" in its own description and was (cite
index="archived, read-only, Oct 8 2026 per the fetched page">archived by its owner</cite>
on 2026-10-08 — no longer maintained. Its one real example of use in the wild
(`r-spatial/evolution`, cite index="49-9">using pkgapi::map_package to establish which
functions in retiring packages are used by their strong reverse dependencies</cite>)
confirms the entry point is `map_package()` — it operates on an **installed R package**
(DESCRIPTION/NAMESPACE/R/ structure), not a loose `.Rproj` folder of scripts. So even
under the narrower RStudio-project scope, `pkgapi` doesn't apply unless the project is
itself a formal package (i.e. the `r-package-development` skill's territory already,
where `pkgapi`-style analysis would be a poor second choice to just archived/dead vs.
actively maintained alternatives anyway). **Conclusion: `pkgapi` is not a viable
foundation — rejected, not pursued further.**

This still leaves the open question of what fraction of the user's real RStudio projects
*are* formal packages vs. loose analysis projects (`.Rproj` + `scripts/`, `R/` without a
`DESCRIPTION`, `data/`, `reports/`, possibly `targets`/`renv`/Quarto as already seen in
this user's own `r-reproducible-pipeline` and `python-reproducible-pipeline` templates) —
that answer changes which tools are even on the table (package-aware tools require a
`DESCRIPTION`; script-folder tools don't care). Asked the user directly rather than
guessing (see chat).

## 5c. Synthesis after R5-R8 — confirms the plain-regex default, narrows further

Three follow-up answers from the user (2026-10-24), combined with the `pkgapi` rejection
in 5b, settle the design direction rather than opening new tool options:

- **R6 (mostly loose, non-package projects)** rules out every package-aware R tool
  surveyed so far (`pkgapi`, and by the same logic `pkgload`/`pkgdepends`/`mvbutils::foodweb`
  run against a loaded package namespace) as the *default* path — they assume a
  `DESCRIPTION`. The skill should still detect a `DESCRIPTION` file and treat that as a
  signal to delegate to `r-package-development`-style tooling instead of (or in addition
  to) the generic scan, but that's a secondary branch, not the main design target.
- **R7 (R and Python usually independent within one project)** means the dependency
  scanner does not need cross-language call resolution (e.g. parsing a `reticulate::py_run_file()`
  argument to connect an R line to a specific Python file) as a first-pass requirement.
  Each language gets its own regex table; an R file that happens to shell out to Python
  (or vice versa) is still worth flagging as an edge if the called path string literally
  appears in a `source()`/`system2()`/`reticulate::py_run_file()`/`uv run` style call, but
  that's a nice-to-have pattern in the same regex table, not a separate resolution engine.
- **R8 (stop at the project root, flag-don't-follow)** simplifies the walker: the file
  scan and the `.gitignore` check both operate purely within one `.Rproj` directory tree;
  an import/`source()` target that resolves outside that tree is listed as an "external
  reference" row rather than triggering a second scan.

Net effect: the plain-regex, zero-install, per-project approach from section 3's
conclusion is now the **confirmed** design, not just the pragmatic default among weaker
options — none of the follow-up answers reopened the tree-sitter/ctags/pkgapi/grimp
options as better fits. Remaining open work is implementation detail (regex tables,
thresholds, artifact format, hook wiring), listed in section 6.

## 5d. Prototype test (round 3, 2026-10-24) — regex scanner run against this repo

Built `tmp-examples/prototype_codemap.R` (git-ignored, not a skill asset yet) and ran it
against this whole repo as the first real test of the section 3/5c design: walk `.R`,
`.py`, `.sh`, `.md`/`.qmd`/`.Rmd`, extract (a) a heading ledger from the dash-comment /
`def`/`class` / Markdown-heading patterns, (b) a flat dependency-edge list from
`source()`/`library()`/`require()`/`here::here()`/`import`/`from ... import`/`#include`,
and (c) a file inventory (path, language, line count, first heading). Final clean run:
168 files, 18,504 lines, 1,110 heading-ledger lines, 99 dependency-ish lines, all three
outputs written to `tmp-examples/CODEMAP_{inventory,headings,deps}.{csv,txt}` (git-ignored).

**Four real bugs found and fixed while building it** — useful lessons for the eventual
skill script, not just this prototype:

1. **Path-prefix stripping broke silently on Windows.** `sub(scan_root, "", path)` used
   the raw (non-regex-escaped) Windows path — with backslashes — as a regex pattern,
   so it never matched and every path stayed absolute. Fix: normalise both sides to
   forward slashes first, then use `fixed = TRUE` rather than treating a filesystem path
   as a regex.
2. **`regexpr()` only returns the first match per line.** A line with several calls on
   it (e.g. `library(httr2); library(xml2); library(rvest); library(readr)`, found in
   this repo's own `jobwatch.R`) only yielded the first `library()` call. Fix:
   `gregexpr()` + `regmatches()` to get every match per line. This under-counted
   dependency edges by more than half in the first run (46 vs. 99 after the fix).
3. **Language detection was case-sensitive in the wrong direction.** The extension was
   lowercased before a `switch()` whose R case label was literally `"R"` (uppercase) —
   so `tolower("R")` → `"r"` never matched, and **every single `.R` file in the repo
   silently fell through to `"other"`**, skipping all R-specific heading and dependency
   rules entirely (R was the only language affected; `.py`/`.sh`/`.md` all happened to
   already be lowercase extensions so this went unnoticed until checked). This is an
   R-specific trap worth calling out explicitly in the eventual skill: don't assume
   case-insensitive extension matching is safe once R is one of the languages, because R
   is conventionally spelled with an uppercase extension unlike every other language
   scanned here.
4. **The dash-heading regex only stripped a *trailing* decorative run.** This repo's own
   convention (seen throughout, e.g. `# ---- 1. links file ----...`) often has dashes on
   **both** sides. Because the title capture is lazy (`(.*?)`), the regex engine extends
   it until the remainder matches the trailing dash run all the way to end-of-line — and
   since the only valid stopping point is before the *final* dash run, the *leading*
   dashes got swallowed into the captured heading text too (e.g. `"---- 1. links file"`
   instead of `"1. links file"`). Fix: explicitly strip an optional leading decorative
   run before the lazy capture.

**What worked without needing a fix:** Markdown/Quarto/R Markdown `#`-heading detection;
`def `/`class ` detection in Python; the overall two-pass walk-then-regex structure: cost
was negligible (well under a second for 168 files/18.5k lines).

**Not yet handled by the prototype (left for the real design, see section 6):**
distinguishing an *internal* file-to-file edge (`source("scripts/dlc_metrics.R")`,
`here::here(...)`) from an *external* package dependency (`library(httr2)`) — the
prototype lists both as one flat "dependency-ish line" list; resolving a relative
`source()` path against the *calling file's* directory vs. the project root (ambiguous
without knowing the working directory at run time — a real limitation of text-scanning,
not just a bug); and capturing only the inner path/package name via the regex's capture
group rather than the whole match text (the raw dump currently includes the surrounding
`source("..."` syntax, which is fine for a first look but not what a clean `DEPENDS.tsv`
column should contain).

## 5e. Skill built (round 4, 2026-10-24) — `codebase-map`

Built the actual skill at `codebase-map/` (SKILL.md; `scripts/build_codemap.R`,
`scripts/codemap-hook.sh`; references `artifact-format.md`, `language-rules.md`,
`triggering-and-updating.md`). Implements sections 5c/5d's design: base-R-only regex
scan, `.codemap/{INVENTORY.md,CODEMAP.md,DEPENDS.tsv}`, internal/external/package/
unresolved classification with real path resolution (calling-file-dir then project-root,
for R `source()`/`here::here()` and Python same-directory/relative imports), a
`PostToolUse` hook for self-triggering (file-count/max-line thresholds) and
self-updating, `.gitignore` and `AGENTS.md`/`DATABOT.md` idempotent insertion (the
AGENTS.md pointer was the user's explicit new requirement this round), and a
`.codemapignore` opt-out.

**Incident during testing (important, not just a lesson for next time):** testing the
hook's project-root walk-up inside a scratch folder nested *inside this very repo*
caused it to correctly find `llm-skills.Rproj` as the enclosing project and for real
create `.codemap/` at the repo root, append a section to the real `AGENTS.md`, and add a
line to the real `.gitignore`. All three reverted immediately (`git checkout --
.gitignore AGENTS.md`, `rm -rf .codemap`) with no lasting change. The behaviour itself
was correct given the design (that folder genuinely is part of the `llm-skills` project);
the real risk it exposed is structural, not a bug: **any** RStudio project — including
this skills-development repo itself, which has an elaborate hand-maintained `AGENTS.md`
— would be auto-edited the first time the assistant touches a file in it, with no
per-project opt-in. Response: added the `.codemapignore` opt-out (checked in both the
hook and the R script, so a direct call behaves the same), documented the incident and
the opt-out prominently in `references/triggering-and-updating.md`, and **did not
register the hook in the live global `settings.json`** — that step needs the user's
explicit go-ahead given what it does to other real projects, unlike the earlier
non-blocking-nudge hooks in this repo. All further testing moved to an isolated scratch
directory outside this repo (`$PA_SCRATCH_DIR/codemap-tests`, deleted afterward), never
nested inside `llm-skills` again.

**Tested (isolated scratch dir, Windows, R 4.6.0, Git 2.55):** full pipeline on a
qualifying synthetic project (9 files, one >300 lines) — hook fires, builds
`.codemap/`, adds the `.gitignore` line, inserts the `AGENTS.md` block, emits exactly one
`additionalContext` nudge; a second call in the same session within 30s is silently
throttled; a tiny one-file project produces no `.codemap/` at all (`CODEMAP_QUALIFIES=0`);
a project with `.codemapignore` is skipped entirely by both the hook and a direct
`build_codemap()` call; a plain folder with no `.Rproj` anywhere above it is silently
ignored; real dependency resolution confirmed for all four `kind`s on hand-built fixtures
(`source("helper.R")` and `here::here("scripts","helper.R")` both resolved to the same
`file-internal` target; `source("../does-not-exist/missing.R")` → `unresolved`;
`source("../../outside-project/shared.R")` pointing at a file that genuinely exists
outside the project → `file-external`; `library(dplyr)` → `package`; same-directory
`import util` and relative `from .util import` both resolved to the sibling `.py` file).
Idempotency confirmed across three successive builds (no duplicate `.gitignore` line, no
duplicate `AGENTS.md` block, `first_build` correctly `TRUE` once then `FALSE` forever
after). `lint_skills()`, `check_skill_links()`, `check_skill_clashes(new=)`,
`skills-ref validate` all clean for `codebase-map` and the three skills given backlinks
(`r-reproducible-pipeline`, `python-reproducible-pipeline`, `git-for-research-projects`);
ownership row added to `skill-boundaries.md`.

**A real false-positive caught by the link checker, documented as a convention, not a
bug:** backticking an external/built-in skill name (`r-package-development`, which is a
default skill, not part of this repo) inside a "Related skills" section trips
`check_skill_links()`'s `unknown-skill` check. Fix was wording, not code: don't backtick
such a name there (matches the existing, previously-undocumented convention already used
by `recipe-notes-formatter` for `obsidian-markdown`/`obsidian-bases`).

**Update, same day:** asked the user explicitly; they chose "register it globally now, but
opt this repo out." Done: an empty `.codemapignore` added at the `llm-skills` repo root,
a new `PostToolUse` matcher group (`write|edit|bash` → `codebase-map/scripts/codemap-hook.sh`,
30s timeout) added to the real `~/.posit/assistant/settings.json` (backed up first to
`settings.json.bak-codemap`; the `edit` tool could not match the target block verbatim for
an unexplained reason — worked around with `sed` into a temp copy, diffed to confirm it
was exactly the intended change, and validated as JSON with `jq` before replacing the real
file, since the R session is sandboxed from reading/writing outside the project and
`python`/`node` weren't reliably available). Re-verified live, with the hook now actually
registered: a synthetic `PostToolUse write` payload with `cwd` set to the real
`llm-skills` repo root produced no `.codemap/` directory and no tracked-file changes,
confirming the opt-out holds under the real configuration, not just the isolated test
harness. Not run: `check_sync_setup()`'s full audit of the live `settings.json` (the R
session's sandboxing prevents reading the real file directly, same limitation noted for
every earlier hook's audit in this repo).

**Not tested:** the hook firing inside a real conversation turn;
Linux/macOS; a project where `DATABOT.md` already exists (only the `AGENTS.md` branch was
exercised); a second, independent real project (only hand-built synthetic fixtures);
whether 15 files / 300 lines are good thresholds in practice; `.qmd`/`.Rmd` embedded-chunk
dependency scanning (code only applies the regex tables, not exercised in a real Quarto
file with actual R/Python chunks); performance on a very large project (hundreds of
files, not just the ~170-file scale already measured in round 3).

## 6. Open research items (not yet done)

- Whether RStudio's outline-from-comment-dashes convention applies to Quarto/`.qmd` and
  Python files the same way as `.R` (check RStudio docs, not yet done).
- Whether universal-ctags is worth offering as an optional accuracy upgrade — needs a
  real install test (Windows: choco/scoop) and a size/complexity comparison against the
  plain-regex approach on one real multi-file project.
- Concrete regex table per language for (a) dependency edges (`source()`, `library()`,
  `here::here()`, `import`, `from … import`, `#include`, Quarto/Rmd `source()` inside code
  chunks) and (b) headings — needs to be written and tested on real files, not just this
  repo's own skill scripts.
- Artifact format and location: single `CODEMAP.md`/`.posit-codemap/` directory at the
  project root vs. one ledger per subdirectory; how it interacts with existing
  user-written docs (`AGENTS.md`, `README`) so it doesn't duplicate content already being
  hand-maintained (this repo already does something similar by hand — risk of the new
  skill fighting with that habit rather than automating it).
- Threshold defaults (file count, line count) — pick defensible starting numbers and let
  the user override, not yet chosen.
- How the artifact gets *read* by the assistant efficiently (grep into it before falling
  back to full file reads) — needs an explicit instruction in the skill body, not just
  the artifact's existence.
- Gitignore mechanics for the new artifact: reuse `git-for-research-projects`'s existing
  append-if-missing pattern (`audit_repo.R`) rather than inventing a new one — not yet
  cross-checked against that script's API.
- No local test run yet of any regex-based prototype on a real multi-file R+Python
  project.

## 7. Log

- 2026-10-24: Round 1. Confirmed no existing skill owns this territory (boundary table
  check). Surveyed aider repo-map, repomix, ctags/tree-sitter landscape, Python import
  graph tools (grimp, pydeps), R function-call graph tools (mvbutils::foodweb, foodwebr,
  pkgapi) via web search — all either need an external toolchain/install or assume an
  installed package/loaded session, neither fitting "zero-install, loose scripts,
  self-updating" well. Found (by grepping this repo's own scripts) that the RStudio
  four-dash section-comment convention is already in active use here, making a
  ready-made, zero-invention heading convention for R/Python files. Fetched the Posit
  Assistant hooks reference live and established that "self-updating"/"self-triggering"
  can only be implemented as a `PostToolUse` hook + deterministic script (no file-watcher
  or timer event exists), reusing the architecture of the two existing hooks in this repo
  rather than a new mechanism. Checked locally: `ctags` is not installed in this
  session's Git Bash/Windows PATH. No skill files written yet; no script prototypes
  tested yet (see section 6 for what's left before implementation).
