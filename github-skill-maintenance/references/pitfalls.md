# Pitfalls this repo has hit

Contents: YAML description traps, CRLF line endings, links, hooks, naming, frontmatter, heredocs. Moved out of SKILL.md; read it when a lint or edit fails unexpectedly.

- **Unquoted `#` in a description.** YAML ends a plain scalar at ` #`, so "Covers #SBATCH
  directives" silently cuts the description there (verified with two parsers). Quote the
  whole value, or write "SBATCH". Linter check: `description`.
- **No `python` in bash on Windows.** The command resolves to a Store shortcut, so scripted edits fail. Use the `edit` tool or R,
  and do not combine an append and a dependent edit in one command (the first part may apply alone).
- **CRLF in scripts and Markdown.** Tools on Windows can leave CRLF in the working copy even though
  `.gitattributes` forces LF in the index (`git ls-files --eol` shows `i/lf w/crlf`). Symptoms: a script
  copied to the cluster fails, and multi-line `edit` calls report "string not found" while single-line ones work.
  - `.gitattributes` forces `eol=lf` only for `.sh`, `.py`, `.md` and `.R`; a new file type needs its own rule first.
  - Any `edit` or `write` call can reintroduce CRLF, even on an LF file and mid-task. Check
    `git ls-files --eol <file>` before every edit of a file already touched this session, and run
    `git ls-files --eol -o -m --exclude-standard <skill>` before lint and commit.
  - Untracked files: `git ls-files --eol` prints nothing, so use `file <path>`. Do not use `grep -c $'\r'`
    (grep's CRLF autodetection can report 0).
  - Fix with `sed -i 's/\r$//' <file>` in Git Bash. A plain append to a CRLF file may need an explicit `\r\n`.
  - If a multi-line `old_string` still fails with LF confirmed and a fresh `read` matching, retry with a short,
    unique single-line anchor; as a last resort `write(..., overwrite = TRUE)` the whole file, then re-check line
    endings immediately.
- **Colon plus space in an unquoted description, and the 1024 limit.** A `: ` inside a plain-scalar
  description fails with "mapping values are not allowed in this context" (use a dash). Trigger-broadening
  edits on a description near the limit overflow it: trim first and re-run `lint_skills()` after every
  description edit (reported once).
- **Apostrophe in a single-quoted description.** A bare apostrophe (a possessive such as
  "user's") ends the YAML scalar and the linter reports "YAML does not parse". Avoid
  apostrophes in descriptions or double them (`''`), and run `lint_skills()` after every
  description edit.
- **Dead links** between skills after a file is moved or was never created. Linter
  check: `links`.
- **A hook extracting one JSON field with a single-capture `sed` breaks on embedded
  quotes.** `lessons-hook.sh`'s `jstr()` helper is fine for structural fields
  (`session_id`, `tool_name`) but silently truncates a free-text field such as a
  `UserPromptSubmit` `prompt` at the first `\"` inside it. If a hook needs to match a
  pattern against free text, run the match against the whole raw payload instead of trying
  to isolate the field first (see `skill-trigger-hook.sh` at the repo root and
  `hooks-reference.md` (same folder)).
- **`~` in R on Windows** is `Documents`, not the profile directory. The scripts use
  `USERPROFILE`.
- **Name clash with a built-in** (e.g. `report`, `create-skill`): the user copy silently
  wins. Check the built-in list before choosing a name.
- **Description drift.** Descriptions that grow past about 950 characters or lose the
  "Use when" wording trigger less reliably; the linter warns on both.
- **Frontmatter `metadata` values must be flat strings**, never a YAML list (`lint_skills()`
  errors on anything else). Decide this before writing the frontmatter, not after hitting the
  error: if a field needs several values, join them into one delimited string (the `file_signals`
  field uses `'|'`, matching the regex-alternation syntax it is used for) rather than a native
  YAML sequence.
- **Writing files safely (decision table).** Scripted writes are the most common source of silent damage here.

  | Method | Failure | Use instead |
  |---|---|---|
  | `bash` heredoc, `sed`, `Rscript -e` with text that contains a backslash (R regex, `\\(`, `\.`) | the bash tool call loses one level of backslash, even in a quoted heredoc; sourcing then fails with "unrecognized escape" | `write` or `edit` tool; check with `grep -c` for the exact string afterwards |
  | `bash` heredoc with long Markdown plus several `sed -i` in one call | file ends mid-sentence, a later file is never created, no error | `write`/`edit`; if unavoidable one file per call, then `wc -l` and `tail` |
  | R `writeLines()` / `file()` text mode on Windows | writes CRLF | `writeBin(charToRaw(paste0(x, collapse = "\n")), path)` or the `write` tool |
  | R `sub()`/`gsub()` with `\\1` and replacement text containing a backslash | backslash silently dropped or a control byte inserted, no warning | `edit` tool, or `fixed = TRUE` with a literal anchor; then `file <path>` and compare `grep -c "^## "` |

  Order matters for line endings: normalise with `sed -i 's/\r$//'` as the last step after the final `edit` or `write`, and confirm with `git ls-files --eol -m` before commit.
- **A failing testthat run** can leave `_problems/` and `testthat-problems.rds` in the tests folder; they are git-ignored here, but delete them after a failure.

- **Environment caches in skill scripts must not inherit.** `exists("x", envir = cache)` on a
  `new.env()` also searches the parent chain, so a global object with the same name gives a false hit
  and a check silently finds nothing (hit once in the shadowed-name check, 2026-10-30). Use
  `new.env(parent = emptyenv())` and `exists(..., inherits = FALSE)`.

- **A fetched docs page is weak evidence of absence.** Pages carry no version number and can omit topics; record "not mentioned", not "removed", and use release notes as the version-bearing source.
- **Backticked `references/` or `scripts/` paths resolve inside the same skill.** `lint_skills()` reports
  "Referenced path does not exist" when a SKILL.md cites another skill's file that way (reported once,
  2026-11-06). Cite the other skill by name and describe the file in words.
