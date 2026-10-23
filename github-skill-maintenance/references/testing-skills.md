# Testing a skill

Based on the Agent Skills guides "Evaluating skills" and "Optimizing descriptions"
(https://agentskills.io/skill-creation/evaluating-skills,
https://agentskills.io/skill-creation/optimizing-descriptions) and the best-practices
checklist. Those guides use Claude Code's CLI to automate runs; Posit Assistant has no
equivalent skill-trigger CLI, so the runs here are manual in fresh conversations.

## Contents

- Static checks (always)
- Does the description trigger? (manual)
- Does the skill improve the answer? (with/without comparison)
- Code in the skill
- When to stop

## Static checks (always, before every commit)

1. `lint_skills()` from `scripts/lint_skills.R`: spec limits, links, teaching section,
   HPC section, CRLF, shebang, `bash -n`, credential-like strings, truncated descriptions.
2. `uvx --from skills-ref agentskills validate <skill-dir>`: independent spec check
   (the project says it is a demonstration library; treat it as a second opinion, and
   note that it did not catch the YAML `#` truncation, which the linter does).
3. `check_versions()` from `scripts/check_versions.R` when the skill names package
   versions.

## Does the description trigger? (manual)

Only the `name` and `description` are loaded at startup, so the description decides
whether the skill is ever used.

1. Copy `assets/trigger-queries.template.json`, fill about 8-10 `should_trigger` and
   8-10 `should_not_trigger` queries. Make the should-not ones near misses that share
   keywords with the skill (for example a GAM question for `mixed-models-glmm`), not
   obviously unrelated prompts. Vary phrasing, formality, detail; include file names and
   casual wording.
2. Split about 60 % train and 40 % validation, mixed, fixed for all iterations.
3. For each query, open a new conversation, paste it, and note whether the assistant
   loaded the skill (the UI shows a skill-loading step). Posit Assistant also exposes
   `/skill-name` for explicit runs, but that bypasses the trigger and tests nothing here.
4. Because behaviour varies between runs, repeat each query up to 3 times and use the
   rate, not a single outcome. This is slow by hand; do the full protocol only for
   skills that seem to misfire, and a spot check of 3-4 queries otherwise.
5. Edit the description using the train failures only: broaden when it misses, add
   "not for ..." boundaries when it false-triggers. Do not paste failing queries'
   keywords in verbatim. Choose the iteration by validation pass rate.
6. Check the final description is at most 1024 characters, third person, "what + Use
   when ...", with no ` #` in an unquoted value.

## Does the skill improve the answer? (with/without comparison)

1. Write 2-3 realistic prompts per skill in `evals/evals.json` inside the skill folder
   (prompt, expected output description, optional input files). Add one edge case.
2. Run each prompt twice in fresh conversations: skill available, and skill absent
   (temporarily move the folder out of `skills.paths`, or compare against the previous
   commit). Save outputs side by side.
3. Write assertions after seeing the first outputs, objectively checkable ("fits a
   Gamma family and reports the link", "does not use BLUPs as data"). Drop assertions
   that pass in both runs; they measure nothing about the skill.
4. Review by hand. Record what the skill costs (extra reading, tokens, time) next to
   what it buys.
5. Fix the instructions, not the single test: generalise, keep the skill lean, move
   repeated helper code into `scripts/`.

## Code in the skill

- Run every script you ship at least once and record what was and was not tested in the
  skill (this repo's convention: a "tested / not tested" paragraph).
- Scripts must handle errors explicitly, justify constants, list their packages, and use
  forward slashes.
- Shell scripts: LF endings (`.gitattributes` enforces LF in the index, but a working
  copy written on Windows can still be CRLF), a shebang, `bash -n`.

## When to stop

Stop when the failures left are inconsistent rather than systematic, or when a change
no longer moves the validation rate. If a description cannot be made to trigger reliably,
the usual cause is that the skill covers too much or too little; split or merge it
rather than lengthening the description.
