# Research ledger: `agents-md-maintenance` skill

For the planned skill that audits/prunes/restructures `AGENTS.md`/`CLAUDE.md`/`DATABOT.md`
project-memory files for token economy. Read this before researching the topic again.

## 1. Requirements (user decisions)

| # | Decision | Date |
|---|---|---|
| R1 | Build a skill for maintaining `AGENTS.md`-type files: lean, well-formatted, token-economical, self-aware of bloat (this repo's own `AGENTS.md` was the trigger example). | 2026-10-24 |
| R2 | Every `AGENTS.md` the skill writes or reviews must carry a standing rule: delegate easy, mechanical, well-scoped tasks to a low-effort subagent to save tokens. | 2026-10-24 |

## 2. Sources (web search + fetch, 2026-10-24)

| Source | Status | Key claim used |
|---|---|---|
| agentskills.io/specification.md | read (fetched directly) | Frontmatter fields, 500-line/5000-token SKILL.md body guidance, progressive disclosure tiers, file-reference-one-level-deep rule. |
| platform.claude.com .../agent-skills/best-practices.md | read (webfetch summary) | Description in third person, "what + when", avoid vague names/helper-utils-tools, size limits, TOC for refs >100 lines, test activation. |
| gist.github.com/0xfauzi (AGENTS.md best practices) | read (search snippet) | <150 lines target, nested AGENTS.md hierarchy (nearest wins), link instead of duplicating, start at 20-30 lines and grow from real usage, audit quarterly, treat as code not static docs. |
| augmentcode.com blog (good/bad AGENTS.md study) | read (search snippet) | Progressive disclosure beats comprehensive coverage; push detail into reference files; "overexploration trap" from vague architecture prose; pair every "don't" with a "do"; ≤10-15 references per file. |
| aihero.dev "Complete Guide to AGENTS.md" | read (search snippet) | Minimal root content = 1-sentence description + package manager + non-standard build commands; move language-specific rules to separate files; gives a literal "fix a broken AGENTS.md" refactor prompt (find contradictions → extract essentials → group rest into files → flag for deletion). |
| paulswithers.github.io "AGENTS.md Engineering" | read (search snippet) | Keep lean and reference out; AGENTS.md for agent use only, README for humans; self-updating is hard for general instructions. |
| medium.com (agentic engineering project readiness) | read (search snippet) | "Does nearly every session need this?" test for each block; what should/shouldn't be in root file; don't try to generate a "complete" file from scratch. |
| realpython.com "How to Write an AGENTS.md" | read (search snippet) | Sections menu (coding conventions, constraints as positive actions, ignore rules pointing at `.gitignore`); short/sharp file, each block focused. |
| atlan.com "How to Write an AGENTS.md (2026)" | read (search snippet) | ETH Zurich finding: instructions followed, repository overviews not helpful, context files add >20% inference cost without reliably improving success; three-tier Boundaries model (Always do / Ask first / Never do); technical cap 32 KiB, practical aim <150 lines; "never put generic SE principles agent already knows," never duplicate README, never auto-generate the whole file with an LLM. |
| codex-best-practices (Duke OIT) | read (search snippet) | Codex-specific byte cap (`project_doc_max_bytes`, default 32 KiB); personal (`~/.codex/AGENTS.md`) vs project file split; natural-language instructions aren't guaranteed, pair with permission/sandbox config for firm control. |
| hboon.com "AGENTS.md that actually works" | read (search snippet) | Put critical/never-do rules at top (position matters); concrete do/don't pairs; <150 lines, extract >20-line sections into skills; monthly review, cut rules unused in a month; "reflect loop" (ask agent to propose additions at session end, human curates); re-run evals when trimming after model updates rather than just comparing wording. |
| dev.to/airscript (format should vary by harness) | read (search snippet) | AGENTS.md as a family of context surfaces, not one template; density (concise vs comprehensive) and layout (single/split/multifile) are deliberate choices tied to repo complexity and harness retrieval behaviour. |
| GitHub drona23/claude-token-efficient | read (search snippet) | Net token savings from a terse-behaviour file only materialize when output volume is high; low-volume/one-off use can be a net loss; community tip: many small path-scoped files beat one big file. |
| xtrace.ai "Too Many CLAUDE.md and Skill Files" | read (search snippet) | Symptom list for bloat (wrong skill fires, two files disagree and agent picks whichever loaded last, every session pays a tax); resolve contradictions by deleting the loser, not archiving where still readable; retrieval (RAG-style) vs always-loaded cuts cost ~50x but is a different architecture; target 100-200 lines, sweet spot 50-80. |
| dev.to/gabrielanhaia (token budget) | read (search snippet) | `/context`-style measurement before trimming; one-line-per-purpose table (build/test commands → always-loaded file; area-specific rules → path-scoped; multi-step procedure → skill; must-run-every-time → hook, not context; directory trees/dependency lists → delete, agent can read the code); imports don't reduce cost, only organize; prune with evidence (load frequency), not vibes. |
| mindstudio.ai (Claude cost settings) | read (search snippet) | Concrete token targets (global file <500 tokens, project file <1000 tokens); convert paragraphs to bullets for 40-50% cut; monthly review cadence. |
| ai-muninn.com (token burn-rate fixes) | read (search snippet) | Self-audit prompt pattern ("read your CLAUDE.md, flag what's stale, propose a version under N tokens"); explicit "use subagents for exploratory work" as one of the eight fixes — supports R2. |
| firecrawl.dev "12 ways to cut tokens" | read (search snippet) | HTML comments are stripped before injection (cost-free place for maintainer notes/rationale); `@path` imports still load fully at session start (organizational only); path-scoped `.claude/rules/` only cost context when the glob matches; one benchmark: 3847→312 tokens, "91.9% reduction, no quality regression," by keeping only what Claude cannot infer from the code. |
| gist.github.com/techygarg (subagent delegation economics) | read (search snippet) | Explicit decision rule: delegate for reasoning quality/isolation, not raw parallelism; don't delegate single-file/single-location edits or destructive ops; prefer 2-4 agents per wave; "use cheaper models for mechanical work (search, scaffolding, structural checks)" — directly supports R2's wording. |
| dev.to/owenfox (model-routing subagents) | read (search snippet) | Concrete pattern: keep an expensive/reasoning model for planning, route "rename this symbol," "add error handling," "extract this prop" style mechanical edits to a cheaper worker via a subagent description. |
| HN thread on sub-agent token burn | read (search snippet) | Counter-evidence: parallel sub-agent fan-out can burn *more* tokens than sequential single-agent work if subagents inherit the expensive parent model or over-explore; "I now have an explicit line in AGENTS.md to not use subagents unless explicitly requested" — the win depends on routing to a genuinely cheaper/lower-effort agent, not just delegating. |
| dev.to/promptmaster (single vs multi-agent) | read (search snippet) | Rule of thumb: delegate when a side task would flood the main conversation with search results/logs/file contents not needed again; subagent descriptions also cost context (Claude Code warns past 15k combined tokens), so keep them short too. |

## 3. Facts carried into the skill design

- No single numeric line/token limit is authoritative; cited targets range ~50-200 lines or
  roughly 300-2000 tokens depending on file role (global vs. project) and source. The skill
  should teach the *test* ("does nearly every session need this?"), not enforce one magic number,
  but can cite ~150 lines as a common rule-of-thumb trigger for "consider splitting."
- Consistent, convergent guidance across sources: (a) instructions > overviews, (b) split live
  rules from historical narrative/log, (c) progressive disclosure — push anything not needed
  every session into a skill, a reference file, or a nested/path-scoped file, (d) prune with
  evidence/review cadence rather than only growing the file, (e) never duplicate what's already
  in code, README, or `.gitignore`, (f) don't let an LLM generate the whole file from nothing.
- This repo's own `AGENTS.md` already implements several of these independently (HISTORY.md
  split, `research/` ledgers per topic, a todo table) — good worked example for the skill's body.
- The subagent-delegation rule (R2) is supported by evidence but **not unconditionally a token
  saver**: literature is split — it saves tokens only when the delegate genuinely runs on a
  cheaper/lower-effort model or isolates noisy context, and can *increase* total tokens when
  subagents fan out broadly, inherit the expensive parent model, or over-explore. The skill's
  wording must capture the condition, not just assert "delegate to save tokens."

## 4. Boundary check (vs. existing skills in this repo)

- `codebase-map` already owns inserting/maintaining one specific pointer section in
  `AGENTS.md`/`DATABOT.md` (to `.codemap/`). New skill must not duplicate that — hand off to it
  for that one section, own everything else about the file's structure and content.
- `create-skill` is for authoring new Agent Skills (SKILL.md for a *skill*), not for the
  project's own memory file. Different artifact; name it as a hand-off for "turn this bloated
  section into a skill" moments.
- `github-skill-maintenance` already touches this repo's own `AGENTS.md` (todo table, lessons
  watermark) but as a side effect of its own workflow, not as a general-purpose AGENTS.md
  hygiene tool for *other* projects. No direct overlap, but worth a hand-off note both ways if
  this repo is ever the subject.
- Not yet run: `check_skill_clashes(new = "agents-md-maintenance")` (skill directory doesn't
  exist yet — needs at least a draft SKILL.md with frontmatter to score against).

## 5. Open research items

- Whether to also cover monorepo/nested `AGENTS.md` hierarchies (several sources describe
  "nearest file wins") — likely out of scope for this user's workflow (single-repo, mostly
  skills repo + analysis projects) unless a concrete need appears.
- Whether to build a lint-style script (counting lines/tokens, flagging stale "open decisions"
  entries) similar to `github-skill-maintenance/scripts/lint_skills.R`, or keep this as pure
  reviewer judgement. Not decided yet.

## 6. Log

- 2026-10-24: Ran 4 web searches (AGENTS.md best practices, CLAUDE.md token bloat, agentskills.io
  spec, subagent delegation for tokens) and fetched the two docs `create-skill` requires
  (agentskills.io/specification.md, Claude best-practices page). Read `skill-boundaries.md` and
  `codebase-map/SKILL.md` for boundary-setting. Not yet done: drafting the actual SKILL.md,
  running `check_skill_clashes()`, `lint_skills()`, `check_skill_links()`.
