# Sources behind this skill

Curated for this skill's own use; the full research trail (every source read, what status, what
was rejected) is in this repo's `research/agents-md-maintenance-ledger.md`, not shipped with the
skill. Re-check this list periodically — it's web content, not a versioned spec.

## Core references

- Agent Skills specification, https://agentskills.io/specification — the authoritative spec for
  what belongs in a *skill* versus an always-loaded file; this skill's "promote to a skill"
  guidance follows its progressive-disclosure model (metadata always loaded, body on activation,
  resources on demand).
- Claude Code / Claude platform Agent Skills best-practices page,
  https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices — description
  style and sizing guidance shared across this repo's skills.

## AGENTS.md / CLAUDE.md hygiene

No single source is authoritative for an always-loaded project-memory file; the following
independent write-ups converge on the recommendations in `SKILL.md`:

- https://gist.github.com/0xfauzi/7c8f65572930a21efa62623557d83f6e — size targets, hierarchical
  nested files, "link instead of duplicating."
- https://www.augmentcode.com/blog/how-to-write-good-agents-dot-md-files — progressive
  disclosure, the "overexploration trap," pairing "don't" with "do."
- https://www.aihero.dev/a-complete-guide-to-agents-md — minimal root-file content, a concrete
  refactor prompt for an existing bloated file.
- https://atlan.com/know/how-to-write-agents-md/ — cites an ETH Zurich finding that instructions
  are followed better than repository overviews, and that context files add inference cost
  without reliably improving task success; the three-tier Always/Ask first/Never do framing.
- https://hboon.com/how-to-write-an-agents-md-that-actually-works/ — position matters (critical
  rules first), a monthly-review cadence, a "reflect loop" where the agent proposes additions for
  the user to curate.
- https://xtrace.ai/blog/too-many-claude-skill-files — symptoms of memory-file bloat, resolving
  contradictions by deleting the loser rather than archiving it somewhere still readable.
- https://dev.to/gabrielanhaia/your-claudemd-is-eating-your-context-keep-agent-memory-under-a-token-budget-lll —
  a decision table for where a given line belongs (always-loaded file, path-scoped rule, skill,
  hook, or delete); prune with evidence of what actually loads, not by feel.

## Subagent delegation for token economy

The evidence is mixed, which is why the skill's wording is conditional:

- https://gist.github.com/techygarg/f8f98a2f026538fad4a69b593a964d95 — delegate for reasoning
  isolation, not parallelism; don't delegate single-file edits or destructive operations; route
  mechanical work to cheaper models.
- https://dev.to/owen_fox/how-to-delegate-claude-code-tasks-to-mistral-vibe-save-2-4x-on-tokens-gp2 —
  concrete example of routing mechanical edits to a cheaper worker model while keeping a stronger
  model for planning.
- https://dev.to/promptmaster/single-agent-subagents-or-an-agent-team-when-multi-agent-coding-pays-off-2159 —
  delegate when a side task would otherwise flood the main conversation with content not needed
  again; subagent descriptions themselves cost context too.
- https://news.ycombinator.com/item?id=48883796 — counter-evidence: uncontrolled subagent fan-out,
  or subagents inheriting the expensive parent model, can burn more tokens than doing the task
  sequentially in the main thread.
