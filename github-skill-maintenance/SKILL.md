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
   judgement. Output columns: skill, level, check, message. The `shadowed-name` check parses each
   `.R` file under `scripts/` and `assets/` and flags top-level functions named like an export of base R's
   default packages (warn) or of a common installed package (info), because sourcing such a script
   silently replaces the original (e.g. a test helper called `pf` masks `stats::pf`). Rename to a
   skill prefix or a more specific verb; `%||%` is exempt, and code blocks in `.md` files and
   non-function objects are not checked.
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
   Run it from the repo root with the skill's own directory name, not `.` — running it from
   inside the skill's directory with `validate .` fails with "Directory name '' must match
   skill name ..." even when the `SKILL.md` is valid (reported 2026-10-27).
3. **Version claims.** When asked for a periodic check, or after a package release:
   ```r
   source("github-skill-maintenance/scripts/check_versions.R")
   check_versions()                  # offline = TRUE skips CRAN/PyPI lookups
   ```
   It lists "name version" claims for packages that are installed or backticked, against
   the installed and current CRAN/PyPI versions. "Claim older than latest" is not an error
   ("tested with X" is a valid statement); it means re-test or reword. Plain-text names of
   packages that are not installed are skipped on purpose, and `deeplabcut` is only found
   when written as `deeplabcut <version>`. Treat it as a candidate list. It returns a data frame
   with a `file` column covering the whole repo (hundreds of rows): assign it and filter to the
   changed skill's files instead of printing it all (reported 2026-10-28).
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

Full list in [references/pitfalls.md](references/pitfalls.md). The ones that bite most:

- **CRLF in the working copy** makes multi-line `edit` calls fail with "string not found" and can come back after any `edit` or `write`. Check `git ls-files --eol <file>` (tracked) or `file <path>` (untracked) before each edit, normalise with `sed -i 's/\r$//' <file>`.
- **Unquoted `#` or an apostrophe in a description** silently truncates or breaks the YAML; quote the value and re-run `lint_skills()` after every description edit.
- **Long Markdown via a bash heredoc can be truncated silently**; use the `write`/`edit` tools.

## What the linter does not judge

Content quality, correctness of the statistics or code in a skill, whether a skill
triggers, and whether claims are true. Those need the testing protocol or the user's
domain judgement. `lint_skills()` also never contacts the network.

## Tested and not tested

Details, including every gap, are in [references/tested-and-not-tested.md](references/tested-and-not-tested.md). Headline: run on Windows with R 4.6.0 only; Linux/macOS, a second machine and the hooks firing inside a real conversation turn are untested.

## Related skills

- `skill-lessons`: records real-world lessons and new-skill-suggestion entries; when this
  skill's own workflow or scripts fail, the fix is logged there, not here.
- `skill-feedback-triage`: the skill that consumes lessons and calls back into this one
  (`lint_skills()`, `check_skill_clashes()`, `check_skill_links()`, `check_versions()`) to
  verify a fix or a newly built skill before calling it ready.
- create-skill (a built-in skill, not part of this repo): where a new skill gets written;
  this skill only lints, tests and verifies it afterwards, never authors the content.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were done or not done: why a check was run or skipped, which finding is a real defect and which is a judgement call, why a fix is offered rather than applied, and which assumptions were made. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a package version or API differs from what it states, or it lacks guidance the task needs, record a generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
