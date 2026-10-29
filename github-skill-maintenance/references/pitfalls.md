# Pitfalls this repo has hit

Contents: YAML description traps, CRLF line endings, links, hooks, naming, frontmatter, heredocs. Moved out of SKILL.md; read it when a lint or edit fails unexpectedly.

- **Unquoted `#` in a description.** YAML ends a plain scalar at ` #`, so "Covers #SBATCH
  directives" silently cuts the description there (verified with two parsers). Quote the
  whole value, or write "SBATCH". Linter check: `description`.
- **CRLF in scripts and Markdown.** Tools on Windows can leave CRLF in the working copy even
  though `.gitattributes` forces LF in the index (`git ls-files --eol` shows `i/lf w/crlf`). A
  script copied to the cluster from the working copy then fails, and multi-line string
  replacements in `SKILL.md` or reference files report "string not found" while single-line
  ones work. Run `git ls-files --eol <file>` before a multi-line edit. Fix with
  `sed -i 's/\r$//' <file>` in Git Bash. `.gitattributes` only forces `eol=lf` for `.sh`, `.py`,
  `.md` and `.R`; a new file type needs its own rule added there first. CRLF also comes back
  *after* a clean edit (a `write` or `edit` call can reintroduce it even on an already-LF file),
  and this can bite mid-task, not just at commit time — a later `edit` on the same file can fail
  with "string not found" purely because the prior `edit`/`write` call put CRLF back. Treat
  `git ls-files --eol <file>` as a near-default check before *every* edit attempt on a file this
  session has already touched, not only reactively after a failure; also check again at the end
  of a batch, not only before: run `git ls-files --eol -o -m --exclude-standard <skill>` (covers
  new and modified files, not just the one you just touched) before lint and commit. If a
  multi-line `old_string` still fails to match after confirming the file is LF and a fresh
  re-read looks byte-identical, retry with a shorter, unique single-line anchor from the same
  spot rather than repeating the same large string — this has worked even when the root cause of
  the mismatch was not CRLF and stayed unexplained. A plain-text append to an already-CRLF file
  can also need an explicit `\r\n` separator, since incremental edits can leave LF-only spans
  inside an otherwise-CRLF file. Don't check for stray CRLF with `grep -c $'\r'`: grep's own
  CRLF autodetection can mask the count and report 0 matches on a file that still has CRLF
  (reported once, 2026-10-24); `git ls-files --eol` is the reliable check, as above. For a file
  not yet tracked by git (new, uncommitted), `git ls-files --eol` prints nothing at all rather
  than flagging a problem, which can look like "nothing to check" when the file is actually
  CRLF — use `file <path>` instead for untracked files (reported 2026-10-26). If a multi-line
  `edit` keeps reporting "string not found" against text a fresh `read`/`grep` confirms is
  present byte-for-byte, and CRLF is ruled out, falling back to `write(..., overwrite = TRUE)`
  with the full file content is a reliable escape hatch — but that `write` call itself commonly
  reintroduces CRLF on a file that was LF before it, so always re-check line endings (`file
  <path>` if untracked) immediately after, not just before, the next edit (reported 2026-10-26).
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
  `skill-trigger-hook.md` (same folder)).
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
- **Long Markdown through a bash heredoc can be silently truncated.** A reference file written
  with a `cat <<'EOF' > file` heredoc, combined in the same `bash` call with several `sed -i`
  edits (and once, an `Rscript -e` script using regex backslashes), ended mid-sentence, and a
  later file in the same command was never created, with no error surfaced (reported once,
  2026-10-27). Write multi-line Markdown or R with the `write`/`edit` tools instead of a bash
  heredoc; if a heredoc is unavoidable, keep it to one file per `bash` call and check `wc -l`
  plus a `tail` of the result afterwards. Keep `sed` to single-line changes only.
