# Rework: restructuring instead of patching

Contents: when to use it, gate, steps, what to record, verification.

A `rework` is an outcome for a target (section, reference file, script or mechanism) whose design is the
problem: repeated small patches, a recurring issue after a text fix, contradictions, or a topic with three
or more bullets that overlap. It is its own change (own commit), never mixed with routine fixes. Triggers
are in [triage-method.md](triage-method.md) ("Target scan"). Record the entries as `fix` in the dispositions
ledger.

## Why it needs a gate

Appending is cheap; deleting is risky because the reason a rule exists is often gone. A rewrite that drops
rules silently brings old failures back, and a rewrite without a standing prune habit regrows. The gate
therefore makes the rule list and the rationale explicit before anything is deleted.

## Steps

1. **Read the whole target** and its history (`git log -p -- <file>`, prior triage ledgers, `HISTORY.md`).
2. **Rule inventory.** List every rule, caveat and example in the target as a numbered table: rule, why it
   exists (entry, ledger row or commit if known, else "unknown"), keep / merge / move / drop.
   "Unknown" rationale means keep or move to a reference, not drop, unless the rule is clearly wrong.
   For a script, also list non-function top-level objects (regex vectors, column lists) and stateful
   objects (environments, options) separately, since a split can break load order or duplicate state.
   Count name references with lookarounds (`(?<![A-Za-z0-9_.])name(?![A-Za-z0-9_.])`, `perl = TRUE`), not
   `\b`: a word boundary never matches before a dot, so dot-prefixed helpers look unused.
   Save an original copy for before/after comparison with `bash` into the git-ignored `tmp-examples/`;
   the R session cannot read or write the system scratch directory.
3. **Name the underlying design problem** (one sentence) and the new shape (headings, decision table,
   checklist, script, lint check). Prefer the higher rungs of the fix ladder in `triage-method.md`.
4. **Net size does not grow** for a SKILL.md; detail moves to `references/`, never into more SKILL.md lines.
5. **Show the user** the inventory table and the new shape before editing; a rework is approved as a whole,
   in the triage table or by `AskUser`.
6. **Write the new text** without provenance. Put the rule inventory and rationale in the ledger under
   `research/`, not in the skill.

Cover the whole skill, not only the file that triggered it: run `usage_churn_files(skill)` (`scripts/churn.R`) and
list every `candidate` file in the inventory as keep, rework now or defer with a reason.

## Verify

Append one row per reworked file or folder to `rework-log.tsv` (date, commit, target) right after the rework commit
(the hash does not exist before it), as a follow-up commit, so the churn ranking stops listing the skill until it
is edited again.

`lint_skills()`, `uvx --from skills-ref agentskills validate <dir>`, `check_skill_links()` if related-skills
sections changed, re-run any reproducible original failure and any changed script. Compare the new text
against the inventory: every `keep` and `merge` rule is still findable. State what was not tested.
Per the standing rule, do not call it ready while errors remain.

## Limits

At most one or two reworks per triage run; choose by churn and recurrence, and let the user decide. A rework
is more research and more tokens than a patch, which is the point: it replaces several future patches.

Net-size check for step 4: record `file.size("<skill>/SKILL.md")` before the first edit and compare after the last
(an added pointer line is enough to break the rule).
