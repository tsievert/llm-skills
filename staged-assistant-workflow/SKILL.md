---
name: staged-assistant-workflow
description: Designs a long or complex multi-step assistant task as named stages, each a separate conversation or headless run with one input file and one output file, so no single conversation has to hold the whole task's context. Covers a stage table, a status function for "which stage is next and why", file-based hand-offs, completeness gates between stages, and resumable per-item batches. Use when a task's own length or complexity looks likely to exhaust one conversation's context before it's done — a multi-week build, a task with many similar sub-items, or (as one specific case) a job that also recurs on a schedule and needs assistant judgment each run. Not for a one-off task that comfortably fits one conversation. For an all-headless DAG with no assistant-judgment step use `r-reproducible-pipeline`/`python-reproducible-pipeline` instead. For one long but non-recurring stream, `agents-md-maintenance`'s hand-off note may be enough on its own. Close-out logging belongs to `skill-lessons`.
metadata:
  prompt_signals: '\b(huge|massive|very large|too (big|long))\b[^.?!\n]{0,40}\b(task|project|build|refactor)\b|\b(many|several|multiple)\b[^.?!\n]{0,30}\b(sessions|conversations)\b[^.?!\n]{0,20}\b(finish|complete|build)\b|\bwill take\b[^.?!\n]{0,30}\b(weeks|days|sessions)\b|\b(weekly|daily|recurring|periodic|every (week|day|month))\b'
---

# Staged assistant workflow

A pattern for a task whose own length or complexity is likely to exhaust one conversation's
context before it's finished — a multi-week build, a task with many similar sub-items to work
through, or any work stream where "just keep going in this conversation" would eventually mean
losing earlier context or needing `/compact`. Breaks the task into named stages, each with exactly
one file in and one file out, so a stage can run in its own conversation (or headless) without the
assistant needing to remember what earlier stages did — it rereads the input file instead.

A task that **also** recurs on a schedule (weekly digest, periodic re-check) and needs assistant
judgment at some stage is a specific, secondary case of the same problem: recurrence is just one
common *reason* a task's cumulative context would otherwise outgrow one session, not the thing this
skill is defined by. The mechanism (stage table, gates, status function) doesn't care why a task
needs staging, only that it does.

This generalises a real build (a weekly job-listing pipeline's staged refactor, October 2026)
and is being used for a second time before any part of it is proven
reusable. Treat specifics below as a starting point, not a fixed API — adapt names and gate logic
to the task at hand. If a workflow turns out *not* to need assistant judgment at any stage, switch
to `r-reproducible-pipeline` (`targets`) instead; it already has DAG caching, branching, and a
cluster back end that this pattern does not try to reinvent.

## When to reach for this vs. a plain pipeline

| Signal | Use |
|---|---|
| Every stage is deterministic code (fit a model, render a report) | `r-reproducible-pipeline` / `python-reproducible-pipeline` |
| At least one stage needs the assistant to read, judge, or write prose (classify items, draft a summary, decide a borderline case), and the task's own length risks outgrowing one conversation | this skill |
| The task also repeats on a schedule and needs assistant judgment each run | this skill — treat the schedule as the reason staging is needed, not a different problem |
| One long work stream, not recurring, just needs a restart point | `agents-md-maintenance`'s hand-off-note pattern (lighter weight, no stage table) |
| The assistant-judgment stage can be scripted later with an LLM API call (`ellmer`) instead of a conversation | still start here; swapping the stage's *implementation* doesn't change the stage table |

## Core pieces

1. **Stage table.** One row per stage: name, input file(s), output file(s), a done-check (does
   the output exist and pass its gate?). Keep it in one R object or a small data frame a status
   function can read — not prose scattered through the skill.
2. **File hand-offs, not conversation memory.** Each stage reads only its declared input file(s)
   and writes only its declared output file(s). A new conversation resuming stage N needs no
   context beyond "read file X, follow stage N's instructions, write file Y" — this is what lets
   the stage run in a fresh conversation or headless.
3. **A status function.** One function (e.g. `jw_status()` in the source project) that reports,
   for the current run: which stages are done, which is next, and why a stage is blocked (missing
   input, gate failure, pending items). This is the single thing a user or a new conversation
   checks first — never make them re-derive it by reading stage outputs by hand.
4. **Completeness gates, not just "no error".** Between stages, check that every expected item is
   accounted for exactly once (e.g. "every source in the roster produced exactly one row, with
   status in {ok, error, skipped}") rather than only checking the stage didn't throw. A stage that
   silently drops rows is a worse failure than one that errors loudly.
5. **Resumable per-item batches.** For a stage that processes many items (classify N postings,
   screen N candidates), write partial output per item or per small batch (not all-or-nothing), so
   a stage interrupted partway can resume from what's already written rather than restarting.
6. **One folder/store per run.** Namespace outputs by run (e.g. an ISO week folder) so re-running
   doesn't clobber the previous run's evidence and two runs can be diffed.
7. **Lessons close-out.** When a run finishes (or a stage hits something worth recording), follow
   `skill-lessons` to write a generic entry — this is a separate step from the stage table, not a
   stage of its own.

## Writing the stage table

Keep it small and explicit; a stage that can't state its one input file and one output file
usually needs to be split. A minimal shape:

```r
stages <- list(
  list(name = "s1_probe",   inputs = "roster.csv",     outputs = "s1_probe.parquet",
       gate = function(out) all(out$status %in% c("ok", "error", "skipped"))),
  list(name = "s2_classify", inputs = "s1_probe.parquet", outputs = "s2_classify.parquet",
       gate = function(out) !anyNA(out$decision))
  # ...
)
```

A status function walks this list in order, checking each stage's output file against its gate,
and reports the first stage that is missing, failed its gate, or (for an assistant-judgment stage)
not yet closed out.

## Assistant-judgment stages

A stage the assistant itself performs (not scripted code) still writes exactly one output file
when done — the stage isn't "finished" until that file exists and passes its gate. State this
explicitly in the stage's instructions so a resuming conversation can tell "not started" from
"in progress, partial batch written" from "done". If the stage involves reading many items
(screening, bulk classification), delegate the mechanical first pass to a subagent when doing it
inline would load a lot of one-off content (titles, snippets) that won't be needed again, and keep
the judgment calls that need the full task context in the main conversation.

## Explain the reasoning (teaching rule)

When using this skill, say briefly why a task got split the way it did (which stage is the
assistant-judgment one and why it can't be scripted yet), why a gate checks what it checks, and
flag the choice to add a stage or merge two as the user's to confirm — a stage boundary is a
design decision, not a mechanical default.

## Capture lessons (self-improvement rule)

If a step of this pattern breaks down in practice (a gate that didn't catch a real failure, a
status function that gave a misleading "next stage", a hand-off file that turned out to need more
than one input), record a generic, anonymised entry via `skill-lessons`. This skill has been used
once so far; entries here matter more than most for deciding whether the pattern generalises.
