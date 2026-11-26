# Research: `upstream-bug-report` (research and draft round 2026-11-26)

Status: skill drafted 2026-11-26, unproven (no live trigger test, no real report filed). Source statuses: read / partial / blocked / search / meta / not researched. Source-quality rules from `AGENTS.md` applied.

## 1. Requirements

| # | Requirement |
|---|---|
| R1 | (2026-11-26, user) `keypoint-moseq` and `deeplabcut-hpc` must tell the assistant to watch for errors, unexpected behaviour or deviation from the docs that should be reported as a bug. Done: inline notes in both SKILL.md files. |
| R2 | (2026-11-26, user) Evaluate a separate bug-reporting skill; run `check_skill_clashes` for it; draft it with `create-skill`, generalising `deeplabcut-hpc/references/upstream-search.md`; record everything as research for reuse. |
| R3 | (2026-11-26, assistant, to confirm) The assistant drafts but never files, comments or votes; the user posts. |
| R4 | (2026-11-26, assistant, to confirm) Inline notes stay in the domain skills as the always-on trigger; the new skill holds the general procedure. |

## 2. Sources

| # | Source | Status | Used for |
|---|---|---|---|
| S1 | https://agentskills.io/specification.md | read | frontmatter limits, body under 500 lines, references one level deep |
| S2 | https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices.md | read | third-person description, TOC in long references, workflow checklists |
| S3 | https://reprex.tidyverse.org/articles/reprex-dos-and-donts.html | read | minimal reproduction rules: built-in or tiny data, only needed commands, no `rm(list = ls())`/`setwd()`, restore options, `tempfile()`, session info, run it yourself |
| S4 | https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/creating-an-issue | read | template chooser, `template` query parameter, duplicate suggestions after title plus 100 characters of body (up to three, non-blocking) |
| S5 | https://cli.github.com/manual/gh_issue_create | read | flags `--title`, `--body-file`, `--template`, `--web`; `--dry-run` not documented |
| S6 | `deeplabcut-hpc/references/upstream-search.md` | read (local) | source of the generalised search procedure |
| S7 | `gh api` on DeepLabCut/DeepLabCut | read (live, 2026-11-26) | has `.github/ISSUE_TEMPLATE/bug_report.yml` (form: duplicate-search checkbox, OS, DLC version, engine, mode, device, description, steps, logs), `config.yml` with blank issues disabled and links to the image.sc forum and gitter, CONTRIBUTING.md; default branch `main`; last push 2026-11-24 |
| S8 | `gh api` on dattalab/keypoint-moseq | read (live, 2026-11-26) | issues enabled, no `ISSUE_TEMPLATE`, Discussions disabled, CONTRIBUTING.md is about pull requests (all changes via PR, test checks, nox sessions, Python 3.10-3.14), default branch `main`, last push 2026-11-09 |
| S9 | Stack Overflow "How to make a great R reproducible example" | skipped: linked from S3, not fetched | candidate for a later round |
| S10 | Python-side minimal-reproducible-example guidance (for example pandas or scikit-learn contributing pages) | not researched | `issue-draft.md` gives only generic Python advice; add if a Python bug is actually reported |
| S11 | GitHub docs on issue forms syntax and `gh search issues` qualifiers | not researched | current text assumes the plain flags above |

## 3. Facts

- Clash check, `check_skill_clashes(new = "upstream-bug-report")` at the default threshold 0.15: no findings among 35 skills. At threshold 0.05 the nearest pairs were `data-repository-readme` (0.108), `github-skill-maintenance` (0.093), `hpc-cluster-docs` (0.068), `skill-feedback-triage` (0.067), all `handoff: none`, mostly generic words (repository, template, documentation, issue, version). Neither `deeplabcut-hpc` nor `keypoint-moseq` appears in the lexical top 8.
- The lexical score misses a semantic overlap: `deeplabcut-hpc`'s description (987 of 1024 characters) says it should "reproduce a DLC bug locally and draft an upstream issue". A request to draft a DLC bug report could load both skills. No room in that description for a hand-off sentence without trimming other text. Decision for the user: trim that phrase from the DLC description and let the new skill own drafting, or accept the overlap (record `accepted` in `clash-decisions.tsv`).
- `check_skill_links()` flagged one-way links from the new skill to `deeplabcut-hpc`, `keypoint-moseq` (backlinks added) and `web-fetching-r` (recorded `no-backlink`). Tooling bug: the suggested row in the one-way message omits the `to` column (the sprintf in `check_skill_links.R` line 73 has a missing argument, giving a format warning); the file needs `from, to, decision, reason, date`. Not fixed.
- `lint_skills()` initially errored on a reference path written in backticks that belongs to another skill (`references/upstream-search.md`); reworded to plain text. Lesson: the link checker resolves any backticked relative path against the current skill.
- `gh` is installed at `C:\Program Files\GitHub CLI\gh` and authenticated on this machine (token not printed). In the earlier DLC ledger it was not on PATH on another machine; check with `which gh` before relying on it.

## 4. Decisions made in this round

| Decision | Why |
|---|---|
| Separate skill plus inline notes | Notes are always on in domain skills; procedure (search, reduction, redaction, template) is shared and would drift if duplicated. |
| Assistant never files | Public, attributable action under the user's account; the user decides whether data may be shared. |
| DLC `upstream-search.md` kept | It holds DLC-specific commands and the feature-check caveat; the generic file avoids repeating project names. |
| Related skill `skill-lessons` | Bugs in this repo's skills are not upstream bugs; the boundary is stated in the description. |

## 5. Open research items

- Live trigger test (should-trigger and near-miss queries, including "draft a DLC bug report" for the clash with `deeplabcut-hpc`).
- Resolve the DLC description overlap (above).
- Python reproduction guidance (S10) and Stack Overflow MRE page (S9).
- Whether `gh issue create` should be run by the assistant when the user asks explicitly (currently allowed only on explicit request in that turn).
- Other candidate domain skills for inline notes: `gam-mgcv`, `mixed-models-glmm`, `r-reproducible-pipeline`, `python-reproducible-pipeline`, `openalex`. Not added; the user asked for kpms and DLC only.
- `skills-ref` validate not run (user shell or `uvx --from skills-ref agentskills validate upstream-bug-report`).

## 6. Log

- 2026-11-26: inline "watch for bug candidates" notes added to `keypoint-moseq` and `deeplabcut-hpc`. Skill `upstream-bug-report` drafted (SKILL.md, `references/search-procedure.md`, `references/issue-draft.md`). Clash, lint and link checks run; backlinks added; ownership row added to `skill-boundaries.md`; one `no-backlink` row recorded.

## 7. Round 2 (2026-11-26): overlap fix, sprintf fix, proxy trigger test

| Item | Result |
|---|---|
| DLC description overlap | Removed "or reproduce a DLC bug locally and draft an upstream issue" from `deeplabcut-hpc`'s description and added "To check a suspected bug upstream and draft an issue use upstream-bug-report." The new skill's description already names `deeplabcut-hpc`, so the hand-off is in both. The DLC body still keeps the inline note and `references/upstream-search.md`. |
| `check_skill_links.R` line 73 | Bug: the suggested-row format string had six placeholders for seven arguments and omitted the `to` column. Fixed by adding `\t%s` so the row reads `from, to, decision, reason, date`. Verified: no format warning when `check_skill_links()` runs on the repo (see below). |
| Proxy trigger test | 14 queries in `upstream-bug-report/assets/trigger-queries.json` (7 should-trigger incl. DLC, kpms, mgcv, ggplot2, dplyr, snakemake; 7 near misses incl. DLC OOM sizing, skill lesson, glmmTMB singular fit, PR workflow, README, pivot_longer user error, gitignore/token). Two general subagents saw only names and descriptions of 38 skills (35 repo skills plus 3 built-ins), shuffled order, no SKILL.md access. |
| Result | Should-trigger: `upstream-bug-report` chosen 14 of 14 selections. Near misses: 0 of 14 false loads; the pivot_longer user error went to `tidy-data-wrangling` and the run-2 subagent cited the description's "not for ordinary user errors". Co-loads: domain skill alongside on DLC, kpms, mgcv queries (intended); `python-reproducible-pipeline` once on the snakemake query; `deeplabcut-hpc` on the DLC OOM query together with `hpc-resource-allocation` (correct, not a bug-report miss). Query 11 (open a pull request) loaded no skill. |
| Limits | Subagents are not the real loader; queries were written by the skill author; the split fields were not used for tuning because nothing failed; one round of two runs; no real-conversation test. |
| Cleanup | The description dump had to go to git-ignored `tmp-examples/` (R cannot write the scratch dir); deleted afterwards. |

Open items now: real-conversation trigger test, `skills-ref validate` in the user's shell, Python reproduction guidance (S10).

## 8. Round 3 (2026-11-26): validation and more inline pointers

- `uvx --from skills-ref agentskills validate upstream-bug-report` (run from repo root, assistant shell): "Valid skill: upstream-bug-report", exit 0.
- Inline "Watch for bug candidates" sections added to `gam-mgcv` and `mixed-models-glmm` (both rule out misspecification and version differences first, then point to `upstream-bug-report`; backlinks added to their Related skills). Recorded as `no-backlink` rows. Lint: only info findings after normalising CRLF; clash check none; the live one-way message now prints a correct five-field row (confirms the sprintf fix). Trigger test not run for the two edited skills.
