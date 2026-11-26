---
name: upstream-bug-report
description: "Checks whether an unexpected error, wrong result or deviation from the documentation in a third-party package or tool is a known or fixed upstream bug, builds a minimal reproduction with version info, and drafts (never files) an issue for the user to review. Use when software misbehaves against its docs, a traceback looks like a regression, the user asks whether something is a bug, where to report it, or to write or check a bug report, GitHub issue or reprex for a package. Not for bugs in the llm-skills skills themselves (use skill-lessons), not for model or statistics questions (use the modelling skills first), not for ordinary user errors fixed by reading the docs. Domain skills such as deeplabcut-hpc and keypoint-moseq add the project-specific repository, template and known pitfalls."
---

# Upstream bug report

Turns "this looks like a bug" into a checked, minimal, redacted issue draft. The assistant never files, comments or votes on an issue; the user decides and posts it. This skill holds the general procedure; a domain skill supplies the repository and its quirks.

## Where this skill runs

Locally on the user's computer, where internet and `gh` are available. It does not run on a cluster. Versions, logs and tracebacks that only a cluster has come from the user running a specific command there and pasting the output; never guess them.

## Workflow (copy and track)

```
- [ ] 1. Confirm it is not a usage error (docs, signature, version)
- [ ] 2. Collect environment facts
- [ ] 3. Search upstream (issues, PRs, commits, releases, forum)
- [ ] 4. Classify: confirmed / similar / not found / fixed-unreleased
- [ ] 5. Reduce to a minimal reproduction
- [ ] 6. Redact, then draft the issue from the repository's template
- [ ] 7. Hand the draft to the user; they file it
```

1. **Usage error first.** Re-read the documented signature and the changelog for the installed version. A deviation from the docs is a bug candidate; a misreading is not. Say which you think it is and why.
2. **Environment facts.** Package version (and whether a release tag or a dev build), Python/R version, OS, hardware and CUDA if relevant, install method, exact first and last lines of the traceback or the wrong output next to the expected output. Ask the user to run the command and paste the result when it lives on another machine.
3. **Search upstream.** Follow [references/search-procedure.md](references/search-procedure.md): issues open and closed, PRs, recent commits for the suspect file, releases, forum. Do not repeat a search that the domain skill's ledger already records.
4. **Classify honestly.** Confirmed (same error, same version range), similar (related, not proven the same), not found, or fixed but unreleased. Link each match. Do not present a workaround from an unresolved or unrelated issue as established.
5. **Minimal reproduction.** Smallest data, fewest steps, runs in a fresh session, built-in or synthetic data where possible. Recipe and checks: [references/issue-draft.md](references/issue-draft.md).
6. **Redact and draft.** Strip tokens, usernames, home paths, hostnames, project names and unpublished data (the llm-skills repo is public too, so nothing personal goes into skills or ledgers). Fill the repository's own issue template if it has one; read it from the repo, do not recall it.
7. **Hand-off.** Show the draft as text, with the target URL and the template to choose. Offer `gh issue create --web` or `--body-file` for the user to run; do not run it yourself unless the user explicitly asks in that turn.

## Bug-candidate signals

A documented argument silently ignored; output that contradicts the docs; a result that changes with an unrelated setting; a crash in a documented default path; a docs example that fails; a silent wrong or degenerate result without a data explanation. Flag these when seen, even if the user did not ask.

## What to say to the user

State the classification, the links, what is still unknown, and which step is theirs (whether to file, which account, whether the data may be shared). If a fix exists only on `main`, list the options (pin an older release, pre-release, install from `main`) and let the user choose; installing from GitHub needs their explicit permission.

## Related skills

- `deeplabcut-hpc`: DeepLabCut repository, bug template fields and known failure modes (its upstream-search reference is the DLC-specific version of the search).
- `keypoint-moseq`: keypoint-MoSeq (`dattalab/keypoint-moseq`) pitfalls; check its tested-and-not-tested list before calling something a bug.
- `skill-lessons`: for a problem with one of this repo's skills, not with upstream software.
- `web-fetching-r`: polite page fetching when `gh` or the REST API is not enough.

Trigger-test queries and results: `assets/trigger-queries.json` (summary in `research/upstream-bug-report-ledger.md`).

## Explain the reasoning (teaching rule)

Teach, don't replace the user's thinking: say briefly (a sentence or two) why a case was or was not treated as a bug, why a search or reduction step was skipped, what was assumed, and which decision (file or not, share data or not) is the user's. Point to a reference for depth.

## Capture lessons (self-improvement rule)

Load the `skill-lessons` skill and append a generic, anonymised entry (no project data, IDs or paths) as soon as something unanticipated happens: an error or warning, advice or code that failed, a user correction, a version or API mismatch, missing guidance, or a recommendation that held up (`worked-well`). Also write one `use-case` entry per session. When unsure, record it with `generality: unsure`. Entries are hypotheses for `skill-feedback-triage`.
