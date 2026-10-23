---
name: github-skill-maintenance
description: Maintains the llm-skills GitHub repo of custom skills. Lints skills against the Agent Skills spec and the repo's standing rules (teaching section, HPC "Where this skill runs", links, CRLF, truncated descriptions), finds stale package-version claims, audits the auto-sync hook and skills.paths config, and guides testing, commit and push of skill changes. Use when the user asks to check, lint, validate, review, test, update, release or sync skills, asks why a skill is not loading or not triggering, or wants a periodic skill health check.
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
   (PostToolUse `skill` and Stop), the lessons data folder, stamp and git state:
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
   the change, push to `origin/main`. Update `AGENTS.md` (todo list and Log: what changed,
   what was tested, what was not). A pulled skill is used from the next conversation, and
   the sync hook picks changes up within 24 h per machine.

## Pitfalls this repo has hit

- **Unquoted `#` in a description.** YAML ends a plain scalar at ` #`, so "Covers #SBATCH
  directives" silently cuts the description there (verified with two parsers). Quote the
  whole value, or write "SBATCH". Linter check: `description`.
- **CRLF in scripts.** Tools on Windows can leave CRLF in the working copy even though
  `.gitattributes` forces LF in the index (`git ls-files --eol` shows `i/lf w/crlf`). A
  script copied to the cluster from the working copy then fails. Fix with
  `sed -i 's/\r$//' <file>` in Git Bash before copying.
- **Dead links** between skills after a file is moved or was never created. Linter
  check: `links`.
- **`~` in R on Windows** is `Documents`, not the profile directory. The scripts use
  `USERPROFILE`.
- **Name clash with a built-in** (e.g. `report`, `create-skill`): the user copy silently
  wins. Check the built-in list before choosing a name.
- **Description drift.** Descriptions that grow past about 950 characters or lose the
  "Use when" wording trigger less reliably; the linter warns on both.

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

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this skill, say briefly why things were done or not done: why a check was run or skipped, which finding is a real defect and which is a judgement call, why a fix is offered rather than applied, and which assumptions were made. Keep each explanation to a sentence or two, name the trade-off or the decision that belongs to the user, and point to a reference for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice or code fails, the user corrects it, a package version or API differs from what it states, or it lacks guidance the task needs, record a generic, anonymised entry by following the `skill-lessons` skill: no project data, IDs or paths; write it when the issue is resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
