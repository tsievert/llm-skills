---
name: agents-md-maintenance
description: 'Audits, prunes, and restructures AGENTS.md, CLAUDE.md, and DATABOT.md project-memory files for token economy: flags bloat, stale or contradictory rules, narrative creep, and duplicated content, and moves detail into dated history logs, research ledgers, or on-demand reference docs following progressive disclosure. Checks that the file carries a standing rule to delegate narrowly-scoped, low-judgment tasks to a lower-effort subagent rather than doing everything inline, worded as a conditional win, not a default. Use when the user asks to audit, clean up, trim, restructure, or split an AGENTS.md/CLAUDE.md/DATABOT.md file, says project memory has gotten too long or bloated, or asks what belongs in project memory versus a skill or reference doc. Does not create Agent Skills itself (routes new-skill ideas through skill-lessons for later triage, not create-skill) and does not own the `.codemap/` pointer section that codebase-map inserts.'
---

# AGENTS.md maintenance

Keeps a project's always-loaded memory file (`AGENTS.md`, `CLAUDE.md`, or `DATABOT.md`) lean,
current, and well-formatted. The file is read into context on every session, so every line in
it is a recurring token cost, not a one-time one — see
[references/best-practices-sources.md](references/best-practices-sources.md) for the research
this skill is built from.

## The core test

For every block of text in the file, ask: **does nearly every session in this project need
this?** If the honest answer is "probably not," it's a candidate for extraction — to a dated
log, a reference file, a skill, or deletion. This one question does most of the work; the
sections below are ways of applying it systematically.

## Audit workflow

1. **Read the whole file first.** Don't skim; contradictions and duplication are only visible
   end to end.
2. **Classify every block** as one of: a standing rule or convention (keep), a fact the agent
   cannot infer from the code or environment (keep, if still true), a resolved decision or
   narrative entry (move to a dated history/changelog file), a todo/status table (keep if short
   and current; prune finished rows), or something the agent already knows or can read from the
   code/README/`.gitignore` itself (delete).
3. **Check for staleness.** Flag "open decisions" that read as already resolved, todo rows with
   no recent activity, and facts that may have drifted (versions, paths, usernames). Don't assume
   — ask the user to confirm anything you can't verify from the repo itself.
4. **Check for contradictions.** Two rules that conflict are worse than one missing rule, because
   the agent picks one unpredictably — usually whichever it read most recently. Resolve in place
   and remove the other; don't leave a "deprecated" copy anywhere the agent can still read it.
5. **Check formatting for scannability.** Tables over long prose for structured facts (todo
   lists, ownership maps, source tables). Bullet lists only for genuinely parallel items.
   Rules phrased as positive actions ("use X") read more reliably than bare "don't"s; pair a
   "don't" with a "do" where there's a clear alternative.
6. **Check position.** Earlier lines in the file carry more weight in practice. The rules that
   must never be missed (secrets, destructive-action limits, hard constraints) should sit near
   the top, not buried after routine narrative.
7. **Check for the subagent-delegation rule** (see below) and add or correct it if missing or
   mis-stated.
8. **Propose, don't silently rewrite.** Summarize findings (what's stale, what's duplicated,
   what's miscategorized) and propose the restructuring; let the user confirm before editing,
   the same way other skills in this repo surface findings before changing files.
9. **Re-read right before a full-file overwrite.** Once the user approves, re-read the file
   immediately before a full-file `write(overwrite=TRUE)`, not just at the start of the audit —
   another skill with its own self-triggering hook (e.g. a codebase-map-style pointer section)
   can append to the same always-loaded file mid-session. Preserve any section owned by another
   skill verbatim in the rewrite.

## Restructuring patterns

- **Split live state from history.** Keep current rules, conventions, and an open-items list in
  the main file; move dated narrative (what was tried, what was found, what was decided and why)
  to a separate `HISTORY.md` or changelog, read on demand rather than every session. This repo's
  own `AGENTS.md`/`HISTORY.md` split is a working example.
- **Split research from decisions.** If a project does enough investigation to need citations or
  source tables (as this repo's `research/` ledgers do), keep that in topic-specific files, not
  inline in the memory file — reference them by path instead of duplicating their content.
- **Promote a procedure to a skill — but not in this session.** If a block has grown into a
  multi-step workflow with its own edge cases, it has outgrown the always-loaded file. Don't hand
  off to create-skill directly: that builds a skill on the spot, in whatever session happened to
  notice the need, with no review and no check for overlap with an existing skill. Instead,
  record a new-skill-suggestion entry via the `skill-lessons` skill (proposed name, the trigger,
  and the scope in a sentence or two) and tell the user it's logged for the next
  `skill-feedback-triage` run rather than built now. Still flag it to the user in this session —
  logging it is not silent.
- **Reference doc vs. full skill.** When extracting a grown procedural block, prefer a plain
  reference doc (read on demand from inside the memory file, or kept in the project) when the
  procedure is project-specific and not reused across projects or conversations. Prefer
  recording a new-skill-suggestion entry (above) when it would be reused across projects or
  benefits from independent discovery/triggering rather than being tied to one project's
  always-loaded file.
- **Reference instead of duplicating.** Point at `README.md`, `.gitignore`, or existing docs
  rather than restating their content; duplicated facts drift apart over time.
- **A hand-off note for a long work stream that outgrows one conversation.** When a multi-step
  refactor or build spans more than the memory file and history log can usefully hold (a
  17 KB `AGENTS.md` and a 105 KB `HISTORY.md` are both too large to re-derive one work stream's
  state from), write a dedicated hand-off file instead of growing either: goal and decisions,
  what exists and where, what's verified vs. not, a numbered "next actions" list, and "how to
  resume" (the exact instruction to restart the work). Link it from the memory file with one
  line, and archive or delete the hand-off file once the work stream closes — it's scratch
  state for one thread of work, not a permanent record (that's what `HISTORY.md` is for).
- **No single correct length.** Cited rules of thumb for always-loaded files range roughly from
  ~50 to ~200 lines depending on the file's role (global vs. project) and the source; treat these
  as a prompt to look harder when well exceeded, not a hard limit to enforce mechanically.

## The subagent-delegation rule

Every `AGENTS.md` this skill writes or reviews should carry some form of this standing rule, but
worded as a *conditional* recommendation, not a blanket default:

> Delegate narrowly-scoped, low-judgment tasks (e.g. a mechanical search across many files, a
> repetitive edit pattern, summarizing a large log or output) to a subagent — especially one
> that can run with lower effort or a cheaper/smaller model — when doing it inline would mean
> loading a lot of noisy context (many files, logs, search results) into the main conversation
> that won't be needed again. Don't delegate by default: single-file edits, ambiguous-scope
> work, or tasks needing the main conversation's accumulated context are usually cheaper and more
> reliable done directly, and fanning out many subagents on one task can burn more tokens than it
> saves if they aren't genuinely lower-cost.

This wording is deliberately conditional: the evidence for subagent delegation saving tokens is
real but not universal — it depends on actually routing to a lower-cost agent or isolating noisy
context, and reports exist of subagent fan-out burning *more* tokens than sequential single-agent
work. See the ledger cited above for the specific sources. If a project's own memory file already
has an equivalent rule (this repo's own working rules touch on `explore` subagents for broad
investigation), check it matches this framing rather than adding a duplicate.

## What never belongs in the always-loaded file

Secrets or credentials of any kind; generic software-engineering advice the agent already knows
("write clean code," "follow best practices"); directory trees or dependency lists the agent can
get by reading the project; content duplicated from `README.md`; long architecture prose without
concrete file pointers; anything resolved or no longer true.

## Related skills

- `skill-lessons`: the hand-off for "this belongs in a skill, not here." Record a
  new-skill-suggestion entry there (a `type` value, not a skill name) rather than calling
  create-skill directly, so the new skill is only built after a `skill-feedback-triage` review.
- create-skill (a built-in skill, not part of this repo): the eventual destination once a
  new-skill suggestion is reviewed and approved — not something this skill calls directly.
- `staged-assistant-workflow`: when a work stream is recurring (not just long), with named
  stages, gates, and a status function, rather than a single hand-off note.
- `codebase-map`: owns inserting and maintaining the one specific pointer section it adds to a
  project's `AGENTS.md`/`DATABOT.md` (pointing at `.codemap/`). Leave that section alone; this
  skill covers everything else in the file.
- `github-skill-maintenance`: maintains this repo's own skill-authoring conventions and lints
  skill files; not a general AGENTS.md-hygiene tool for other projects, but the two repos'
  conventions (dated log entries, todo tables, "explain the reasoning" sections) are consistent
  with the patterns recommended here.
- import-instructions (a built-in skill, not part of this repo): converts other tools'
  instruction files (Copilot, Claude Code, VS Code/Positron) *into* Posit Assistant skills — a
  different direction from pruning an existing memory file.

## Explain the reasoning (teaching rule)

The aim is to teach the user long-term, not to replace their own thinking. When using this
skill, say briefly why things were or were not done: why a block was flagged as stale versus
kept, why something was proposed for extraction into a skill rather than a reference file, why a
finding was surfaced rather than auto-fixed, and which length or structure decisions are
judgment calls rather than hard rules. Keep each explanation to a sentence or two, name the
trade-off, and point to the research ledger for depth rather than lecturing.

## Capture lessons (self-improvement rule)

If while using this skill an error it did not anticipate occurs, its advice fails, the user
corrects it, or it lacks guidance the task needs, record a generic, anonymised entry by
following the `skill-lessons` skill: no project data, IDs, or paths; write it when the issue is
resolved and mention it in one sentence. Skip one-off user preferences. Entries are hypotheses
for later triage in the llm-skills repo (`skill-feedback-triage`), not facts.
