---
name: github-skill-maintenance
description: Maintains the llm-skills GitHub repo of custom skills. Lints skills against the Agent Skills spec and the repo's standing rules (teaching section, HPC "Where this skill runs", links, CRLF, truncated descriptions), finds overlapping skill scopes (clashes) and stale package-version claims, audits the auto-sync hook and skills.paths config, and guides testing, commit and push of skill changes. Use when the user asks to check, lint, validate, review, test, update, release or sync skills, asks why a skill is not loading or not triggering, or wants a periodic skill health check.
metadata:
  version: "1.0"
---

# GitHub skill maintenance

Applies to the repo at the working directory root (one folder per skill, synced from
GitHub into Posit Assistant via `skills.paths` and a SessionStart hook; see the project
`AGENTS.md`). The project working rules apply: look up the current spec and docs online
before changing skill files or hook config, and check CRAN for a package before
hand-writing a helper (installing from CRAN or Bioconductor is allowed; GitHub or
R-universe needs the user's permission first).

## Workflow

Run the cheap checks first, in this order. Report findings as a short table; do not edit
skills unless asked, because findings in other skills are the user's decision. Offer a fix
and say what it would change.

1. **Lint.** From the repo root in the R console:
   ```r
   source("github-skill-maintenance/scripts/lint_skills.R")
   lint_skills()                     # or lint_skills(skills = "gam-mgcv")
   ```
   Errors break the spec or a standing rule, warnings are likely problems, info is for
   judgement. Output columns: skill, level, check, message.
1b. **Cross-skill links.** Skills should point to each other where a user would plausibly need the
   neighbour, and links should go both ways unless there is a reason not to:
   ```r
   source("github-skill-maintenance/scripts/check_skill_links.R")   # uses find_repo_root() from lint_skills.R
   check_skill_links()               # scope = "all" also counts mentions in references/ and scripts
   ```
   Findings: `one-way` (A names B, B does not name A; the `skill` column is the one that would
   get the backlink), `unknown-skill` (a backticked name in a "Related skills" or "Next skills"
   section that is not a skill here), `isolated` (no links in or out). A one-way link is a
   **decision, not a defect**: ask whether someone using B would plausibly need A. If yes, add a
   one-line pointer to B's "Related skills" section in B's existing wording. If no, record a
   `no-backlink` row with a reason in `references/link-decisions.tsv` so it is not raised again.
   Never bulk-add backlinks: generic skills (the `hpc-*` set, `openalex`) should not accumulate a
   pointer to every domain skill that uses them. Hub skills (this one, `skill-lessons`,
   `skill-feedback-triage`) and the boilerplate "Explain the reasoning" and "Capture lessons"
   sections are ignored. The check is textual: it sees a name, not whether the link makes sense.
1c. **Scope clashes.** Skills whose descriptions claim the same requests load together or get mixed up.
   ```r
   source("github-skill-maintenance/scripts/check_skill_clashes.R")
   check_skill_clashes()                  # or check_skill_clashes(new = "my-skill")
   ```
   Flags pairs with similar description vocabulary (IDF-weighted cosine, default threshold 0.15) and
   whether the descriptions name each other (`handoff`: none, one, both). `warn` (no hand-off) needs a
   decision: reword, add a hand-off sentence, or record `accepted` with a reason in
   `references/clash-decisions.tsv`. Run it for every new or changed skill. The ownership table and
   description-writing rules are in [references/skill-boundaries.md](references/skill-boundaries.md);
   update the table when adding a skill. The score is lexical: it cannot see meaning and cannot prove
   triggering (that needs the queries in step 5).
2. **Independent spec check.** `uvx --from skills-ref agentskills validate <skill-dir>`
   (PyPI `skills-ref`, the reference validator; its README calls it a demonstration
   library). The bare command `uvx skills-ref` fails on Windows; use `--from`. It accepts
   a skill the linter rejects (it does not see the truncated-description problem below).
3. **Version claims.** When asked for a periodic check, or after a package release:
   ```r
   source("github-skill-maintenance/scripts/check_versions.R")
   check_versions()                  # offline = TRUE skips CRAN/PyPI lookups
   ```
   It lists "name version" claims for packages that are installed or backticked, against
   the installed and current CRAN/PyPI versions. "Claim older than latest" is not an error
   ("tested with X" is a valid statement); it means re-test or reword. Plain-text names of
   packages that are not installed are skipped on purpose, and `deeplabcut` is only found
   when written as `deeplabcut <version>`. Treat it as a candidate list.
4. **Sync and hook setup.** Read-only audit of settings, the sync hook, the lessons hooks
   (PostToolUse `skill` and Stop), the skill-trigger hook (UserPromptSubmit, PostToolUse
   `skill`, Stop) and the file-signal hook (PostToolUse `skill` and `read|grep|bash`; see
   [references/skill-trigger-hook.md](references/skill-trigger-hook.md) for both),
   the data folders, stamp and git state:
   ```r
   source("github-skill-maintenance/scripts/check_sync_setup.R")
   check_sync_setup(fetch = TRUE)
   ```
   If R cannot read `~/.posit/assistant/settings.json` (the R session may block paths
   outside the project), do not work around it: ask the user to paste the file, parse it
   with `jsonlite::fromJSON(text = ..., simplifyVector = FALSE)` and pass the list as
   `cfg =`. Facts and the reasoning behind each setting:
   [references/sync-and-config-facts.md](references/sync-and-config-facts.md).
5. **Test behaviour** only for new or changed skills, or one that misfires: description
   trigger queries and a with/without comparison. Protocol and a query template:
   [references/testing-skills.md](references/testing-skills.md) and
   `assets/trigger-queries.template.json`.
6. **Release.** Re-lint, then `git status`, commit with a message that names the skill and
   the change, push to `origin/main`. Update `AGENTS.md`'s todo table (status) and add a
   Log entry to `HISTORY.md` (what changed, what was tested, what was not). A pulled skill
   is used from the next conversation, and the sync hook picks changes up within 24 h per
   machine.

## Pitfalls this repo has hit

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
  inside an otherwise-CRLF file.
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
  [references/skill-trigger-hook.md](references/skill-trigger-hook.md)).
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

## What the linter does not judge

Content quality, correctness of the statistics or code in a skill, whether a skill
triggers, and whether claims are true. Those need the testing protocol or the user's
domain judgement. `lint_skills()` also never contacts the network.

## Tested and not tested

Run against the 13 skills in this repo on Windows (R 4.6.0): it found the truncated
`hpc-job-scripts` description, three CRLF working-copy scripts, and one dead link in
`mixed-models-glmm`. `check_versions()` ran with CRAN and PyPI lookups. `check_sync_setup()`
was tested with synthetic good and bad `cfg` lists (clone missing from paths, no defaults,
missing script, `useHooks = "none"`, no stamp) and live git state; reading the real
`settings.json` from R was blocked by the session guard, so that code path is untested in
this session. Not tested: Linux or macOS, `bash -n` on non-Windows, the manual trigger
protocol end to end, a second machine. The lessons-hook audit was tested with synthetic
good and bad `cfg` lists (wrong matcher, `async` field, wrong script path, missing hooks)
and a synthetic lessons folder; it has not seen the real `settings.json` (blocked, see above).
The skill-trigger hook (`skill-trigger-hook.sh` at the repo root, added 2026-10-24) was tested with
twelve synthetic piped payloads (no match, explicit match, block-once, silent repeat,
cleared-by-skill-load, `stop_hook_active` loop guard, missing `session_id`, embedded-quote
prompt, a question near-miss, `DEBUG` logging, and malformed/empty stdin) and its
`check_sync_setup()` audit was run against the real `settings.json` content (read with
`bash`/`cat` and passed as `cfg`, the same path-guard workaround as above) after the file
was updated to register it. Not tested: firing inside a real conversation turn, `SubagentStop`.
The file-signal hook (`skill-file-signal-hook.sh`, added 2026-10-24, the non-blocking R2
counterpart) was tested with synthetic piped payloads (nudge on a matching `read`/`grep`
result, silence on a repeat, on an already-loaded skill, on unrelated content, and on a
non-matching tool; embedded-quote content; missing/malformed stdin) and its own
`check_sync_setup()` section was run against the real `settings.json` content the same way.
Its `lint_skills()` check (`metadata.file_signals` compiles as a regex and has reasonably
specific alternatives) was exercised on the two seeded skills (`hpc-job-scripts`,
`deeplabcut-hpc`) with no findings. Not tested: firing inside a real conversation turn, the
cost of scanning every skill's frontmatter at scale. See
[references/skill-trigger-hook.md](references/skill-trigger-hook.md) for detail.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were done or not done: why a check was run or skipped, which finding is a real defect and which is a judgement call, why a fix is offered rather than applied, and which assumptions were made. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a package version or API differs from what it states, or it lacks guidance the task needs, record a generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
