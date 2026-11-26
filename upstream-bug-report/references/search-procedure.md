# Searching upstream before improvising

Generalised from `deeplabcut-hpc/references/upstream-search.md` (DLC-specific details stay there). Replace `OWNER/REPO` with the project's repository; the domain skill names it.

## Contents

- Preconditions
- Search steps
- Classifying the result
- Feature-support checks that return `False`
- Fallback without `gh`

## Preconditions

Have the installed version (release tag or dev build), the exact error text and the install method. Searches run locally, where the internet is available.

## Search steps

1. Issues, open and closed, by error text and by function name:
   ```bash
   gh search issues --repo OWNER/REPO "error text" --sort updated
   gh issue view 123 --repo OWNER/REPO --comments
   ```
   Search the exact message first, then the function or config key, then a looser phrase. Closed does not mean fixed in the user's version: read the closing comment and date.
2. Pull requests, merged and open:
   ```bash
   gh search prs --repo OWNER/REPO "keyword" --sort updated
   gh pr view 123 --repo OWNER/REPO
   ```
   If a code comment or config cites an issue as the source of a feature, also check for superseding PRs; fast-moving repos often ship a different final design than the first proposal.
3. Recent commits and releases, and the history of the suspect file:
   ```bash
   gh api "repos/OWNER/REPO/commits?per_page=30"
   gh api "repos/OWNER/REPO/commits?path=FILE_PATH&per_page=10"
   gh release list --repo OWNER/REPO
   ```
4. The project's forum or discussion board (the domain skill names it). GitHub Discussions, if enabled: `gh api repos/OWNER/REPO --jq .has_discussions`.
5. Compare dates with the installed version. Note which branch a fix merged into (`gh pr view` shows the base branch).

## Classifying the result

| Class | Meaning | Next step |
|---|---|---|
| confirmed | same error or behaviour, version range includes the user's | link it; add a thumbs-up or a short new fact only if the user chooses to |
| similar | related symptom, not proven the same | link it; say what differs; draft a new issue only if the difference is real |
| fixed, unreleased | merged on `main` or a pre-release | offer: pin an older release, pre-release, or `main` (user choice; GitHub installs need explicit permission) |
| not found | nothing matches after the searches above | say so before diagnosing; proceed to a minimal reproduction |

Record the searches done and their outcome in the research ledger so they are not repeated.

## Feature-support checks that return `False`

A snippet that introspects the installed package for a named field can report `False` because the change has not merged anywhere, or because it merged to a non-default branch the install does not track. Check the merge branch, not just that a PR merged. A clean release tag despite a described from-source install can mean the install did not pick up recent commits.

## Fallback without `gh`

The keyless REST API works from R or curl for low volume: `https://api.github.com/repos/OWNER/REPO/issues/123`, `/pulls/123`, `/releases`, `/commits`. It is rate limited (60 requests per hour without a token), so batch and stop early. For HTML pages use the `web-fetching-r` helpers. Never print or store a token.
