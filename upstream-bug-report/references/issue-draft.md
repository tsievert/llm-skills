# Minimal reproduction and issue draft

## Contents

- Minimal reproduction
- Redaction checklist
- Draft structure
- Repository-specific templates
- Filing (the user's step)

## Minimal reproduction

Follow the reprex principles (tidyverse reprex "do's and don'ts"): the smallest, simplest, built-in data possible; only the commands that need to run; no `rm(list = ls())`, no `setwd()` to a path only the author has, no masking of built-in functions, restore options and delete files you create, use `tempfile()`; include session info when versions might matter; run the code yourself so the output is real.

1. Start from the failing script and delete lines until removing anything more makes the problem vanish.
2. Replace real data with synthetic or tutorial data. Keep only the properties that matter (shape, dtype, missing values). Set a seed.
3. Run it in a fresh session or a fresh environment. R: `reprex::reprex(session_info = TRUE)` produces copy-ready output. Python: a single script run with an environment created from the pinned versions.
4. Confirm the failure reproduces and note the versions on which it does and does not (an older release that works is a strong, cheap clue; `git bisect` only if the user wants it).
5. If it cannot be reduced, say so; a failing run on the user's data with a precise description is still useful, but the user decides whether the data may be shared.

## Redaction checklist

Remove or replace: tokens, passwords, API keys; user names; home and project paths; host and node names; email addresses; unpublished data and animal or subject identifiers; cluster account names. Check traceback lines and log headers, which often carry paths and hostnames. Environment variable dumps are never pasted whole.

## Draft structure

Use the repository's template if it has one (see below). Otherwise:

```
Title: <function or area>: <observed behaviour> (version X)

What happened and what was expected (two or three sentences).

Steps to reproduce: <minimal script, numbered steps>

Environment: OS, language and package versions, install method, hardware if relevant.

Logs: first and last lines of the traceback in a code block.

Searched: links to the nearest existing issues and why they do not match.

Workaround, if any, and whether it was tested.
```

One bug per issue. State facts and uncertainty separately ("I did not test on version Y"). No speculation about the cause unless labelled as such.

## Repository-specific templates

Read the live template from the repository, not from memory:

```bash
gh api repos/OWNER/REPO/contents/.github/ISSUE_TEMPLATE --jq '.[].name'
gh api repos/OWNER/REPO/contents/.github/ISSUE_TEMPLATE/bug_report.yml --jq .content | base64 -d
gh api repos/OWNER/REPO/contents/CONTRIBUTING.md --jq .content | base64 -d
```

Checked 2026-11-26 (see `research/upstream-bug-report-ledger.md`): DeepLabCut has a form template (OS, version, engine, mode, device, description, steps, logs) with blank issues disabled and general questions routed to the image.sc forum; keypoint-MoSeq has no issue template, a CONTRIBUTING.md about pull requests and tests, and Discussions disabled.

## Filing (the user's step)

Give the user the draft as text and the target repository URL. Options they can run themselves: the web form (`https://github.com/OWNER/REPO/issues/new/choose`), or
```bash
gh issue create --repo OWNER/REPO --title "TITLE" --body-file issue.md
```
(`--template NAME` and `--web` also exist). GitHub suggests up to three possible duplicates while the title is typed; the user should look at them. Save the draft with the `write` tool in the project or scratch folder, never in the public skills repo if it holds anything unredacted.
