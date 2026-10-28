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

## 9. Round 3 (2026-10-28, same session): handoff step 4, with a live finding mid-research

Prompted by the user: "look into hooks and other means to trigger this skill efficiently." This
round's own tool calls incidentally triggered both existing skill-trigger hooks while reading their
source for reference -- a real, unplanned test of the exact mechanisms being evaluated, kept and
reported here rather than discarded as noise.

### 9.1 Live false positives found while reading the existing hooks (not staged-assistant-workflow-specific, but directly informs the design below)

- **R1 (`skill-trigger-hook.sh`, explicit-instruction detector):** the user's own prompt this round
  -- "Look into hooks and other means to trigger this skill efficiently" -- matched
  `TRIGGER_RE` (`trigger ... skill` within 60 characters) and set a `.pending` marker, even though
  the sentence is a request to *research* triggering, not an instruction to *load* a skill right
  now. This is the same "question/meta-discussion near-miss" class already documented in
  `github-skill-maintenance/references/skill-trigger-hook.md` ("Should we use a different skill
  here?"), now confirmed for a declarative (non-question) meta-sentence too -- the accepted-false-
  positive class is broader than just questions.
- **R2 (`skill-file-signal-hook.sh`, file-signal nudge):** reading this round's own source material
  -- `scripts/skill-trigger-hook.sh`, `scripts/skill-file-signal-hook.sh`, and
  `github-skill-maintenance/references/skill-trigger-hook.md` via the `read`/`bash` tools -- tripped
  nudges (and, on a second hit, escalation markers) for `deeplabcut-hpc`, `hpc-gpu-jobs`,
  `hpc-job-scripts`, `hpc-r-code`, and `hpc-resource-allocation`. None of this round's work touches
  HPC or DeepLabCut; the match was on the `file_signals` example patterns themselves (`sbatch`,
  `SIGUSR1`, `--gres=gpu`, etc.) appearing *as literal text* inside documentation that describes
  those patterns. This is a self-referential/meta false positive the existing ledger (section 6.5,
  step 1) did not anticipate: `file_signals` assumes a match means "this looks like a real HPC
  script", but a skill-authoring conversation that merely *discusses* another skill's signal text
  triggers the same hook. Cleared the stale markers for this session afterward (diagnosed as false
  positives, not left as an open block) rather than letting the next `Stop` force an unrelated
  "load `hpc-job-scripts`" block. **Not fixed**: this is a real gap in `skill-file-signal-hook.sh`
  worth a `skill-lessons` entry for `github-skill-maintenance`/`skill-trigger-hooks-ledger.md`
  (logged as an open item below, not fixed this round -- out of scope for step 4).

### 9.2 Resolved: `transcript_path`'s actual structure (closes an open item from section 2 and section 5.2)

Enabled the hooks' own `DEBUG` switch (`touch ~/.posit/skill-triggers/state/DEBUG`) for two of this
session's own tool calls, inspected the captured payload, then disabled it and deleted the capture
file again (per the hook docs' own "may hold private content, delete afterwards" instruction).

Finding: `transcript_path` is **not** a growing conversation log. It is a small JSON *index* file
(`conversation.json`, example: 2.9 KB after ~80 lm-messages in this very session) holding only the
turn tree (parent/child message-group ids) -- it grows by a few bytes per turn, not per token, so
its file size is a poor proxy for context/token growth, contrary to section 2's untested assumption.

The real content lives in two sibling files in the **same directory** as `transcript_path`
(`dirname(transcript_path)`), neither named in the hooks docs' field table:

| File | What (observed, this session) | Size this session |
|---|---|---|
| `lm-messages.jsonl` | one JSON object per line, one per LM-level message (`role`: `user`/`assistant`/`tool`); this is the actual content sent to/from the model, including full tool inputs/outputs | 276 KB, 82 lines |
| `ui-messages.jsonl` | one JSON object per line, coarser-grained (UI-level turns, not LM messages) | 211 KB, 6 lines |
| `usage-events.jsonl` | present but not inspected this round | 2.2 KB |

This resolves section 5.2's design: a length-based hook should stat (or `wc -l`) **`lm-messages.jsonl`
next to `transcript_path`**, not `transcript_path` itself. Byte size tracks cumulative context
reasonably well (it includes full tool outputs, which is exactly what consumes the model's context
window), though a single large `read`/`grep`/`bash` result can inflate it without the task actually
being "long" in the sense this skill cares about -- so it is a proxy for context *pressure*, not a
perfect proxy for "this task needs staging." One data point only (this session, a real multi-file
research-and-edit task, hit 276 KB over ~80 LM messages); no threshold has been calibrated against a
second example, and none should be picked from a single observation.

### 9.3 Revised recommendation for the two sketches

- **5.1 (prompt-content phrase nudge):** still worth building, on the same non-blocking,
  `additionalContext`-only, dedup-per-session basis as the existing R1/R2 nudges -- the bounded cost
  (one ignorable line, or at most one forced `Stop` turn if escalated the same way R2 escalates) is
  the same accepted risk class as the finding in 9.1, not a new one. Phrase list, revised to lead
  with length/complexity per the section 6 rescoping (not recurrence-only):
  `\b(huge|massive|very large|too (big|long))\b[^.?!\n]{0,40}\b(task|project|build|refactor)\b`,
  `\b(many|several|multiple)\b[^.?!\n]{0,30}\b(sessions|conversations)\b[^.?!\n]{0,20}\b(finish|complete|build)\b`,
  `\bwill take\b[^.?!\n]{0,30}\b(weeks|days|sessions)\b`, plus the original recurrence set
  (`\b(weekly|daily|recurring|periodic|every (week|day|month))\b`) kept as a secondary pattern per
  section 6.2's "recurrence is one case, not the definition." Not yet implemented or tested against
  negative examples (same discipline `testing-skills.md` requires) -- this round only drafted the
  patterns, per the user's "research" framing.
- **5.2 (content-growth signal):** now concretely buildable (9.2 closes the structural unknown), but
  still needs a second real session's `lm-messages.jsonl` growth curve before picking a byte
  threshold -- one data point is not enough to calibrate a nudge that fires at the right time rather
  than too early (noisy) or too late (useless). Recommend: collect the size at a few natural check
  points (e.g. whenever `skill-lessons` or `agents-md-maintenance` is invoked, since those already
  mark "this work stream is wrapping up or handing off") across a few real sessions before writing
  the hook, rather than guessing a number now.
- Neither is built this round. Per this repo's standing rule, any new hook needs `check_sync_setup()`
  coverage and the user's sign-off on the settings.json change before being added -- not sought yet.

### 9.4 Open items (new this round)

- The R2 self-referential false-positive class found in 9.1 is a real gap in
  `skill-file-signal-hook.sh`/`skill-trigger-hooks-ledger.md`, not just a staged-assistant-workflow
  concern -- recorded here with a pointer, but not filed as a formal lesson or fixed yet. A plausible
  mitigation (restricting matches to files outside `github-skill-maintenance`/research-ledger paths,
  or more simply, only matching within code/script content, not prose) is not designed.
  Cross-referenced from `skill-trigger-hooks-ledger.md`'s own log (see its entry for this date).
- 5.1's revised phrase list is drafted, not implemented or tested.
- 5.2's design is now unblocked but needs a second session's data before a threshold is chosen; not
  scheduled.
- The handoff's step 4 is now addressed at the research level; building either design still needs
  the user's go-ahead (new hook = settings.json change + `check_sync_setup()` coverage, per the
  repo's "verify before reporting ready" rule).

## 10. Log: 2026-10-28, same session, step 4's 5.1 built (user-approved)

User approved building the 5.1 prompt-content nudge now, reusing existing hook infrastructure
without new calibration (distinct from 5.2, which still needs a second session's growth curve --
not built this round).

Implementation, reusing `skill-file-signal-hook.sh` rather than adding a new script: added a
`metadata.prompt_signals` frontmatter field (same shape as `file_signals`: one `'|'`-separated
regex string) to `staged-assistant-workflow/SKILL.md`, with the length/complexity-led phrase set
drafted in section 9.3 (length/complexity phrases first, recurrence phrases kept as a named,
secondary alternative per section 6's rescoping). Extended `skill-file-signal-hook.sh` with a new
`UserPromptSubmit` case and a shared `check_signal()` helper so both the file-content and
prompt-content channels use identical nudge-once/escalate-on-repeat logic and marker namespace
(`$sid.loaded.<skill>` / `$sid.nudged.<skill>` / `$sid.pending.fs.<skill>`) -- a skill nudged via
either channel is not nudged again via the other, and a second ignored hit on either channel still
escalates into `skill-trigger-hook.sh`'s existing `Stop` block, with no changes needed to that
script. Added matching `lint_skills()` and `check_sync_setup()` coverage for `prompt_signals`
(mirroring the existing `file_signals` checks), and a new subsection in
`github-skill-maintenance/references/skill-trigger-hook.md` ("The prompt-signal channel"). Wired
into the real `~/.posit/assistant/settings.json` (`skill-file-signal-hook.sh` added to
`hooks.UserPromptSubmit`, additive alongside the existing `skill-trigger-hook.sh` entry).

Verified: `bash -n` on the edited hook script; a full synthetic-payload test matrix (first-hit
nudge, second-hit escalation, unrelated prompt silent, length-phrase and recurrence-phrase
alternatives both match, already-loaded skill never nudged via either channel, embedded quotes
still detected, missing session_id and malformed stdin do not crash) plus a regression check that
the pre-existing `file_signals`/`PostToolUse` channel, including the `hpc-gpu-jobs` dash-leading
pattern's `--` guard, still works after the shared-helper refactor. `lint_skills()` (repo-wide:
only the known, accepted `prompt_signals` specificity over-warn on the nested-group word `day`,
documented as harmless, plus unrelated pre-existing info findings), `check_skill_links()` and
`check_skill_clashes(new = "staged-assistant-workflow")` (both clean, 30 skills), `skills-ref
validate staged-assistant-workflow` (valid), and `check_sync_setup()` against the real, live
settings.json content read via `bash`/`cat` (same R-session path-guard workaround as the other hook
audits) -- all `ok`/expected `info`/`warn` only (uncommitted tree, one unpushed commit; both
pre-existing, not from this change).

Not done: 5.2 (content-growth hook) is still not built, per the two-point calibration task tracked
separately below. Real-conversation-turn confirmation (only synthetic payloads tested this round,
same limitation the original R1/R2 scripts had before their own first live confirmation). The
phrase list's negative-example calibration (`references/testing-skills.md` discipline) is still
not done -- flagged as a known gap, not a blocker, since the cost of a miss is bounded to one
ignorable nudge or, on a second miss, one forced `Stop` turn (the same accepted-risk class as R1/R2).

### Two-point calibration for 5.2, same session

At the user's request, inspected `lm-messages.jsonl` size twice in this same session, anchored
against the user's own reported token count the second time:

| When | `lm-messages.jsonl` | Lines | User-reported tokens |
|---|---|---|---|
| Start of this round (before the build) | 276,251 bytes | 82 | not given |
| After the build, user reports ~120k tokens | 357,584 bytes | 99 | ~120,000 |

Ratio at the second point: ~2.98 bytes per reported token. Still only one token-anchored data point
-- not enough to fix a byte-based threshold with confidence (the ratio could shift with how much of
a session is prose vs. large tool outputs, which this very session's own mix of file reads and
edits is not necessarily representative of). Useful enough to sanity-check an eventual threshold
order of magnitude (e.g. a context limit quoted in the low hundreds of thousands of tokens would
correspond to roughly one to a few MB of `lm-messages.jsonl`), but 5.2 remains un-built pending more
data points, per this ledger's section 9.3 recommendation.

### Third data point, same session, after the build+verification work

| When | `lm-messages.jsonl` | Lines | `ui-messages.jsonl` | Lines |
|---|---|---|---|---|
| Start of this round | 276,251 bytes | 82 | 211,402 bytes | 6 |
| Mid-round (~120k tokens reported) | 357,584 bytes | 99 | 269,692 bytes | 10 |
| After building the 5.1 hook + verification | 667,354 bytes | 221 | 4,792,761 bytes | 34 |

Notable: `ui-messages.jsonl` grew far faster than `lm-messages.jsonl` between points 2 and 3 (roughly
18x vs. 1.9x) during a stretch of heavy tool use (many `read`/`edit`/`bash` calls while building and
testing the hook). This suggests `ui-messages.jsonl` batches larger per-entry payloads (plausibly
full diffs/tool-call renderings for the UI) and may be a noisier, spikier proxy than
`lm-messages.jsonl` for "how much is actually in the model's context" -- another reason to prefer
`lm-messages.jsonl` for a future 5.2 threshold, not yet settled with more than this one session's
data. Still only one session; no cross-session comparison has been done.

## 11. Log: 2026-10-28, RStudio's own size bands discovered; hand-off written

User reported RStudio's own UI labels conversation length qualitatively: 120k tokens = "medium",
and this session's current 196.2k tokens = "very large". This is a new, more useful calibration
anchor than guessing a byte threshold independently -- see
`research/HANDOFF-content-growth-hook.md` for the full write-up and next steps. Fourth data point
recorded: at 196.2k tokens, `lm-messages.jsonl` was 687,109 bytes (233 lines). Combined with the
~120k-token point from earlier this session (357,584 B), the average bytes/token ratio is
~3.0-3.5, but the *incremental* ratio between the two points (~4.33 bytes/token) is higher and
unexplained -- flagged in the hand-off as needing more, varied data points before trusting a
constant.

Work on 5.2 is paused here (user asked for a clean hand-off to start a fresh conversation, this
session having itself reached "very large"). `research/HANDOFF-content-growth-hook.md` is the
authoritative resume point, written to the same convention as
`research/HANDOFF-job-watch-refactor.md`.

## 12. Round 4 (2026-10-28, fresh conversation): hand-off step 1 resolved, step 2 in progress

Resuming per `research/HANDOFF-content-growth-hook.md`.

### 12.1 Step 1: no numeric band boundaries exist in the docs

Re-read `https://assistant.posit.co/docs/features/context-management/` in full, this time
looking specifically for numbers, not just the "UI-only" fact (already established in section 2).
Result: the page documents exactly one number anywhere on the topic --
`features.autoCompactTokenBuffer` (default **30,000 tokens**), the context-limit buffer reserved
for the auto-compaction summary, which triggers once fewer than that many tokens remain in the
window. The page has no mention of "small"/"medium"/"large"/"very large" labels, no percentage
bands, and no other threshold. **Conclusion: the labels the user sees in the Session HUD are not
documented anywhere reachable** -- they are a UI-only presentation detail with no published
numeric definition. Per the handoff's own fallback instruction, this round stops looking for more
bands and treats the two-point data (120k = "medium", 196.2k = "very large") as the only anchor,
stated explicitly rather than invented.

### 12.2 Step 2: a third data point gathered (this session, different composition)

Used the same DEBUG-capture protocol as section 9.2 (`touch
~/.posit/skill-triggers/state/DEBUG`, one `bash` call, inspect, delete the capture file and the
DEBUG marker afterward -- confirmed deleted). This session's `transcript_path` points at
`.../b7b36a33-fd83-422b-84dc-69db9a2afa06/conversation.json`; the sibling files at that point (20
lm-messages in, early in a read-the-ledger-and-one-webfetch-heavy round, not yet matched by a
user-reported token count):

| File | Size | Lines |
|---|---|---|
| `lm-messages.jsonl` | 79,543 B | 20 |
| `ui-messages.jsonl` | 56,299 B | 2 |
| `usage-events.jsonl` | 1,884 B | n/a |

Not yet anchored to a token count -- asked the user (same turn) to report what the status-bar
token counter/HUD currently shows, to get a third token-anchored ratio point from a
lighter-tool-use, more prose-heavy session than the one that produced the first two points (section
10/11). Note `ui-messages.jsonl`'s line count (2) looks implausibly low for ~20 lm-messages and
several tool calls so far -- worth a second look once more sessions are inspected, since section
10 already flagged `ui-messages.jsonl` as spikier/noisier; this may be another instance of that, or
a sign the two files batch differently early in a session than later.

### 12.3 Token-anchored point received; a composition-dependence finding supersedes the "treat as fixed" plan

User reported, same turn: **59.3k tokens, labelled "small"**. This is a third, differently-composed
token-anchored point (and, as a bonus, a third named band -- "small" -- not seen before):

| Session (composition) | Label | Tokens | `lm-messages.jsonl` | Bytes/token |
|---|---|---|---|---|
| This session (light tool use, mostly prose/reading) | "small" | 59,300 | ~79,543 B | ~1.34 |
| Prior session, mid-round | "medium" | 120,000 | 357,584 B | ~2.98 |
| Prior session, end of round (heavy tool use) | "very large" | 196,200 | 687,109 B | ~3.50 |

**This is the key finding of this round.** The bytes/token ratio is not a session-wide constant --
it varies by more than 2.5x across the three points (1.34 to 3.50), and the lowest ratio belongs to
the *lightest*-tool-use session. This confirms, with cross-session data rather than a single
session's internal non-linearity (section 11's unexplained ~4.33 incremental ratio), that a fixed
byte threshold is at best a rough, composition-dependent proxy for the token-based bands RStudio
itself displays -- not a reliable stand-in. A tool-output-heavy session will cross any given byte
threshold at a *lower* token count than a prose-heavy session will. Note also that `lm-messages.jsonl`
at this session's check point (20 lines) was captured slightly before the user's token report (a few
more tool calls happened in between), so the 1.34 ratio is an upper-bound estimate on the true
value at exactly 59.3k tokens, if anything making the true ratio even lower and the spread even
wider than stated.

Given this, the design below deliberately picks a conservative (low) byte threshold rather than
averaging the three ratios, so that even a tool-output-heavy session doesn't get nudged much later
than a prose-heavy one would -- erring toward an earlier, cheap, ignorable nudge rather than a
late, more costly miss (the only false-positive cost is one extra line of `additionalContext`, per
the "known open risks" carried over from the handoff).

### 12.4 Token-over-time CSVs and a fourth point: the ratio is not composition, it is a fixed offset

Sources: `context-inbox/token-usage-session-rows.csv` / `-totals.csv` (the previous conversation, 153
requests, 11:56-13:14 UTC; context per request = input + cache_read + cache_write) and this
session's `usage-events.jsonl` (only 10 `keepalive` rows; read via a copy in `tmp-examples/`, deleted).
User also reported this session at **~110k tokens** and that RStudio's **small -> medium switch is at
100k tokens** (first numeric band boundary; "large" boundary still unknown, "very large" <= 196k).
Same moment: `lm-messages.jsonl` = 341,634 B (144 lines).

Findings:
- **Fit:** tokens ~= 30.6k + bytes / 4.15 over the three well-anchored points (120k/357,584 B;
  196.2k/687,109 B; 110k/341,634 B); residuals <= 3.1k tokens (~3%). The fixed ~30k intercept is the
  system prompt, tool list, skills list and memory, which are in the context but not in
  `lm-messages.jsonl`. This **replaces the "bytes/token varies 1.3-3.5x by composition" reading of
  12.3**: the 59.3k "small" point was measured before the token report (file had grown since), so 1.34
  was a lower bound, not a composition effect. Keepalive rows corroborate the offset (41k tokens very
  early in this session, before much content existed).
- **Implied byte thresholds:** medium starts at ~288 KB, 120k at ~371 KB, 196k ("very large") at ~687 KB.
- **Compaction breaks the proxy.** The previous session's context peaked at 202,157 tokens (request 85)
  and fell to 63,492 by request 100 (compaction), while `lm-messages.jsonl` never shrinks (docs: compacted
  messages are kept in the tree, only hidden). After `/compact` the byte size overstates context; a
  size-based nudge is a false positive there. Mitigated only by nudge-once-per-session.
- `usage-events.jsonl` has no per-request rows for normal turns (keepalives only) and its
  `anchorMessageId` does not match `lm-messages.jsonl` ids, so it cannot be joined to byte offsets or
  used as a live token source. The CSVs come from the UI export, not from any hook-visible file.

Decision: keep `content_growth_threshold_bytes: "350000"` (~125k tokens, just past "medium" start and
well before "very large"), now justified by the fit rather than a guess. Caveats stay in the nudge
design: advisory wording, once per session, unreliable after compaction.

Verification done this round: `bash -n`; synthetic matrix (below threshold silent, above nudges,
second hit writes escalation marker, already-loaded skipped, missing file silent, marker shared with
prompt-signal channel, PostToolUse regression); `lint_skills()` (only pre-existing accepted warn/info),
`check_skill_links()`, `check_skill_clashes()`, `check_sync_setup(cfg=)` (hook already registered on
`UserPromptSubmit`; only expected info/warn: dirty tree, 3 unpushed). Not done: `skills-ref validate`
(command not found in this shell), a live-session test of the growth nudge, HANDOFF file removal,
HISTORY.md entry, commit.

### 12.5 Linking the growth nudge to compaction (considered 2026-10-28, not built)

Sources: https://assistant.posit.co/docs/features/hooks/ (re-read; status: read), plus a local grep of
this session's `conversation.json` / `lm-messages.jsonl` for any compaction marker (status: read).

Facts:
- **`PreCompact` is not fired** by Posit Assistant (hooks docs: Events table note and Compatibility list). There is
  no `PostCompact` event and `SessionStart.source` is only `startup`/`resume`, so no hook sees a compaction.
- **Auto-compaction does not fire `UserPromptSubmit`** (docs, "V1 scope"). Only prompts the user submits do; a typed
  slash command is stated to fire it, but the payload form of `/compact` is unverified (no live capture).
- `conversation.json` is a small turn-tree index and `lm-messages.jsonl` holds only text mentions of "compact"
  (17 hits, all prose) -- no structural compaction marker a hook could stat.

Decision: **do not build.** Value is real but bounded, cost is an untested payload guess:
- Manual `/compact` could be detected in the `UserPromptSubmit` payload and used to write a baseline marker
  (`$sid.compactbase` = current `lm-messages.jsonl` size), with `check_growth` comparing `size - baseline` to the
  threshold. That would remove the false positive only for manual compaction.
- Auto-compaction (the common case, triggered when fewer than ~30k tokens remain) stays invisible, so the
  false-positive class survives. The nudge fires at ~125k tokens, before auto-compaction would normally occur (limit
  minus 30k buffer), so it is usually already spent by then; nudge-once-per-session bounds the harm to one ignorable line.
- Alternative that needs no compaction signal: nothing; a hook cannot read live token counts (section 2, 12.4).

Open item: if the payload for a typed `/compact` is ever captured (DEBUG switch), the baseline-marker design above
is a ~10-line change in `check_growth`. Revisit if a `PreCompact`/`PostCompact` event is added to the host.

`research/HANDOFF-content-growth-hook.md` was removed 2026-10-28 once 5.2 was built; its content lives in sections
9-12 of this ledger (recover the file with `git show HEAD:research/HANDOFF-content-growth-hook.md`).
