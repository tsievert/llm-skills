# Chaining jobs with a short-lived submission-loop orchestrator

## Contents
- The pattern this covers
- Two failure modes and why `--dependency` alone does not catch them
- Submission-loop template
- Resuming from a specific step
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
