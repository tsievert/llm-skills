# Research: dedicated "toolchain orchestrator integrity" skill? (2026-10-24)

## 1. Question
User asked whether a new skill should check the integrity of a hand-rolled Python/Slurm
job-chain orchestrator (submits stage N+1 after stage N) plus best practices for it.

## 2. Sources checked
| Source | Status |
|---|---|
| `hpc-job-scripts/SKILL.md` (this repo) | read in full |
| `python-reproducible-pipeline/SKILL.md` (this repo) | read in full |
| web: unige.ch HPC community thread, francesco-oteri Medium "Mastering Slurm Job
  Submissions", groups.oist.jp "Advanced Slurm", Harvard FASRC docs, NeSI best-practice
  docs, vsoch Sherlock lessons | search snippets only |

## 3. Findings
- `hpc-job-scripts` already covers: directive ordering, `--time`/`--mem` mutual exclusion,
  `module purge`, job arrays vs loops, **chaining with `sbatch --parsable` +
  `--dependency=afterok` + `--kill-on-invalid-dep=yes`**, log directory creation, race
  conditions in arrays, node-local scratch sync, signal/requeue/checkpoint handling, and a
  static linter. Its description already explicitly covers "an orchestrator or wrapper that
  submits a batch, sweep, or range of ... runs" and existing-script detection via
  `#SBATCH`/`sbatch`/`srun` file signals.
- `python-reproducible-pipeline` already owns the "when does a hand-rolled chain outgrow
  itself" decision (its "Choose the tool" table: a few scripts in sequence -> a short driver;
  several dependent steps/samples, Slurm -> Snakemake) and the integrity properties a real
  toolchain needs (explicit input/output per step, params not raw config reads, one writer per
  output, logs+benchmarks, incremental rerun, `--locked` environments).
- Web sources (all generic Slurm docs, not research papers) independently converge on the same
  dependency-chaining pattern (`--dependency=afterok`/`afterany`, capture job ID via
  `--parsable`) already documented in `hpc-job-scripts`. One source's explicit conclusion:
  <cite index="2-13,2-14,2-15">"avoid unnecessary complexity... a simple loop or Bash script can achieve the same result more transparently... Focus on clarity, reproducibility, and adapting your workflow to your real computational needs."</cite>
  — i.e. graduate to a real workflow tool only when complexity warrants it, matching this
  repo's existing hand-off.
- Gap actually found (not yet covered in depth by either skill): a hand-rolled orchestrator's
  own *internal* integrity — verifying stage N's expected output files exist/are non-empty
  before submitting stage N+1 (beyond Slurm's own exit-code-based `afterok`), a persisted
  state/log of which stage last completed so a partial chain can resume idempotently, and
  cleanup of now-orphaned downstream `sbatch` calls after a stage fails outside Slurm's own
  dependency mechanism (e.g. a Python stage exits 0 but writes a truncated/invalid file).

## 4. Verdict
No new skill. The two gap items are a natural, bounded addition to `hpc-job-scripts`'s
existing "Chain stages with..." bullet (output-existence checks + a stage-state file next to
`--kill-on-invalid-dep=yes`), not a separate domain. A standalone skill here would overlap
both `hpc-job-scripts` (chaining mechanics) and `python-reproducible-pipeline` (the
integrity/reproducibility properties and the "when to graduate" decision) heavily enough to
violate the repo's "watch for skill clashes" rule, and would compete for the same trigger
phrases ("orchestrator", "toolchain", "chain of jobs").

## 5. Round 2 (2026-10-24): sharpening the gap

### 5.1 Sources
| Source | Status |
|---|---|
| cambiotraining.github.io HPC intro, "Job Dependencies" | search snippet |
| hpc.nih.gov "Building pipelines using slurm dependencies" | search snippet |
| wiki.incd.pt, hpc.hku.hk dependency pages | search snippet |
| GitHub `igreen1/pyantz` issues #13 and #50 (closed 2026-10-19, filed ~5 days before this
  research, i.e. a live, current bug tracker for an actual Slurm-pipeline-manager Python
  package) | read via search snippet |
| ResearchGate/arXiv items on bioinformatics-pipeline agent robustness and workflow-manager
  comparisons (Excelra Q&A, PMC Cluster Flow, bioRxiv JUDI) | search snippets, general
  framing only, not specific bugs |
| `github-skill-maintenance/references/skill-boundaries.md` | read in full (ownership map,
  confirms `hpc-job-scripts` owns "sbatch structure, arrays, logs, requeue") |

### 5.2 Key finding
`pyantz` (a dedicated Python/Slurm pipeline-manager library, not a toy) shipped two
integrity bugs in its Slurm runner, found and fixed in the same week as this research:
- **#13:** <cite index="9-1,9-2,9-3,9-4,9-5,9-6">the process exits with status 0 whether the job succeeded or failed... Since all SLURM dependencies are afterok, dependents of a failed job are treated as satisfied and run.</cite>
- **#50:** <cite index="10-1,10-2">when an afterok dependency fails, SLURM leaves dependents in PENDING with reason DependencyNeverSatisfied indefinitely, clogging the user's queue</cite> because `--kill-on-invalid-dep=yes` was missing.

This corroborates, with a concrete and current example, that the gap identified in round 1
is real and non-obvious enough that even a purpose-built tool got it wrong: `afterok`
protects against a failed *Slurm job*, not against a script that *catches its own error and
still exits 0*. The hpc.nih.gov doc independently shows a third variant of the same class:
its wrapper script around `sbatch` itself checks the submission output
(<cite index="11-2">sbr="$(/path/to/real/sbatch "$@")"; if [[ "$sbr" =~ Submitted\ batch\ job\ ([0-9]+) ]]</cite>)
specifically because a failed `sbatch` call can otherwise poison the job-ID capture used for
the next `--dependency`.
The bioinformatics-workflow-manager sources (Excelra Q&A, PMC Cluster Flow) independently
restate the same framing already in this repo's `python-reproducible-pipeline`: hand-rolled
bash chains are fine for small/one-off use and become fragile on retries, logging and
directory management as they grow — no new information there, just corroboration of the
existing hand-off.

### 5.3 Sharper verdict
Still **no new skill**. But the focus for extending `hpc-job-scripts` narrows from a vague
"orchestrator integrity" to three concrete, evidenced failure classes, all specific to
Slurm's `--dependency` mechanism and squarely inside `hpc-job-scripts`'s existing scope
(sbatch structure, chaining, requeue):
1. **Exit-code honesty at the script boundary.** The stage script (Python or otherwise)
   must `sys.exit(1)`/raise on failure; a caught exception, a swallowed subprocess return
   code, or a `sys.exit(0)` default will make `afterok` silently lie. This is a review
   checklist item (read the script's exit path), not new Slurm syntax.
2. **Submission-failure checking at the orchestrator boundary.** Capturing the job ID from
   `sbatch`'s stdout must check that submission actually succeeded (regex the
   `Submitted batch job <id>` line, or use `--parsable` and check the exit code of `sbatch`
   itself) before using that ID in `--dependency=afterok:<id>`; otherwise a rejected
   submission (bad partition, QOS, syntax) silently breaks or misdirects the next
   `--dependency`.
3. **`--kill-on-invalid-dep=yes` is already in `hpc-job-scripts`'s bullet list**, so item 3
   is confirmed as correct and sufficiently prominent, not a gap — the pyantz issue shows
   what happens without it (orphaned PENDING jobs) but the skill already states the fix.

Output-existence checks (round 1's second gap item) remain a reasonable defense-in-depth
addition but are secondary to items 1-2, which are the failure modes actually observed in a
real tool's bug tracker.

## 6. Open items
- Not yet written: the three-item `hpc-job-scripts` extension above. Pending user go-ahead.
- Not tested: any of the gap-item code on a real cluster; the `pyantz` bug reports were read
  as search snippets, not verified against the library's current source.
