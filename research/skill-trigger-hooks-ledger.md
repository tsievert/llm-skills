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

## 6. Log

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
