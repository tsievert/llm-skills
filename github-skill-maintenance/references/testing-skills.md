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
- Testing hooks and scripts that clean directories (Windows)
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

- Package-manager tests (renv, uv, conda) go into disposable copies of source files only. Never copy, move, sync or delete
  recursively over folders that link into a shared cache (`renv/library`, `.venv`, junctions): a write through the link damages the
  shared cache for every project. Point caches at a scratch folder when a test must write into an environment (renv: `RENV_PATHS_CACHE`,
  uv: `UV_CACHE_DIR`).

## Testing hooks and scripts that clean directories (Windows)

When a bash test deletes or recreates a scratch directory (`rm -f "$dir"/*`), convert a Windows backslash
path first (`cygpath -u "$dir"`) or build it with forward slashes: a glob on a backslash path matches nothing
and `rm -f` stays silent, so stale state files from earlier cases make later cases pass or fail for the wrong
reason. List the state directory before each test case (one report, high confidence).

## Testing several neighbouring skills together (proxy test)

The manual protocol above assumes fresh conversations and one skill at a time. For a family of
skills with overlapping scope, a cheaper proxy is to write about 15 realistic queries with the
expected skill, then give subagents only the names and descriptions and ask which skill they
would load, three runs each (example: `assets/trigger-queries-clash-areas.json`). It tests
description wording only, not the real loader, not near-miss queries that should trigger
nothing, and not the skill bodies. Results so far are in `skill-boundaries.md` (open items).

## Common trigger-miss pattern: discovered mid-task, not stated in the request

Found 2026-10-24 from a real conversation log (`dlc-pig-method-paper`): the user asked for "an
optional orchestrator for the sow and piglet submission scripts... to submit jobs with different
training parameters". `hpc-job-scripts` and `deeplabcut-hpc` did not trigger, even though the
assistant then read the actual files (`GDK_DLC_piglet_train_submit.sh`, `GDK_DLC_sow_train_submit.sh`)
and would have seen `#SBATCH` lines and a DeepLabCut training call. The skills only loaded two turns
later, once the user explicitly wrote "HPC best practices and DLC API". Lesson, generalised from the
web sources behind this skill's advice (philschmid.de/agent-skills-tips; agensi.io; selftune.dev;
atlan.com, 2026): a `description` written only against the *vocabulary a skill author expects*
("Slurm", "sbatch", "DeepLabCut") misses requests phrased with *domain or project jargon* ("sow and
piglet submission scripts", "orchestrator for training runs") and, separately, the assistant does not
automatically re-check skill relevance after reading file content mid-task that makes the match
obvious — loading happens mainly off the initial message.

Two independent mitigations, both needed:

1. **Widen "Use when" with implicit/contextual phrasing**, not just the literal jargon: cover the
   *task* ("submit a batch/sweep of runs with different parameters", "retrain after fixing the
   data") in addition to the *tool* ("Slurm", "sbatch"). Do not add this user's own project-specific
   terms ("sow", "piglet") to a shared skill description — they do not generalise to other users; the
   fix is the task-level phrasing, not the brand name.
2. **Name the file-level signal explicitly in the description** for skills whose domain shows up in
   file content before it shows up in the user's words (`#SBATCH`/`sbatch`/`srun` for the HPC skills,
   `import deeplabcut`/`pytorch_config.yaml` for `deeplabcut-hpc`), so the description itself tells
   the assistant that reading such a file is a trigger, independent of the wording of the request.

When auditing a skill that seems to undertrigger, check both: does the description cover indirect/
contextual phrasing (per the checklist above), and does it tell the assistant that evidence found
*while working* (file contents, filenames, existing scripts) counts as a trigger just as much as the
user's own words?

**Plan mode does not appear to suppress this**, based on one live trial (2026-10-24): a plan file that
named `mixed-models-glmm` only as background guidance ("this is the kind of modeling choice this skill
documents conventions for"), not as an explicit "load skill X" step, still led the assistant to call the
`skill` tool unprompted during the post-approval implementation turn. Approval mode (Normal/Auto/YOLO) is
a separate, global setting unrelated to skill loading; nothing in the documented Plan-mode mechanics
suggests skill discovery is special-cased there. Treat this as one data point, not a guarantee — if a
real case of a plan-then-implement turn skipping an obviously relevant skill shows up, it is likely the
same undertrigger pattern above (description wording), not a Plan-mode-specific effect, so check the
description first.

## When to stop

Stop when the failures left are inconsistent rather than systematic, or when a change
no longer moves the validation rate. If a description cannot be made to trigger reliably,
the usual cause is that the skill covers too much or too little; split or merge it
rather than lengthening the description.
