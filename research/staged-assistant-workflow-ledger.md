# Research: triggering `staged-assistant-workflow` (2026-10-28)

No dedicated research ledger existed for this skill before now — it was built directly from one
real refactor (see `HISTORY.md`) with no separate research round, unlike most other skills in this
repo. This ledger fills that gap, prompted by the user asking (1) whether Plan-mode activation
could trigger it, (2) whether an AGENTS.md note tying it to Plan mode would help, and (3) whether
the assistant can self-detect conversation length/complexity/token usage as a trigger signal.

## 0. Handoff (read this first if picking this up in a fresh conversation)

**Where this stands:** research only, nothing built or committed yet. The conversation that
produced this ledger got long enough that the user asked for the research to be made self-contained
here rather than carried in conversation memory — treat this section, not conversation history, as
the authoritative state.

**Decided (confirmed with the user, don't re-litigate without new evidence):**
1. Don't hook `EnterMode`/Plan-mode entry directly for this skill (§3.2) — too high a
   false-positive rate, since most Plan-mode use is one-off, not long/recurring.
2. The skill's defining trigger is **anticipated context/token exhaustion from a task's own
   length**, not recurrence (§6.2). The user explicitly corrected the initial framing (which had
   leaned on "recurring or long") toward this. Literature backs it: Anthropic's "structured
   note-taking" / practitioner "GSD framework" / phased-execution sources all frame this as a
   single-task context-management problem, no recurrence required (§6.1).
3. Fully-deterministic recurring tasks stay routed to `r-reproducible-pipeline` /
   `python-reproducible-pipeline`, unchanged from before.
4. A real, not-yet-resolved gap: a recurring task that still needs assistant *judgment* each run
   (the job-opportunity-watch case this skill was generalized from) doesn't fit a pure pipeline
   skill. Recommended (not yet agreed) resolution: keep it as a secondary, explicitly-named use
   case of the same stage-table mechanism rather than deleting recurrence from scope outright
   (§6.2, last bullet).

**Progress (2026-10-28, same day as this ledger) — see the dated log entry below for details.
Original "not yet done" list, now partly superseded:**
1. Get the user's explicit sign-off on the §6.2 resolution for the recurring-with-judgment gap
   (bullet 4 above) — this determines whether the rewrite in step 2 keeps a recurring-use-case
   paragraph or drops recurrence from the skill entirely.
2. Rewrite `staged-assistant-workflow/SKILL.md`: frontmatter `description`, the "When to reach for
   this vs. a plain pipeline" table, and any other recurrence-centered wording in the body, to
   center length/context-bloat as the headline trigger (keep the job-opportunity-watch origin
   story, since it's still a valid example — a recurring task that happened to also need staging
   because of judgment, not staged *because* it recurs).
3. Fix the stale backlink in `agents-md-maintenance/SKILL.md`'s "Related skills" section (currently
   reads "when a work stream is recurring (not just long)" — has the emphasis backwards per the
   §6.2 decision; should read something like "when a long or complex work stream needs named
   stages, gates, and a status function, rather than a single hand-off note").
4. Only after 1-3: revisit the trigger-design options already sketched (§5.1 prompt-content
   signal, §5.2 transcript-length signal) — they were designed before the rescoping decision and
   may need their keyword lists adjusted (e.g. §5.1's phrase list is currently recurrence-only;
   add length/duration phrasing like "this is going to be a huge task" / "will take many sessions"
   now that recurrence isn't the sole criterion).
5. Run `lint_skills()` / `check_skill_links()` / `check_skill_clashes()` (per this repo's standing
   "verify before reporting ready" rule) after any of the above edits, before telling the user
   anything is ready.

**How to resume:** read this section, then §6 in full (the scope-correction round) before §§1-5
(the original, now partly-superseded Q1-Q3 research) — §6 supersedes §§3-4's framing on recurrence
specifically, but §§2, 3.2's `EnterMode`-mechanics finding, and §5's hook-design sketches are still
accurate and not superseded.

## 1. Requirements (user questions, 2026-10-28)

| # | Question | Answer (short) |
|---|---|---|
| Q1 | Can Plan-mode activation fire a hook that nudges toward this skill? | Partially — see §3. No dedicated Plan-mode hook event exists, but `EnterMode` is a regular tool call and is hookable via `PreToolUse`/`PostToolUse` matcher `EnterMode`. However, Plan mode's own stated use cases (multi-step features, refactors, architecture) are mostly one-off, not recurring — so firing on every Plan-mode entry would mismatch this skill's actual trigger condition more often than it would match it (see §3.2). |
| Q2 | Should AGENTS.md carry a note to invoke this skill together with Plan mode? | A narrower version yes: Plan mode is a reasonable place for the assistant to *notice* recurrence/long-horizon cues (see §4), not a place to reflexively invoke the skill. Recorded as a recommendation, not yet written into AGENTS.md pending user sign-off on wording. |
| Q3 | Can the assistant self-detect conversation length, complexity, or token usage as a trigger? | The assistant (model) cannot — token/length counters are a host-UI feature not exposed to the model's own context or any tool (see §2). A *hook* can approximate length by reading `transcript_path`, which every hook payload after `SessionStart` includes. This is a new, unbuilt design, distinct from the content-keyword (`file_signals`) and explicit-instruction (R1) nudges already built for other skills — see §5. |

## 2. What the assistant itself can and cannot observe (sources read)

Read live, full page (not from memory, per this repo's working rules):
`https://assistant.posit.co/docs/features/hooks/` and
`https://assistant.posit.co/docs/features/context-management/` and
`https://assistant.posit.co/docs/features/plan-mode/`.

- Context Management page: the token counter and Session HUD breakdown are **UI-only**
  features (status bar, a HUD panel) — the docs describe them as things *you* (the user) view
  and click, with no mention of this information being surfaced back into the model's own
  context or exposed via a tool. There is no `getTokenUsage`-style tool in this assistant's tool
  list, and none of the hook payload fields (checked exhaustively below) carry it either.
- Hooks page, full "Hook input" field table: common fields on every event are `session_id`,
  `transcript_path`, `cwd`, `hook_event_name`, plus `permission_mode` on four events. Per-event
  extra fields (`tool_name`/`tool_input`/`tool_response`, `prompt`, `source`, `reason`,
  `stop_hook_active`/`last_assistant_message`, `agent_id`/`agent_type`,
  `notification_type`/`message`) contain **no turn count, token count, or context-window-usage
  field anywhere**. This was cross-checked against the complete per-event table, not inferred.
- Confirmed absent: no `PlanModeStart`/`PlanModeEnd`/`ModeChange` event exists. The full `Events`
  table lists exactly nine events (`SessionStart`, `SessionEnd`, `UserPromptSubmit`,
  `PreToolUse`, `PostToolUse`, `Stop`, `SubagentStart`, `SubagentStop`, `Notification`); Plan mode
  is not one of them.
- **What a hook *can* do instead:** every event from `SessionStart` onward carries
  `transcript_path` ("the conversation's transcript file"). A hook script can stat or read that
  file directly — file size, line count, or a rough message/turn count — as a proxy for
  conversation length, entirely independent of the model's own self-report. This is a
  deterministic, host-independent measurement, not a model self-assessment, which matches this
  repo's general preference (per `skill-trigger-hooks-ledger.md` §7.2's citation) for putting
  "a step that must happen every time" in a hook rather than a standing instruction a model may
  defer. Not yet attempted here — no local test of reading a real `transcript_path` file's
  format was done this round.
- "Complexity" has no proxy at all in any payload or doc read — unlike length (file size/line
  count is a crude but real measurement), complexity is not something transcript metadata
  encodes. Any complexity-based trigger would have to stay a model judgment call, not a hook
  check.

## 3. Plan mode as a trigger (Q1, in depth)

### 3.1 What Plan mode actually is for
Read `https://assistant.posit.co/docs/features/plan-mode/` in full. Its own "When to Use Plan
Mode" section names (cite index="n/a — paraphrase of a four-item bullet list, not a verbatim
quote") multi-step features spanning several files, complex refactoring, unfamiliar codebases,
and architectural decisions — none of these are inherently *recurring* or *too long for one
conversation* in the sense `staged-assistant-workflow`'s own description targets ("a task that
repeats on a schedule or keeps growing past one conversation"). A single complex refactor planned
in Plan mode is very often still a one-conversation (or few-conversation) job with no recurrence
and no need for file-based stage hand-offs.

### 3.2 Why a blanket Plan-mode hook is the wrong shape
`EnterMode` is hookable (`PreToolUse`/`PostToolUse` matcher `EnterMode`, with `tool_input.mode`
holding `"Plan"` or `"Cleaning"` per this assistant's own `EnterMode` tool schema and
`tool_input.title` holding the free-text plan title, if supplied). A hook *could* fire an
`additionalContext` nudge on every `EnterMode(mode="Plan")` call. But per §3.1, most Plan-mode
entries are not staged-workflow candidates, so this would be a high-false-positive nudge — closer
to the risk profile the existing `skill-trigger-hooks-ledger.md` explicitly tried to avoid for
content signals ("a keyword hit cannot judge 'should this skill have fired'"), except worse here
because the base rate of true positives is lower (recurring/multi-session tasks are a minority of
Plan-mode uses, whereas `#SBATCH` really is specific to HPC skills). A hook has no field to
distinguish "planning a one-off refactor" from "planning a weekly digest pipeline" — `tool_input`
for `EnterMode` is just `{mode, title}`, and `title` is short free text the user may not have
written yet (the tool call can happen before the title is finalized in some flows) and is
exactly the kind of un-anchored free text the R1 design in `skill-trigger-hooks-ledger.md`
already flagged as fragile to regex against (embedded phrasing varies, false positives on casual
wording).

### 3.3 Conclusion on Q1
Don't hook `EnterMode` directly for this skill. The useful version of the idea survives as a
**prompt-content signal**, not a mode-entry signal: watch for recurrence/long-horizon *language*
in the user's own request, wherever it appears (Plan mode or not) — see §5.1.

## 4. AGENTS.md note tying the skill to Plan mode (Q2)

A loose, unconditional note ("always load staged-assistant-workflow when entering Plan mode")
would just relocate the false-positive problem from a hook into prose the assistant reads every
session — no better than today's status quo where the assistant is expected to pick the right
skill from context. The narrower, defensible version: add a short conditional line near Plan
mode's existing use in this repo's own workflow (there isn't one yet — this repo has not
previously connected Plan mode and this skill in AGENTS.md) stating that *if*, while in Plan mode,
the task under discussion turns out to be recurring, scheduled, or likely to span many
conversations, the plan should explicitly consider staging it per `staged-assistant-workflow`
rather than writing a single flat implementation plan. This is phrased as a conditional check
during planning, not a blanket require-this-skill rule — consistent with this repo's own
"Consider a subagent-delegation rule per skill" precedent (a judgment call, not a requirement for
every case). Not yet written into AGENTS.md; wording needs the user's sign-off first.

**Superseded note (see §6.2):** the wording sketched above still leans on "recurring, scheduled,
or likely to span many conversations" as the trigger language. Once the SKILL.md rewrite in the
handoff's step 2 lands, this wording should be revised to lead with length/complexity ("the task
looks likely to outgrow one conversation's context") and mention recurrence only as one example,
not the headline condition.

## 5. Buildable trigger designs (not yet built)

### 5.1 Prompt-content signal (extends the existing R1 mechanism)
`skill-trigger-hook.sh` already regexes `UserPromptSubmit`'s `prompt` field for explicit
"trigger the skill" phrasing (see `skill-trigger-hooks-ledger.md` §7, "Log", 2026-10-24 entry).
The same hook family could gain a second, narrower phrase set aimed at *this* skill specifically:
recurrence/duration words a user would plausibly use when describing a task that needs staging —
`\b(weekly|daily|recurring|periodic|every (week|day|month))\b`,
`\b(spans|spanning) (many|multiple) (conversations|sessions)\b`,
`\btoo (long|big) for one (conversation|session|chat)\b`. On a match, a non-blocking
`additionalContext` nudge naming `staged-assistant-workflow` — same dedup-per-session convention
as the existing nudges, never a block (recurrence language is a much weaker signal than an
explicit "use this skill" instruction, so it shouldn't escalate to `Stop` the way R1's explicit
instruction does).

**Needs updating per §6.2:** this phrase list is recurrence-only. Add length/duration phrasing
once the rescoping lands, e.g. `\b(huge|massive|very large) (task|project|refactor|build)\b`,
`\b(many|several|multiple) (sessions|conversations) (to finish|to complete)\b`, `\bwill take
(weeks|days) to (finish|build|implement)\b` — not yet drafted or tested, see handoff step 4.

### 5.2 Transcript-length signal (new — not discussed in the existing ledger)
A `UserPromptSubmit` or `PostToolUse` (no matcher, i.e. every call) hook reading
`transcript_path`'s file size (or counting occurrences of a turn-boundary marker, format
unverified — needs a real transcript file inspected before this is buildable) and, past a
threshold, emitting a once-per-session nudge: "this conversation has grown large; if the
remaining work is substantial, consider whether splitting it into stages
(`staged-assistant-workflow`) would help." This directly answers Q3's "can length serve as a
trigger" — yes, but only via a hook measuring the file on disk, never via the model noticing its
own token budget, which it cannot see. Two cautions, both unresolved: (a) the transcript file's
actual structure (JSON lines? one object? compacted vs. raw?) has not been inspected, so the
"file size as a length proxy" claim is untested; (b) under the original (now-superseded, see §6.2)
framing this bullet worried that "a long conversation is not the same signal as a *recurring*
task" — that worry mostly dissolves once length/complexity (not recurrence) is the actual target,
but the nudge text should still avoid implying *every* long conversation needs staging (some are
better served by plain `/compact`, e.g. a long but linear data-exploration session with no
separable stages/artifacts).

## 6. Round 2 (2026-10-28): is "long, not recurring" a real, separately-studied problem?

Prompted by the user pushing back on §1/§3-4's framing: their mental model is that this skill
exists to stop a **single** long task from flooding context/token budget by splitting it into
stages a fresh session can pick up — recurrence is incidental, not the defining criterion — and
recurring tasks belong to the pipeline skills instead. Six `web_search` calls (budget allows at
most 5 per turn, used across two consecutive turns), reading search-result snippets only (no full
page fetches this round).

### 6.1 Yes — this is a named, well-studied problem, independent of recurrence

- Anthropic's own applied-AI team names this exact problem and the exact mechanism. Their post
  frames it as one of three long-horizon techniques: (cite index="30-8">compaction, structured note-taking, and multi-agent architectures</cite>.
  **Structured note-taking** is the closest documented ancestor of this skill's
  "file hand-offs, not conversation memory" core piece — persisting state outside the context
  window so it survives a session boundary, described elsewhere as (cite index="33-7,33-8,33-9">stores persistent memory outside the context window. The model can write to files like NOTES.md or TODO.txt, then reload them later. This strategy enables long-horizon coherence without overloading the context window.</cite>
  Nothing in Anthropic's framing ties this to recurrence — it's about a task whose **own** length
  exceeds one window, exactly the user's framing.
- Practitioner sources independently converge on the same "split one long task into
  session-sized, file-handed-off phases" pattern, again with no recurrence requirement:
  one explicitly lists (cite index="21-2">Fresh sessions</cite> as a fix for "Switching tasks or
  recovering from degraded output" and (cite index="21-2">Plan files</cite> for "Long-running
  implementation tasks", both single-task framings. Another names the same idea as a named
  framework: (cite index="23-7,23-8,23-9">Each phase has a natural context boundary. When a phase ends, you don't carry all its exploratory conversation into the next one. You carry only the output: a plan, a spec, a decision log.</cite>
  explicitly scoped to (cite index="23-11">projects that span more than a single session</cite> —
  a duration/complexity criterion, not a recurrence one.
- A third source frames the mechanism this skill's "resumable per-item batches" piece maps onto —
  per-item checkpointing so a stage can resume instead of restarting — as a general answer to
  "the agent lost its plan": (cite index="12-1,12-2">A prose summary is not a checkpoint. Three files, one boot rule, and a WAL line keep a long agent run alive across context compaction</cite>,
  again a single-long-task framing with no recurrence angle at all.
- The academic literature (Context-Folding, Scroll/"Context as an Environment", ACM, HyMem,
  AdaCoM — all 2026 arXiv preprints found this round) studies a closely related but **narrower**
  problem: automated, in-model-loop context management (branch/fold, external executable session
  environments, RL-trained compression) *within a single agent run*, not the human-in-the-loop,
  multi-conversation, file-based hand-off this skill actually prescribes. It's adjacent evidence
  that context-length-driven task splitting is a live, named research area, not applicable
  methodology to copy directly — this skill's actual mechanism is much closer to the practitioner
  "GSD framework"/"structured note-taking" layer than to any RL-trained agent architecture.

### 6.2 What this changes about the skill's scope (decision, pending the edit)

The evidence supports the user's correction: **the defining trigger is anticipated context/token
exhaustion from a task's own length**, not recurrence. Recurrence (a weekly digest) is just one
common *reason* a task's cumulative context would otherwise exceed one session — a single very
long one-off build exhausts context the same way, for the same reason, and benefits from the same
stage-table/file-hand-off/gate mechanism. Concretely, this means:

- The frontmatter description's disjunctive wording ("repeats on a schedule **or** keeps growing
  past one conversation") was already closer to correct than the body; the body's decision table
  and the `agents-md-maintenance` backlink (its line reads "when a work stream is recurring (not
  just long)") have the emphasis backwards and should be corrected to center length/complexity,
  not recurrence.
- Recurring tasks that are **fully deterministic** (no assistant judgment at any stage) are
  already correctly routed to `r-reproducible-pipeline`/`python-reproducible-pipeline` — that
  part of the existing design holds and matches the user's "like the pipeline skill" instinct.
- Gap to flag, not silently drop: a recurring task that **does** need assistant judgment at some
  stage (the job-opportunity-watch case this skill was originally generalized from) doesn't fit a
  pure pipeline skill and would lose its home if recurrence is removed from this skill's scope
  entirely. The mechanism (stage table, gates, status function) doesn't actually care *why* a task
  needs staging — recurrence and raw length are two different reasons to reach for the identical
  pattern. Recommended resolution: recenter the skill's framing on length/context-bloat as the
  primary, headline driver (matching the user's model and the literature above), while keeping
  recurring-with-judgment work as a secondary, explicitly-named use case of the same mechanism
  rather than deleting it outright.

## 7. Open items (nothing built this round — research only, per the user's request)

- Neither §5.1 nor §5.2 has been written, tested, or approved. This round was research only.
- §5.2 needs a real `transcript_path` file inspected (format, size scale for a "normal" vs.
  "long" conversation) before a threshold can be chosen.
- No decision yet on whether §5.1's phrase list (recurrence *or* the new length/duration variants
  sketched in §5.1's "needs updating" note) risks the same false-positive class R1's phrase regex
  was tuned against (e.g. "I check my email weekly" containing "weekly" with no task relevance) —
  needs the same negative/positive example discipline as `references/testing-skills.md`'s
  trigger-query protocol before shipping.
- §4's AGENTS.md wording is drafted in prose above but not committed to the file, and per §6.2 and
  §4's "superseded note" still needs revising to lead with length rather than recurrence.
- Whether to route any of this through the existing shared `skill-trigger-hook.sh` /
  `skill-file-signal-hook.sh` scripts (adding a third concern) or a new sibling script is
  undecided — mirrors the "one script per repeated-event family" question already open in
  `skill-trigger-hooks-ledger.md`.
- The handoff's step 1 (user sign-off on the recurring-with-judgment resolution) has not happened
  yet — do not skip straight to the SKILL.md rewrite without it.

## 8. Log: 2026-10-28, handoff steps 1-3 executed

User sign-off obtained in the same conversation that surfaced this ledger: keep the
recurring-with-judgment case as a secondary, explicitly-named use case of the stage-table
mechanism (the section 6.2 recommendation), not a reason to delete recurrence from scope.

Done this round:
1. **Handoff step 2** -- rewrote `staged-assistant-workflow/SKILL.md`: frontmatter `description`,
   the intro paragraph, and the "When to reach for this vs. a plain pipeline" table now lead with
   length/complexity/context-exhaustion as the headline trigger. A recurring-plus-judgment task
   (the job-opportunity-watch origin case) is kept as one explicitly-named row/case, not the
   defining criterion -- matching section 6.2's recommendation rather than deleting recurrence
   outright.
2. **Handoff step 3** -- fixed the stale backlink in `agents-md-maintenance/SKILL.md`'s "Related
   skills" section: was "when a work stream is recurring (not just long)" (emphasis backwards per
   section 6.2); now "when a long or complex work stream needs named stages, gates, and a status
   function... (a recurring schedule with assistant judgment at some stage is one specific case of
   this, not the defining one)".
3. **Handoff step 5 (verification), scoped to steps 1-3's edits** -- re-ran, per this repo's
   standing "verify before reporting ready" rule: `lint_skills()` (only pre-existing info-level
   notes remain, e.g. this skill's description at 993/1024 characters -- not a new finding, no
   errors anywhere), `check_skill_links()` (clean across all 30 skills), `check_skill_clashes(new =
   "staged-assistant-workflow")` (clean, threshold 0.15, 30 skills), and
   `uvx --from skills-ref agentskills validate staged-assistant-workflow` ("Valid skill"). Note:
   running `validate .` from inside the skill folder fails the directory-name check (the directory
   is named `.` from that vantage point) -- run `validate <skill-name>` from the repo root instead.

Not done this round (still open, per the original handoff's step 4 and section 7 above):
- Handoff step 4 -- the section 5.1/5.2 trigger-design sketches have not been revisited or
  rewritten. Section 5.1's phrase list is still recurrence-only; it needs length/duration phrasing
  added before any hook is built from it.
- Not committed to git. `staged-assistant-workflow/SKILL.md` and `agents-md-maintenance/SKILL.md`
  are both edited in the working tree; ask the user before committing/pushing.
- `HISTORY.md` has not been updated with a closing entry for this round -- do that once the
  remaining handoff step (or the user's decision to stop here) is settled, per this repo's
  convention of logging there rather than in `AGENTS.md`.
