# Skill-trigger enforcement: research ledger

For the question "what can we do about skill undertriggering (explicit instructions dropped,
context clues ignored)?", raised 2026-10-24 after analysing `tmp-examples/conversation-export.json`
(see the `github-skill-maintenance` lesson logged the same day,
`~/.posit/lessons/inbox/anon_20261024-162307_manual.md`).

## 1. Two distinct failure modes (requirements)

| # | Mode | Example | Fix category |
|---|---|---|---|
| R1 | An explicit, unambiguous user instruction to load a skill is present, but is never acted on, including after a Plan-mode switch and/or subagent delegation | `conversation-export.json`: "Make sure to trigger the appropriate skills..." never followed up, 4 turns, 0 `skill()` calls | deterministic enforcement is possible (the condition is checkable) |
| R2 | No explicit instruction; the signal is only in file content read mid-task (`#SBATCH`, `import deeplabcut`) | `conversation-export-2/3/4.json`: heavy sbatch/DLC content, 0 skill calls, no explicit ask either | only a best-effort nudge is possible; the "should a skill have fired" judgment is not fully decidable from content alone |

## 2. Why this happens (sources read)

- Prompt-level instructions are soft constraints that degrade with context length and
  competing content, while hooks run outside the model's reasoning chain. One source claims
  prompt-based instructions achieve roughly 70-90% compliance and can be skipped "under
  context pressure, long sessions, or competing priorities" (dotzlaw.com/insights/claude-hooks,
  2026; marketing-flavoured, treat the exact percentages as unverified, but the architectural
  claim — hooks run outside the model's reasoning chain — matches the Posit Assistant docs
  read in section 3).
- The general "lost in the middle" / instruction-following-degrades-with-length literature
  (Liu et al. 2023 lineage) is the underlying reason prompt instructions like "trigger the
  appropriate skill" can be present in a transcript yet not acted on dozens of tool calls
  later: one paper names "failures to follow instructions" as one of three primary failure
  modes at longer context lengths (arxiv 2601.03269, "The Instruction Gap", citing
  Databricks 2024). A different paper found no clean positional effect for *instruction*
  position specifically (arxiv 2510.14842, section 4.2) — so treat "it was early in the
  context" as a plausible contributor, not a proven cause; the Plan-mode/subagent-delegation
  note already in `testing-skills.md` (one trial, no suppression found) is consistent with
  this: it's likely competing-context volume, not a Plan-mode-specific effect.
- Context isolation via subagents is a known, deliberate design trade-off in the broader
  agent literature, not unique to this assistant: launching a sub-agent with its own system
  prompt and tool set is described as reducing interference from irrelevant history and
  improving modularity (arxiv 2607.00151, SmoothAgent, section 3.5). A separate source
  states the corollary plainly: subagent delegation in coding agents means "every invocation
  of a subagent creates a brand new session" with no shared history (dev.to/saez520). This
  explains why a subagent used for investigation cannot itself be relied on to carry the
  parent's pending instruction forward — the parent conversation must track it itself.

## 3. Posit Assistant hook capabilities actually confirmed (not Claude Code's; read live, 2026-10-24)

Read in full: https://assistant.posit.co/docs/features/hooks/ (fetched directly, not from
cache/memory, since this governs what we can build).

Facts not previously recorded in this repo's memory/skill files:

- **`UserPromptSubmit`** fires when a prompt is accepted for a turn and can inject
  `additionalContext` or `decision:"block"` + `reason` (rejects the prompt). This is new
  leverage for R1: a hook can inspect the *exact* incoming instruction text before the
  model ever reasons about it, independent of how deep the conversation later gets.
- **`SubagentStart`** / **`SubagentStop`** are real, separate events (`launchSubagent` or a
  delegated `webSearch`). `SubagentStart` cannot block; `SubagentStop` can (forces the
  subagent to keep going). Matcher for both is `agent_type`, not tool name. Not used by any
  skill in this repo yet (only `PostToolUse`/`Stop` are used, by `lessons-hook.sh`).
- **`PostToolUse` can inject `additionalContext`**, not just `decision:"block"` — i.e. a
  *non-blocking* nudge is a first-class, documented capability, not a workaround. This
  directly enables a content-keyword nudge for R2 without the false-positive risk of a hard
  block.
- `Stop`/`SubagentStop` JSON output is `top-level decision:"block"` + `reason` (matches what
  `lessons-hook.sh` already does for `Stop`; the same shape extends to `SubagentStop`).
- `PostToolUse` payload includes `tool_response` (capped 50,000 characters) — enough to scan
  `read`/`grep`/`bash` output for keyword hits without separately re-reading the file.
- Hooks are **additive** (global + project both run) and **fail-open** (a crash or timeout
  is treated as if the hook allowed the action) — consistent with the existing
  `lessons-hook.sh` design philosophy ("fails open").
- `stop_hook_active: true` on `Stop`/`SubagentStop` payloads lets a hook guarantee it blocks
  **at most once** per completion attempt, exactly the mechanism `lessons-hook.sh` already
  relies on to avoid infinite loops.
- Confirmed absent: `PreCompact` is not fired in this release (Claude Code has it; not
  relevant here since compaction isn't the mechanism we're compensating for anyway).

## 4. Refined design, not yet built

**R1 (explicit instruction dropped) — deterministic, three-hook pipeline, all reusing the
`lessons-hook.sh`-style fail-open/once-only pattern:**

1. `UserPromptSubmit`: regex the incoming `prompt` for trigger phrasing ("trigger the
   appropriate skill(s)", "make sure to (use|trigger|load) ... skill", "use the right
   skill"). On a match, write a per-session marker (`~/.posit/state/<session>.pending_skill_instruction`)
   with a scrubbed snippet and timestamp. Non-blocking (`additionalContext` only, or silent).
2. `PostToolUse` matcher `skill`: if a marker exists for this session, delete it (the
   instruction is considered addressed — *some* skill was loaded, which is as much as a
   hook can check; it cannot judge whether it was the *right* skill).
3. `Stop` (extend `lessons-hook.sh` or add a sibling script): if a marker still exists and
   `stop_hook_active` is not set, return `decision:"block"` quoting the original instruction
   back and asking the assistant to either load the relevant skill or explain briefly why
   none applies, then exit; the second `Stop` (now `stop_hook_active:true`) passes silently
   either way, bounding this to one forced extra turn, same as the lessons reminder.

**R2 (context-clue undertrigger) — best-effort, single hook, no blocking:**

4. `PostToolUse` matcher `read|grep|bash` (same matcher family as `lessons-hook.sh`'s
   optional error counter): scan `tool_response` against a small, explicit keyword→skill
   table (seeded from the signals already named in `hpc-job-scripts`/`deeplabcut-hpc`
   descriptions: `#SBATCH`/`sbatch`/`srun`, `import deeplabcut`/`pytorch_config.yaml`;
   extensible per skill). On a hit for a skill not yet loaded this session (cross-check
   `usage.tsv`), return `additionalContext` once per (session, skill) — never block, since
   "should this skill have fired" is a judgment call a keyword match cannot make reliably
   (an already-correct, already-reviewed sbatch script doesn't need the skill reloaded).

Both pipelines can live in one script (new matchers added to `lessons-hook.sh`, or a
sibling `skill-trigger-hook.sh` sharing its conventions) to keep the hook surface small, per
the existing "one script per repeated-event family" pattern in this repo.

## 5. Open items / not yet done

- Script not written yet; no local tests run.
- Keyword table for R2 is a maintenance burden (same risk class as any hardcoded keyword
  list) — scope it to the 2-3 skills with the clearest file-signature (HPC, DeepLabCut) and
  extend only on evidence, not speculatively for every skill.
- The phrase regex for R1 (step 1) needs real negative/positive examples before shipping,
  same discipline as `references/testing-skills.md`'s trigger-query protocol, to avoid
  matching "skill" in unrelated sentences (e.g. "that doesn't take much skill").
- Not checked: whether `additionalContext` from `PostToolUse` is visible to the *user* or
  only fed back into the model's context (the docs describe it as context, not UI); treat as
  invisible-to-user by default and don't rely on it for communicating anything the user must
  see.
- No test of `SubagentStop`/`SubagentStart` payload shape against a real `launchSubagent`
  call in this project; the docs text above is the only source so far.

## 6. Round 2 (2026-10-24): is R2 common elsewhere, and is a non-blocking nudge viable?

Triggered by a second, independent real-session recurrence of R2 (turn 3 of the
`dlc-pig-method-paper` series: "update paths... references are broken" across `#SBATCH`/DLC
scripts, logged as a `github-skill-maintenance` lesson,
`anon_20261024-audit_manual.md`). Five `web_search` calls plus reading of search snippets
only (no full-page fetches this round; all citations below are to search-result text).

### 7.1 Yes, this is common — not a quirk of this repo

- Multiple open/closed Claude Code GitHub issues describe the same shape: skills or
  `CLAUDE.md` rules present and loaded, but not acted on mid-task. Issue #18454 ("ignores
  CLAUDE.md and Skills files during multi-step tasks") has a maintainer-adjacent comment
  dated Jan 25, 2026 and a user comment: "This happens all the time... Claude will NOT check
  for available skills but jump straight to the standard tools" (github.com/anthropics/claude-code/issues/18454).
  A separate commenter on the same issue: "unless a skill is manually invoked... Claude will
  deny its existence when prompted to use it... it will routinely ignore skill instructions."
- A troubleshooting guide lists "too many skills" as a cause: "GitHub issue reports describe
  installs of 137 skills where only 116 load, with the rest silently absent" (lazyskills.sh) —
  a different mechanism (context-budget truncation) than R1/R2, but confirms skills silently
  failing to participate is a known community-wide complaint class, not specific to this setup.
- This is consistent with, not contradicted by, the official guidance: Anthropic's own
  best-practices page and a third-party summary both say Anthropic monitors this with
  instrumentation rather than claiming the model reliably self-checks: "Anthropic logs skill
  usage with a PreToolUse hook... If a skill is not being used, either no one needs it or the
  description is not triggering correctly" (medium.com/@tahirbalarabe2, "9 Tips for Building
  Claude Agent Skills"). Official guidance also names description quality as the main lever,
  and does not claim a model-side automatic re-check of relevance exists.

### 7.2 Mechanistic explanation (academic, not just anecdote)

- PlanBench-XL (arxiv 2606.22388, "Takeaway 9") studied drift in long-horizon tool-use agents
  and found the bottleneck is reselection, not discovery: <cite index="1-4,1-5,1-6">Before failed-run non-progress calls, the model had already retrieved at least one valid tool that could support progress toward the solution in 78.0% of default cases and 71.1% of block cases... many wrong calls occur even though the model has already seen a solution-relevant alternative. The bottleneck is therefore not only tool discovery, but also deciding which discovered tool should be used next.</cite>
  It also finds a recency bias: <cite index="1-8,1-9">The failed non-progress calls also show a strong recency pattern in tool selection. In both settings, most non-progress calls use tools from recent retrieval windows</cite>.
  Applied to R2: the skill list was "seen" once, at session start; by the time file content
  makes the match obvious, it is no longer in the recent window, and nothing re-surfaces it.
  This gives a concrete, falsifiable reason a content-triggered nudge should help: it puts the
  skill name back in the *recent* window right when the signal appears, rather than relying on
  the model recalling a session-start listing.
- A software-engineering treatment of Claude Code skills and hooks states the general
  principle directly: <cite index="44-14,44-15,44-16">If a step must happen every time the triggering event occurs, put it in a hook. A standing instruction in a skill body, however firmly worded, is something the model may read, defer, or skip. The same instruction expressed as a hook runs unconditionally.</cite>
  (arxiv 2607.25032, "Authoring Agent Skills: A Software-Engineering Approach"). This is the
  same reasoning that justified R1's `UserPromptSubmit`/`Stop` pipeline, extended here to R2.

### 7.3 Prior art: the exact R2 mechanism already exists in the wild, as a non-blocking nudge

Two independent, currently-open community implementations do essentially the design sketched
in section 4, item 4 of this ledger:

- `msobroza/coding-agent-playbook` issue #58, "feat(hooks): add the skill-nudge hook": <cite index="40-1,40-3,40-4,40-5,40-6">A new default-tier feedback hook, skill-nudge (post_tool_use on edit and write, priority 30, Claude Code and OpenCode, no body). The first time a session edits a file a skill covers, it names that skill: 'Conventions for this file: skill .', one line per matching skill, at most 200 characters. Each line shows once per skill per session, through the existing dedupe_key and combine machinery.</cite>
  This is a `PostToolUse` nudge, deduped per (session, skill), non-blocking, file-content keyed
  — the same shape as the ledger's R2 sketch, already built and apparently in active use.
- `theitush/giverny` issue #358 describes a related pattern (nudging toward a different skill,
  not file-content keyed, but the same mechanics): <cite index="39-4,39-5,39-6">The plugin's hook on the Agent tool adds non-blocking additionalContext in a session that is not a manager. Prefer PreToolUse if Claude Code takes context there, so the agent can switch before spawning; otherwise PostToolUse... It fires only on signs of task work</cite>,
  and reports a successful test: <cite index="39-9,39-10">Verified by the worker: 7 unit tests, plus a real headless claude -p --model haiku run against the branch binary in a scratch env. The Explore call got no context; the general-purpose "Edit hello.txt" call got the nudge, and the model quoted it back.</cite>
  — i.e. a live confirmation that a `PostToolUse` `additionalContext` nudge is actually read and
  acted on by the model in a fresh run, not just theoretically delivered.
- Separately, `dotzlaw.com` frames the general PostToolUse-nudge pattern (for a linter, not
  skills, but the same mechanism) as the reliability fix for exactly this prompt/hook gap:
  <cite index="43-7,43-8,43-9,43-10,43-11">With hooks, the setup works differently. A PostToolUse hook fires after every file write. It runs the linter. If there are errors, it injects the error descriptions back into the agent's context as additionalContext. The agent fixes the issues in its next action.</cite>

### 7.4 Re-assessment of the false-positive objection that shelved R2

The original decision (section 4/5 above, 2026-10-24) treated R2 as too risky to build because
a keyword hit cannot judge "should this skill have fired." Round 2 narrows that objection:

- The objection applies to a **blocking** R2 (forcing the assistant to load a skill it may not
  need). Nobody in the prior art blocks on this signal; every example found is
  `additionalContext` only. The cost of a false positive drops from "forced wrong action" to
  "one ignorable extra line of context, at most once per (session, skill)" — closer in risk
  profile to the linter-nudge pattern above (well-established, not seen as a false-positive
  hazard in any source read) than to a hard gate.
- The **decidability** problem is real but narrower than feared: it is not "should a skill have
  fired" in general, it is "does this specific text pattern (`#SBATCH`, `import deeplabcut`)
  appear in a tool result for a skill not yet loaded this session" — a much easier predicate
  than relevance judgement, and the same one the HPC/DeepLabCut descriptions already assert in
  words ("even if the request doesn't name Slurm/HPC... check whether the scripts... import
  deeplabcut"). The hook would mechanise a check the description text already claims the
  assistant should be making.
- The **maintenance-burden** objection (section 5) is addressed by moving the keyword table out
  of the shared hook script and into each opted-in skill's own frontmatter (a `metadata` map,
  which the spec already reserves for extra fields; see `sync-and-config-facts.md`), so the
  signal lives and is reviewed next to the skill it serves, not centrally. This mirrors the
  Claude-Code-specific "skill-scoped hooks" idea named in passing by stephanmiller.com:
  <cite index="45-1,45-2,45-3">You can define hooks in a skill's frontmatter, and they're only active while that skill is active... The rule lives and dies with the skill instead of polluting every session.</cite>
  (Posit Assistant hooks are declared centrally in `settings.json`, not in skill frontmatter —
  confirmed absent from `sync-and-config-facts.md` — so this repo cannot literally do
  skill-scoped hook registration; the adaptation is a shared hook that *reads* a per-skill
  declared field, which gets the same locality-of-ownership benefit without needing the
  platform feature.)

### 7.5 Design, revised from section 4 item 4, not yet built or approved

1. Opt-in per skill: an optional `metadata.file_signals` list in `SKILL.md` frontmatter, each
   entry a short literal or simple regex string plus nothing else (no free text, to keep this
   lintable and non-executable). Only added to skills with a strong, low-ambiguity signature —
   start with `hpc-job-scripts` (`#SBATCH`, `\bsbatch\b`, `\bsrun\b`) and `deeplabcut-hpc`
   (`import deeplabcut`, `pytorch_config\.yaml`, `pose_cfg\.yaml`) per the existing description
   clauses; do not add it speculatively to the other 22 skills.
2. One shared hook, `PostToolUse` matcher `read|grep|bash` (reuses the matcher family already
   used by `lessons-hook.sh`'s dormant error counter): on each call, read every skill's
   `file_signals` from the local clone (cheap: 24 small YAML frontmatter reads, or cache them
   at `SessionStart` into one file next to the throttle stamp), test the tool's `tool_response`
   against each pattern, and for the first hit on a skill not yet loaded this session (checked
   the same way the existing hooks check `PostToolUse` `skill` calls), emit `additionalContext`
   naming the skill — never `decision:"block"`. Dedupe per (session, skill) with a marker file,
   same convention as the R1 pipeline and the `skill-nudge` prior art in 7.3.
3. Extend `check_sync_setup()`/`lint_skills()` to validate `file_signals` entries compile as
   valid regex and are reasonably specific (e.g. warn on a bare word under ~6 characters, which
   risks matching incidental text) — mirrors the existing description/CRLF checks rather than
   adding a new, separate tool.
4. Explicitly out of scope for a first version: no central, assistant-wide "does this file
   match some skill" classifier; no LLM-based matching (keeps it deterministic, auditable, and
   fast, consistent with "put deterministic checks in a hook, not a model call"); no automatic
   mid-task `skill()` invocation (nudging only, per 7.4).

### 7.6 Open items

- Not yet discussed with the user: whether to build this now, given it touches the frontmatter
  of at least two existing skills and adds a new shared hook. Section 7.5 is a proposal, not an
  approved design.
- Unverified: whether Posit Assistant's `PostToolUse` `additionalContext` is actually surfaced
  back into the *same* turn's reasoning the way the `giverny` test showed for Claude Code (item
  5 of section 5, "not checked" line) — this round found a live confirmation for Claude Code,
  not for Posit Assistant specifically.
- Not sized: cost of reading/caching 24 frontmatter files per matching tool call if done
  without the `SessionStart` cache step; should be measured before shipping, not assumed cheap.
- The `check_sync_setup()` extension in step 3 above is sketched, not written or tested.

## 7. Log

- 2026-10-24: Round 1. `web_search` (5 queries: agent-skill description best practices,
  LLM forgets instruction after subagent delegation, lost-in-the-middle instruction
  following, Claude Code hooks Stop block, none left for a 6th) plus one `webfetch` of
  assistant.posit.co/docs/features/hooks/ (fetched live, full page). No local tests. Decision
  pending with the user on whether to build the two-pipeline hook design above.
- 2026-10-24: Built and tested the R1 pipeline only (`scripts/skill-trigger-hook.sh`;
  R2's content-keyword nudge was deliberately not built, see section 4). Simplified away
  from the original sketch's "quote the instruction back" idea: extracting the `prompt`
  JSON field with a single-capture `sed` (the pattern `lessons-hook.sh` uses for structural
  fields) breaks on embedded quotes, which free user text will contain, so the script
  instead regexes the *whole* raw payload and the `Stop` block reason is a fixed generic
  string. Phrase regex (`grep -P`, PCRE negative lookahead to exclude a trailing `?`):
  `\b(trigger|use|load|invoke|apply)\b[^.?!\n]{0,60}\bskills?\b(?!\s*\?)` plus the passive
  form. Found and handled a real near-miss while designing it: "Is the pitfall a reason to
  trigger the lessons-learned rule in some of your skills?" (a question, from
  `conversation-export-3.json`) must not match, and does not, because of the lookahead;
  "Should we use a different skill here?" still matches (`?` is not immediately after the
  skill word) and is accepted as a known, low-cost false positive (one extra forced turn,
  bounded to once per session). Tested with twelve synthetic piped payloads on Windows (GNU
  bash 5.3, GNU grep 3.0, via the agent's sandboxed shell): no-match, explicit match, block
  on `Stop`, silent second `Stop` (reminded-once), `skill`-load clearing the marker before
  `Stop` so no block follows, `stop_hook_active` never blocks, missing `session_id` exits
  silently, embedded-quote prompt still detected, the question near-miss excluded, Windows
  `cwd` path handled, `DEBUG` payload logging, and malformed/empty stdin. Registered in the
  real `~/.posit/assistant/settings.json` (backed up first to
  `C:/Users/thorb/.posit/assistant/settings.json.bak-skilltrigger`): a new
  `UserPromptSubmit` entry, and a second hook added to the existing `PostToolUse`
  (matcher `skill`) and `Stop` groups alongside `lessons-hook.sh` (hooks are additive; both
  run). Extended `github-skill-maintenance/scripts/check_sync_setup.R` with a matching
  audit section (mirroring the existing lessons-hook audit) and ran it against the real
  settings file content (same R path-guard workaround as the existing lessons audit: read
  with `bash`/`cat`, parsed with `jsonlite::fromJSON(text=...)`, passed as `cfg`) — all
  `ok`, one `info` flagging that `grep -P` support in the actual hook execution shell is
  unverified from inside R. Documentation: new
  `github-skill-maintenance/references/skill-trigger-hook.md`, a workflow-step and two
  pitfall/tested-notes edits in `github-skill-maintenance/SKILL.md`. Found and recorded a
  linter gotcha while writing this: a backticked `scripts/<name>` path in a skill's own
  `SKILL.md` body is checked for existence *inside that skill's folder*, so a repo-root
  script (this one, like `lessons-hook.sh`) must be mentioned without the `scripts/` prefix
  there (reference files are not scanned by this check, which is why `skill-lessons/SKILL.md`
  never hit this). Verified clean: `lint_skills()`, `check_skill_links()`,
  `check_skill_clashes(new=)`, `uvx skills-ref validate`. Not tested: the hook firing inside
  a real conversation turn, `SubagentStop`, Linux/macOS, a second machine.
- 2026-10-24 (round 2): six `web_search` calls (no full-page fetches) prompted by a second,
  independent real recurrence of R2 (see section 6 and the `github-skill-maintenance` lesson
  `anon_20261024-audit_manual.md`). Confirmed the problem is common across the Claude
  Code/agent-skill ecosystem (open GitHub issues, troubleshooting guides, a 2026 arXiv paper on
  tool-selection drift) and found two independent prior implementations of close to the exact
  R2 mechanism this ledger had already sketched and declined to build (`msobroza/coding-agent-playbook`
  #58 "skill-nudge", `theitush/giverny` #358), both non-blocking `PostToolUse additionalContext`
  nudges. Narrowed the earlier false-positive objection (section 6.4) and produced a revised,
  not-yet-built design (section 6.5) that moves the keyword table into opt-in per-skill
  frontmatter instead of a central hardcoded list. No code written, no hook registered, no
  local tests. Decision pending with the user.

## 8. Round 3 (2026-10-26): real-session confirmation, and an escalation path

A third conversation export (`conversation-export.json`, dropped at the repo root, an
HPC/DeepLabCut session, `dlc-pig-method-paper`) was analysed at the user's request ("Analyze
why [skills] never triggered... suggest changes"). Both R1 and R2 were by this point built and
registered (see the log above), so unlike rounds 1 and 2 this was the first chance to observe
them firing in an actual session rather than synthetic payloads.

### 8.1 What the transcript showed

- Both file-signal nudges (R2) fired as designed and were visible in the transcript as
  `hook-feedback` blocks: once for `hpc-job-scripts` (after a `read` of a file containing
  `#SBATCH`) and once for `deeplabcut-hpc` (after a `bash` call touching DLC training-script
  content). **Neither was acted on** — the assistant's next turn moved straight to the next
  tool call with no reasoning trace engaging the hook content at all. This closes the
  "not tested: the hook firing inside a real conversation turn... confirmed [for Claude Code],
  not here" item from both R1 and R2's "Tested and not tested" sections (`additionalContext`
  *is* delivered and visible in Posit Assistant, matching the Claude Code prior art in section
  7.3) — and shows visibility alone is not sufficient, consistent with the PlanBench-XL
  reselection-bottleneck/recency-bias explanation already in section 6.2: by the time a second,
  unrelated tool call happens, the nudge is out of the "recent window" the same way the
  skill-list-at-session-start problem was.
- R1 also fired correctly, in the other direction: the user's turn 40 instruction ("Trigger
  your deeplabcut skill to record that as a lesson") set the pending marker, and the very next
  assistant turn did call `skill()` — but loaded `skill-lessons`, not `deeplabcut-hpc`. No
  `Stop` block was needed (the marker was cleared before `Stop` ran), so this is not a failure
  of the enforcement itself; it is the first live instance of the documented, accepted limit
  ("checks *some* `skill()` call happened, not whether it was the right one" — section "What it
  does and does not fix" in the reference doc). Arguably the right call in isolation (the
  instruction's actual intent, recording a lesson, routes through `skill-lessons`), but it means
  `deeplabcut-hpc` itself was never loaded in a session that was saturated with DLC-specific
  content (shuffle-indexing conventions, training orchestrator scripts, dataloader-worker
  tuning) that is squarely that skill's stated territory.
- Separately from the hooks: the very first user message in the session was a pasted terminal
  permission-denied error from a different host, and the assistant's first reply correctly
  noted it had no access to that host — but also, in the same reply, implicitly framed the
  whole topic as "not this workspace's concern" before the task turned out to be exactly that
  workspace's `input/` HPC scripts a few turns later. Not a hook finding (no tool call had
  happened yet to fire a file-signal match), but a plausible contributing anchor: nothing in the
  hook design addresses priming from an early, since-superseded framing.

### 8.2 Change made

Given R1's `Stop`-block mechanism already has an accepted, bounded cost (one forced turn, once
per session) and R2's repeated, *ignored* nudge is now a directly observed failure (not a
hypothetical), added an escalation path rather than reopening the non-blocking-vs-blocking
debate from round 2: a **second**, still-unaddressed file-signal nudge for the same skill in the
same session now writes a marker that feeds into R1's existing `Stop` block, naming the specific
skill(s), instead of repeating the same ignorable `additionalContext` line a second time.
`skill-file-signal-hook.sh` itself still never emits `decision:"block"` (unchanged invariant,
still guarded by `check_sync_setup()`); only `skill-trigger-hook.sh` blocks, now triggered by
either an explicit instruction or an escalated nudge, sharing the one-block-per-session budget.
Full design and all tested/not-tested detail:
`github-skill-maintenance/references/skill-trigger-hook.md` (the "2026-10-26 update" notes and
new "Escalation: a repeated, ignored nudge forces one block" section). Tested with synthetic
piped payloads only (first-match nudge, second-match escalation, a `skill` load clearing the
path between matches, two skills escalating together producing one combined block, an explicit
instruction plus an escalated nudge together producing one combined block, `bash -n`,
`check_sync_setup()`); not tested inside a real conversation turn. `lint_skills()` and
`check_skill_links()` re-run clean after the doc edits (pre-existing `description`-length `info`
notices on three unrelated skills, unchanged).

### 8.3 Deliberately not done this round

- Did not extend `file_signals` to more skills, and did not build a general content-based
  classifier — out of scope per section 7.5 item 4, unchanged.
- Did not try to fix R1's "wrong skill loaded" limit (e.g. parsing the requested skill name out
  of the user's free-text instruction) — the reference doc's own reasoning against extracting
  free text with a single-capture `sed` (embedded quotes) applies here too, and a wrong guess
  injected into a `Stop` block's `reason` would be a user-text extraction, not a controlled
  marker filename the way the R2 escalation's skill name is. Left as an open item below.
- Did not address the "early framing anchors the rest of the session" observation from 8.1 — no
  hook can observe or correct for a model's own earlier phrasing; it would need a prompt-level
  or description-level fix (e.g. the HPC/DeepLabCut skills already carry "even if the request
  doesn't name Slurm/HPC... check whether..." language for exactly this reason, which apparently
  was not enough here either). Recorded as an open item, not actioned.

### 8.4 Open items

- Whether the named-skill escalation block actually gets the *right* skill loaded (as opposed to
  just *a* `skill()` call) is unobserved — round 3 only exercised the unescalated R1 path for
  that question. Needs another real recurrence to tell.
- R1's "wrong skill loaded" limit (8.1, second bullet) is still open; no design proposed yet
  beyond the constraint noted in 8.3.
- ~~Whether to widen `file_signals` beyond the two seeded skills remains undecided~~ — resolved in
  round 4 below (2026-10-26, same day): the user asked to widen it now that the escalation
  mechanism exists.

## 9. Round 4 (2026-10-26, same day as round 3): widened `file_signals` to four more HPC skills

User request: extend `file_signals` to `hpc-gpu-jobs`, `hpc-resource-allocation`,
`hpc-python-code` and `hpc-r-code`, reasoning that the original hold-off (section 7.5 item 1,
"only hpc-job-scripts and deeplabcut-hpc... do not add it speculatively to the other skills")
was conditioned on the escalation mechanism (section 8) not existing yet.

### 9.1 Signals chosen

Each pattern reuses tokens the skill's own description or body already names as its subject
matter — not new invented keywords — mirroring how the two seeded skills' signals were chosen:

| Skill | `file_signals` | Rationale |
|---|---|---|
| `hpc-gpu-jobs` | `--gres=gpu\|--gpus[=:]\|\bCUDA_VISIBLE_DEVICES\b\|\btorchrun\b` | Slurm GPU request syntax, the GPU-visibility env var, and the PyTorch multi-GPU launcher the skill's description names directly. |
| `hpc-resource-allocation` | `OUT_OF_MEMORY\|\boom-kill\b\|\bsacct\b\|\bseff\b` | The Slurm job-state string, the kernel OOM-killer log line, and the two accounting commands (`sacct`/`seff`) the skill's description centres its "measure-then-size" workflow on. |
| `hpc-python-code` | `\bSIGUSR1\b\|signal\.signal\(signal\.SIGTERM` | The signal-handling pattern the skill specifically teaches (SIGUSR1/SIGTERM handling), distinct from the generic job-script content `hpc-job-scripts` already covers. |
| `hpc-r-code` | `parallelly::availableCores\|future\.batchtools\|\bR_LIBS_USER\b` | R/HPC-specific tokens the skill's description names (`parallelly::availableCores` instead of `detectCores`, `future.batchtools`, `R_LIBS_USER`), unambiguous to R code specifically. |

`hpc-cluster-docs` was deliberately **not** given a signal: it is a "run this first, before any
job script" skill about identifying which cluster/scheduler is in use, not keyed to a
distinguishing content pattern in a script — the same reasoning that excluded it from the
original seed list (section 7.5 item 1's "strong, low-ambiguity file signature" requirement).
Nothing in its description points at a specific string the way `#SBATCH` or `import deeplabcut`
do; adding a vague signal here would be exactly the "noise, not signal" case the design warns
against.

### 9.2 A real bug found by testing before shipping

Manually piping the new `hpc-gpu-jobs` signal through the hook (mirroring the existing test
recipe) failed immediately: `grep -qE "$pat"` treated the leading `--gres=gpu` alternative as a
`grep` *option* ("unknown option -- gres=gpu|..."), not a pattern, because the variable's value
starts with `--`. This was not caught by `lint_skills()` (which validates the pattern compiles as
an R regex via `grepl()`, a different regex engine with no option-parsing step) or by the
synthetic-payload tests in round 3 (none of the two seeded patterns started with `-`). Fixed by
adding the `--` end-of-options marker to the `grep` invocation in
`scripts/skill-file-signal-hook.sh` (`grep -qE -- "$pat"`), which is a one-line, order-independent
fix with no behaviour change for patterns that don't start with `-`. This is a second instance
(after the CRLF-reintroduction pitfall, hit again several times while editing this round) of a
class this ledger had not previously named: a check that validates a pattern as *a regex* does
not validate it as *safe `grep` command-line input* — the two are different contracts. Recorded
as a candidate `lint_skills()` extension below (9.4), not yet built.

### 9.3 Testing

Re-ran, after the `grep --` fix, the full chain for each of the four new signals plus
regression coverage: each pattern individually nudges its own skill and only its own skill (one
`torchrun` test, one `--gres=gpu` test matching both `hpc-gpu-jobs` and, correctly, also
`hpc-job-scripts` since the line also contains `#SBATCH` — an intentional overlap, not a bug,
since both skills are genuinely relevant to a GPU `sbatch` script); an unrelated `ggplot2` line
produces no nudge; a skill already marked loaded is correctly excluded while an unrelated
still-unloaded skill in the same session still nudges; the round-3 escalation path (second match
→ `pending.fs.<skill>` → named `Stop` block) still works with the fixed `grep` call and with two
of the newly-added skills (`hpc-gpu-jobs` + `hpc-job-scripts` together). `lint_skills()`,
`check_skill_links()`, and `check_sync_setup(cfg = <real settings.json>)` all re-run clean (no
new findings; the pre-existing three `description`-length `info` notices unchanged, and
`check_sync_setup()`'s "file-signal declaring skills" row now lists all six skills). **Not
tested:** any of the six signals firing inside a real conversation turn; whether six declared
skills (versus the original two) changes the cost of scanning frontmatter per matching tool call
in a way worth measuring (still unsized, per section 7.6/8.4).

### 9.4 Open items

- Candidate `lint_skills()` extension, not built this round: flag a `file_signals` alternative
  that starts with `-` (the exact pattern that caused 9.2), since the fix in the hook script
  covers execution but a future author could still write a leading-`-` alternative in a different
  shared script that calls `grep` without the same `--` guard; a linter check would catch it at
  author time instead of relying on every call site remembering the guard.
- Whether to widen `file_signals` further (`hpc-cluster-docs` with a different kind of signal,
  e.g. matching on an absence rather than a presence, or the `python-reproducible-pipeline` /
  `r-reproducible-pipeline` skills) is undiscussed and not proposed here.
