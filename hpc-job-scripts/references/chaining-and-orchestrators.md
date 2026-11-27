# Chaining jobs with a short-lived submission-loop orchestrator

## Contents
- The pattern this covers
- Two failure modes and why `--dependency` alone does not catch them
- Submission-loop template
- Resuming from a specific step
- Judging whether a script is still used
- Evidence
- Testing

## The pattern this covers

A small script run once on the login node (not a daemon, not something that polls or
waits): it calls `sbatch` once per stage, in order, passing each stage's job ID as the
`--dependency` for the next, then exits immediately. Slurm's scheduler does all the actual
waiting. This is different from a workflow manager (`python-reproducible-pipeline`,
`r-reproducible-pipeline`) in that there is no DAG, no file-based rerun detection, and
usually a handful of stages known in advance; reach for a workflow manager once the number
of stages, their fan-out, or the need for automatic rerun-on-change outgrows a short script.

```bash
jid1=$(sbatch --parsable step1.sh)
jid2=$(sbatch --parsable --dependency=afterok:$jid1 step2.sh)
jid3=$(sbatch --parsable --dependency=afterok:$jid2 step3.sh)
```

## Two failure modes and why `--dependency` alone does not catch them

Both are about the orchestrator trusting something it should check, not about anything
Slurm does wrong. Both were found, independently, in a real Slurm pipeline-manager's issue
tracker the same week this was written (see Evidence below), so they are not hypothetical.

1. **A stage script exits 0 despite failing.** `afterok` relies entirely on the job's own
   exit code. A caught exception that is not re-raised, a subprocess call whose return code
   is never checked, or a script that falls through to a default `sys.exit(0)` all make the
   next stage start on a false premise. This is a property of the stage script, not the
   orchestrator: review each one for an explicit non-zero exit (or re-raised exception) on
   every failure path, including inside `try`/`except` and after calling external tools.
2. **`sbatch` itself fails to submit a stage.** This happens on the login node, inside the
   orchestrator's own loop (bad `--partition`/`--qos`, a typo in a directive, a down
   controller) — not a job failing later. A naive `jid=$(sbatch ...)` then holds an error
   message or an empty string, and the next `--dependency=afterok:$jid` is fed a bad
   dependency. Slurm usually rejects this outright, so the downstream stage silently never
   gets submitted (or runs with the dependency ignored); by the time anyone notices, the
   orchestrator that could have reported it has long since exited. Check each `sbatch`
   call's own exit status before trusting the ID it printed.

Related weaknesses seen when reviewing an existing orchestrator: classifying failures by substring search of
whole logs (a bare "oom" or "nan" matches unrelated words; have the Python step write a status file instead),
rewriting CRLF files in place by default (make it an explicit opt-in), extracting script references with a regex
that only sees one variable pattern, and relying on `afterok` alone so a step that exits 0 without producing
output releases downstream steps (add a marker-file check job).

## Gate jobs, exit codes and testing an orchestrator

- **Gate job.** Make the next step depend (`afterok`) on a small check job that verifies the step's output or status file. Each step script deletes its own stale status file at start, so an old "ok" cannot pass.
- **Exit codes.** `python ... | tee log` (even with `set +e`) hides the exit code, so `afterok` releases the next step after a failure. Call python directly; Slurm already captures stdout in the job log.
- **Empty `squeue` proves nothing.** After a chain was submitted, ask the user to run `sacct -j <all chained ids, comma list> --format=JobID,JobName,State,ExitCode` (array task rows included) before concluding anything; one failed array task makes `afterok` cancel everything downstream.
- **`--dry-run` skips every filesystem side effect** (no `mkdir -p`, no file writes, especially on absolute cluster paths when testing on a workstation). A `submit()` helper called inside command substitution prints the job id only; everything else goes to stderr.
- **Back up in the same block as the edit** (`cp -n file file.bak && sed ...`), and ask for an `ls` of the backups before any step that overwrites results; a backup in a separate block is skipped or its output never pasted.
- **Two-stage test.** First run the orchestrator against a fake `sbatch` script that prints job IDs and records its arguments (catches defects before any cluster time). Then run `sbatch --test-only` for every step on the cluster (it validates arrays, `--chdir`, `--account`, dependencies and `--export`, and prints start estimates per partition), then one real one-step submission.
- **Step markers and resume.** Hash into each step's done-marker only the config variables that step reads; hashing the whole config reruns finished steps (for example PCA) after any unrelated edit.
- **Passthrough.** Give the orchestrator an `EXTRA_SBATCH_ARGS` passthrough (for example `--exclude=<node>`) so a suspect node can be avoided without editing the script.
- **Tests pin their inputs.** Tests must set every config value they assert on after copying the config, never rely on the live config's values.
- **Shell pitfalls the fake-sbatch test exposed:** a job-ID counter lost inside a `$(...)` subshell, `[[ ... ]] && cmd` as the last command under `set -e` (exits when the test is false), empty array expansion under `set -u`, and test inputs created in the wrong folder.
- **`eval "$(tool ...)"` hides failure:** a failing tool leaves an empty string and `eval ""` returns 0, so the job continues with unset variables. Assign first (`out="$(tool ...)" || exit 1`), then `eval "$out"`.
- **Values read by the orchestrator must reach the jobs.** An orchestrator that sources a generated limits file into its own shell does not change what batch step scripts see (they source only the main config). Re-source the file in the step library when its path is set, or export the values, and test that the job sees them, not only the `sbatch` command line.
- **Quote paths in `eval` test expectations** (project paths often contain spaces; an unquoted script directory failed with "No such file or directory").
- **Multi-line text through `sed`/`awk` from Windows.** A `\n` in a replacement was inserted as a literal backslash-n and `bash -n` still passed. Insert multi-line text with the edit tool, strip CRLF, then run `bash -n` and grep for the intended lines.
- **Interactive blocks are self-contained.** Do not give the user a block that sources a batch helper library in their login shell: a helper that ends with `exit` closes the SSH session, and variables defined in a config the block did not source are empty. Activate the environment explicitly in interactive diagnostics.
- **Unique batch ids.** Name per-submission files (tables, manifests) that array tasks read with a token unique to the submit (stage, arm and `$$`), not a timestamp to the second: back-to-back submits overwrote each other and both arrays ran the second arm. Submit variants as separate commands, and when a submitted attempt has no result row, check which table its tasks read.
- **Copy first.** After copying scripts to the cluster, compare file counts and byte sizes with the local folder (`ls | wc -l`, `wc -c`) and run `grep -lU $'\r'` before the first `--test-only`; a partial copy shows up as "script missing" in a preflight.

`--kill-on-invalid-dep=yes` (already in the main chaining bullet) is a different, narrower
fix: it stops a dependent job from waiting forever once Slurm itself has marked a
dependency as unsatisfiable. It does not help with either case above, because in case 1
Slurm sees a satisfied (`afterok`) dependency, and in case 2 the bad ID may never become a
valid, trackable dependency at all.

## Submission-loop template

```bash
#!/bin/bash
set -euo pipefail

submit() {
  # "$@": the sbatch arguments for one stage. Prints the job ID on success.
  local out status
  if ! out="$(sbatch "$@" 2>&1)"; then
    echo "ERROR: sbatch failed for: $*" >&2
    echo "$out" >&2
    exit 1
  fi
  if [[ "$out" =~ Submitted\ batch\ job\ ([0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo "ERROR: unexpected sbatch output: $out" >&2
    exit 1
  fi
}

jid1=$(submit --parsable step1.sh)
jid2=$(submit --parsable --dependency=afterok:"$jid1" --kill-on-invalid-dep=yes step2.sh)
jid3=$(submit --parsable --dependency=afterok:"$jid2" --kill-on-invalid-dep=yes step3.sh)
echo "submitted chain: $jid1 -> $jid2 -> $jid3"
```

`submit()` checks two things `--parsable` alone does not: that the `sbatch` command
exited 0, and that its stdout actually matched the expected "job ID" shape (`--parsable`
output is just the bare ID on success, so a regex on plain `sbatch` output or a check on
`--parsable`'s own exit status both work; the template shows the plain-output regex because
it also captures cases where `--parsable` itself was rejected before producing any ID).
`set -euo pipefail` alone is not enough here: `jid=$(sbatch ...)` always "succeeds" as a
shell assignment even when `sbatch`'s own exit status is nonzero, unless that status is
checked explicitly (as `submit()` does).

## Keep the script to the next run

Reported twice (one project): a sweep orchestrator that kept every past round of candidates and long evidence comments became bloated. Hold only what the script submits now; archive old versions outside it, and keep a list of used IDs for the duplicate guard so finished or failed IDs are never reused.

## Passing values that contain commas

`sbatch --export=ALL,KEY=VAL,...` splits on commas, so a value such as `"3,snapshot-250"` is truncated silently (found by code review in a sweep orchestrator, not by a failed job). Pass such values through the environment instead: `env KEY="3,snapshot-250" sbatch --export=ALL job.sh` (verified locally that the whole value arrives; not run on a real scheduler), or read them from a small env file in the job script.

## Resuming from a specific step

Since the orchestrator is short-lived and not tracking state itself, "resume from step N"
is simplest as a start index the user supplies after inspecting `sacct`/`squeue` themselves
(the orchestrator should not guess which step failed):

```bash
start="${1:-1}"
[[ $start -le 1 ]] && jid1=$(submit --parsable step1.sh)
[[ $start -le 2 ]] && jid2=$(submit --parsable ${jid1:+--dependency=afterok:"$jid1" --kill-on-invalid-dep=yes} step2.sh)
[[ $start -le 3 ]] && jid3=$(submit --parsable ${jid2:+--dependency=afterok:"$jid2" --kill-on-invalid-dep=yes} step3.sh)
```

When starting mid-chain, the earlier stage's real output must already exist on disk; the
orchestrator has no job ID to depend on for a stage it did not submit, so it submits the
resumed stage without a dependency. Do not assume the earlier stage's output is complete or
valid just because the user wants to resume: have the resumed stage itself validate its own
inputs on startup rather than trusting the choice of start index.

## Judging whether a script is still used

A reference grep (for example for `PY_SCRIPT=` defaults) misses scripts launched through computed paths and cannot judge an optional branch. Combine it with a functional comparison against the step that supersedes the file, and state the grep limits.

## Evidence

`igreen1/pyantz`, a Python/Slurm pipeline-manager package, had both of these filed as bugs
in the same week this reference was written (closed 2026-10-19):

- Issue #13: a failed job's process exited 0, so its `afterok` dependents ran anyway.
- Issue #50: a failed `afterok` dependency left dependents PENDING forever because
  `--kill-on-invalid-dep=yes` was missing (the narrower, already-documented fix above).

Read as search snippets only (not the library's source); cited here as evidence that these
are real, non-obvious failure modes, not a hypothesis to also carry into user-facing advice
about `pyantz` itself.

## Testing

Tested locally with a stub `sbatch` (no real cluster): a `submit()` call against a stub that
prints `Submitted batch job 123` and exits 0 returns `123`; against a stub that exits 1
prints the error and the script exits before building the next `--dependency`; against a
stub that exits 0 but prints unexpected text (simulating a wrapped `sbatch` or a cluster
banner message) is also caught and stops the chain rather than feeding garbage into
`--dependency`. Not tested: a real `sbatch`, interaction with `--kill-on-invalid-dep` on an
actual scheduler, the resume-from-step snippet against a live partially-run chain.
