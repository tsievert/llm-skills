# Self-triggering and self-updating

## Contents

- What "self-updating" can and can't mean here
- Trigger thresholds
- The hook
- Throttling and the one-nudge-per-session rule
- `.gitignore`
- `AGENTS.md` / `DATABOT.md` discoverability
- Known gap

## What "self-updating" can and can't mean here

Checked `assistant.posit.co/docs/features/hooks/` live (research ledger section 5):
there is no file-watcher or timer/periodic hook event. Every event is tied either to the
conversation lifecycle or to a **local tool call Posit Assistant itself executes**
(`PreToolUse`/`PostToolUse` on `read`/`write`/`edit`/`bash`/etc.). So "self-updating"
means: a `PostToolUse` hook runs a deterministic script after the assistant's own
`write`/`edit`/`bash` calls, and that script decides whether to (re)build the artifacts.
It is not, and cannot be, a background process that notices changes made outside the
assistant's own tool calls (see "Known gap" below). This is the same architecture already
used by this repo's `skill-lessons` and `skill-trigger-hook` hooks — reuse it, don't
invent a second mechanism.

## Trigger thresholds

A project "qualifies" (the skill should generate `.codemap/` the next time its hook
fires) when, among the scanned extensions (`.R .py .sh .md .qmd .Rmd`) under the project
root:

- there are more than **15 files**, OR
- any single file has more than **300 lines**.

These are starting defaults, not validated against a range of real projects yet (open
item). They're deliberately conservative-low (triggering a bit too early costs almost
nothing — the build itself is sub-second — so erring toward "generate it" is safe).
Once `.codemap/` exists for a project, every subsequent qualifying hook firing just
regenerates it; there's no "ungenerate" path if a project later shrinks below threshold
(stale-but-harmless is an acceptable failure mode; delete `.codemap/` by hand if wanted).

## The hook

`scripts/codemap-hook.sh`, registered as a `PostToolUse` handler with matcher
`write|edit|bash`:

1. Read the JSON payload from stdin; get `cwd` and `session_id`.
2. Walk up from `cwd` to find the nearest ancestor containing a `*.Rproj` file. If none
   is found within a small number of levels, exit 0 silently — this skill's scope is
   RStudio projects (the user's own R5 decision), not arbitrary directories.
3. Throttle: skip (exit 0) if `.codemap/.state.json` was last written less than 30
   seconds ago for this project — avoids rebuilding on every keystroke-driven edit in a
   burst of tool calls.
4. Run `Rscript scripts/build_codemap.R "<project root>"`. If `Rscript` isn't on `PATH`,
   fail open silently (same fail-open convention as every other hook in this repo) —
   this skill assumes R is available (it's an RStudio project) but shouldn't break a
   session if the shell's `PATH` doesn't happen to include it.
5. The R script itself decides, using the thresholds above plus the file/line counts it
   just measured, whether this is a *new* qualifying build (first time `.codemap/` is
   created for this project) or a routine refresh, and returns that via its own exit
   code or a one-line stdout marker the hook script checks for.
6. On a *new* qualifying build only, and at most once per `session_id` (tracked in
   `~/.posit/state/codemap-notified/<session_id>.flag`, mirroring the dedupe pattern in
   `skill-file-signal-hook.sh`), emit JSON with
   `hookSpecificOutput.additionalContext` naming the three artifact paths. Routine
   refreshes after the first build are silent — there is no need to tell the assistant
   the map was refreshed every single time a file changes.

## Throttling and the one-nudge-per-session rule

Two independent throttles, for two different reasons:

- **The 30-second build throttle** (step 3 above) exists so a burst of several `edit`
  calls in a row doesn't re-scan the whole project several times in a few seconds.
- **The one-nudge-per-session rule** (step 6) exists so the assistant isn't told
  "the codebase map was just updated" after every single file change — it only needs to
  learn the artifacts exist once, the first time they appear.

## `.gitignore`

If the project root contains a `.git` directory (checked directly, not assumed), and
`.gitignore` doesn't already have a line matching `.codemap/` (checked with a simple
substring/line match, not a full gitignore-semantics parser — good enough for a single,
simple, literal directory name), append:

```
# codebase-map skill artifacts (auto-generated, do not commit)
.codemap/
```

This mirrors the append-if-missing pattern already used in `git-for-research-projects`'s
`audit_repo.R`, reimplemented here rather than imported, to keep this skill's script
self-contained (no cross-skill script dependency). If the project is not under version
control at all, nothing is written — there's no `.gitignore` to keep in sync with.

## `AGENTS.md` / `DATABOT.md` discoverability

The artifacts are useless if the assistant doesn't know to look for them in a future
session — generating files nobody is told about is exactly the "fighting with the user's
own habit of hand-written project memory" risk flagged as an open item in the research
ledger. So every build also writes (or updates) a marked section in the project's memory
file:

1. Look for `DATABOT.md` at the project root, then `AGENTS.md`. Use whichever exists; if
   neither exists, create `AGENTS.md` (the more common of the two memory filenames,
   per the system prompt's own documentation) with just this section — don't invent
   other project-memory content.
2. Look for an existing `<!-- codemap:start -->` ... `<!-- codemap:end -->` block.
   - If found, replace only the text between the markers (idempotent — never duplicates
     the section on repeated builds, never touches anything else the user wrote).
   - If not found, append the marked block at the end of the file, preceded by a blank
     line.
3. The block itself (filled in with real counts/timestamp at build time):

   ```markdown
   <!-- codemap:start -->
   ## Codebase map (auto-generated by the `codebase-map` skill — do not hand-edit)

   This project has machine-generated navigation aids in `.codemap/`, refreshed
   automatically as files change (42 files, 6,120 lines as of 2026-10-24T18:03:00):

   - `.codemap/INVENTORY.md` — every scanned file with language, line count and a
     one-line description. Start here for an overview.
   - `.codemap/CODEMAP.md` — a greppable heading ledger (`path:line: heading`). Grep
     this for a keyword before reading a long file in full.
   - `.codemap/DEPENDS.tsv` — file-to-file and file-to-package dependency edges
     (`file-internal`, `file-external`, `package`, `unresolved`). Check this before
     editing a file other files may depend on.
   <!-- codemap:end -->
   ```

This is the step the user explicitly asked for (2026-10-24): without it, the artifacts
exist on disk but nothing tells a future assistant session — or a human — that they're
there or what they mean.

## Opt-out: `.codemapignore`

An empty `.codemapignore` file at a project's root disables this skill for that project
entirely — the hook exits silently before even calling `Rscript`, and `build_codemap()`
itself checks for it too (so a direct call behaves the same as the hook-triggered one).
No `.codemap/` directory, no `.gitignore` edit, no `AGENTS.md`/`DATABOT.md` edit.

This exists because of a real incident during development (ledger section 5e): testing
the hook's "walk up to the nearest `.Rproj`" logic inside a scratch folder that was
nested *inside this very skills repo* caused it to correctly find `llm-skills.Rproj` as
the enclosing project and regenerate `.codemap/` **at the real repo root**, appending a
section to the real `AGENTS.md` and a line to the real `.gitignore` (both reverted
immediately — no lasting change). The behaviour itself was correct (that folder really is
part of the `llm-skills` RStudio project); the risk is structural: **any** RStudio project
gets auto-modified the moment the assistant makes a `write`/`edit`/`bash` call anywhere
inside it, with no per-project opt-in. A project that already has an elaborate,
hand-maintained `AGENTS.md` (this repo is itself an example) is exactly the case where an
automatic edit is least welcome. `.codemapignore` is the escape hatch; the user should
decide per project (including, possibly, this one) whether to use it.

## Why "once ever," not "once per session," is enough

The nudge only fires on the build that *creates* `.codemap/` for a project (`first_build`
in the script, which is simply `!dir.exists(".codemap")` before writing) — not on every
session that happens to be the first to touch a project with artifacts already present.
That's deliberate, not a gap: once `AGENTS.md`/`DATABOT.md` has the pointer section (added
by that same first build), Posit Assistant's own memory system loads it automatically at
the start of every future session in that project — the hook doesn't need to repeat
itself. The nudge exists only to cover the one moment a hook-triggered edit can't: the
*current* session's memory was already loaded before this turn's edit added the pointer
section, so without the nudge the assistant wouldn't find out until the *next* session.

## Known gap

The hook only reacts to tool calls **the assistant itself makes**. It cannot see:

- edits made directly in the RStudio/Positron editor between assistant turns,
- files changed by code the assistant ran (e.g. a `targets` pipeline writing new
  scripts) unless that happened via the assistant's own `bash`/`write`/`edit` tools,
- changes made by a different tool entirely (git pull, another process).

So the artifacts can go stale between assistant-driven turns. The mitigation is cheap
regeneration (sub-second) on the *next* assistant-driven `write`/`edit`/`bash` call,
not a guarantee of always-current state. This should be stated plainly to the user
rather than implied to be a real-time watcher.
