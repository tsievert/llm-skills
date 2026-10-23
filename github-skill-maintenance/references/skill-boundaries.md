# Skill boundaries (who owns what)

Read this before writing or changing a skill description, and when `check_skill_clashes()` flags a pair.
Written 2026-10-23 after the first clash audit of 22 skills. Update the table when a skill is added.

## Contents

- Why clashes matter
- Ownership map by cluster
- Rules for writing a description
- Procedure for a new or changed skill
- What the 2026-10-23 audit changed
- Open items

## Why clashes matter

The assistant picks a skill from the YAML `description` alone. When two descriptions claim the same request
("make this re-runnable", "my job was killed", "plot this GAM"), either both load (context cost, conflicting
advice) or the wrong one loads. Duplicated advice inside bodies is the second risk: two copies drift apart
(for example gratia function names, which change between releases).

## Ownership map by cluster

| Cluster | Skill | Owns (trigger territory) | Hands off to |
|---|---|---|---|
| GAMs | `gam-mgcv` | fitting, smooths, k, families, diagnostics, `bam` | `gam-interpretation` (plot, interpret, report), `mixed-models-glmm` (no smooth terms) |
| GAMs | `gam-interpretation` | plotting, inference on smooths, wording | `gam-mgcv` (model fit), `manuscript-figures-ggplot` (journal export) |
| Models | `mixed-models-glmm` | LMM/GLMM, families, ICC, contrasts | `gam-mgcv` (smooth effects) |
| Figures | `manuscript-figures-ggplot` | final figure size, fonts, palettes, export | `gam-interpretation` (GAM plots first) |
| Pipelines | `r-reproducible-pipeline` | targets, renv, Quarto, crew.cluster | `python-reproducible-pipeline` (Python-centred), `hpc-r-code` (plain Rscript job) |
| Pipelines | `python-reproducible-pipeline` | uv, Snakemake, Slurm executor | `r-reproducible-pipeline` (R-centred), `hpc-python-code` (code in one job) |
| HPC | `hpc-cluster-docs` | identify cluster and docs (runs first) | all other `hpc-*` |
| HPC | `hpc-job-scripts` | sbatch structure, arrays, logs, requeue | `hpc-resource-allocation` (kills by memory or time), `hpc-python-code` (code inside) |
| HPC | `hpc-resource-allocation` | sizing from `sacct`, OUT_OF_MEMORY, TIMEOUT, pending | `hpc-gpu-jobs` (launch syntax), `hpc-job-scripts` |
| HPC | `hpc-gpu-jobs` | GPU directives, torchrun, ratios, monitoring | `hpc-resource-allocation` (sizing from measurements) |
| HPC | `hpc-python-code` / `hpc-r-code` | code inside a job, per language | pipeline skills for multi-step workflows |
| DLC | `deeplabcut-hpc` | training and video analysis | `animal-behaviour-tracking-analysis` |
| DLC | `animal-behaviour-tracking-analysis` | metrics, kpms, statistics on tracked output | `deeplabcut-hpc` (the network itself) |
| Deposit | `data-repository-readme` | README, data dictionary | `git-for-research-projects` |
| Deposit | `git-for-research-projects` | gitignore, secrets, tags, CITATION, manifest | `data-repository-readme` |
| Literature | `openalex`, `social-research-search`, `job-opportunity-watch` | scholarly search; social posts; job portals | none needed (different objects) |
| Meta | `github-skill-maintenance`, `skill-lessons`, `skill-feedback-triage` | repo upkeep; write lessons; read lessons | each other (stated in descriptions) |

## Rules for writing a description

1. State the object and the verbs it owns ("fits and checks", not "fits, checks, interprets and plots" if
   another skill owns interpreting).
2. If a neighbouring skill owns something a user might ask in the same breath, name it in the description
   with a hand-off sentence: "For X use other-skill." Both skills should name each other.
3. Do not list another skill's packages or functions as trigger words (for example `glmmTMB` in a GAM skill).
4. Words that describe a failure state ("slow", "killed", "out of memory") go to exactly one skill. Split
   by cause: start-up and logging problems to the script skill, memory and time kills to the sizing skill.
5. Keep the description under about 950 characters; hand-off sentences come last so the "Use when" part
   stays prominent.
6. Do not copy another skill's API advice into a body. Point to it instead, so there is one place to update.

## Procedure for a new or changed skill

1. Run `check_skill_clashes(new = "<skill>")` and read every pair it lists plus the two descriptions.
2. For each pair decide: reword (narrow one description), add a hand-off sentence, merge, or record
   `accepted` with a reason in `clash-decisions.tsv`.
3. Add the skill to the table above, then run `lint_skills()` and `check_skill_links()`.
4. Trigger behaviour is only testable with real queries (see `testing-skills.md`); the score is a screen,
   not proof.

## What the 2026-10-23 audit changed

- `gam-mgcv` no longer claims interpreting, plotting, prediction tooling or glmmTMB; its Interpretation
  section lost the gratia function list (kept only in `gam-interpretation`, which checks the gratia version).
- Pipeline skills dropped "so the user can choose" (both claimed the tool decision) and name each other.
- `hpc-r-code` no longer claims "an R pipeline" or "out of memory"; `hpc-gpu-jobs` no longer claims
  "how many GPUs/CPUs/memory"; `hpc-job-scripts` no longer claims "was killed".
- Hand-off sentences added for the DLC pair, the deposit pair and `manuscript-figures-ggplot`.
- Scores before: pipelines 0.52, GAMs 0.24, `hpc-python-code`/`hpc-r-code` 0.23 (accepted twins).

## Open items

- Body-level duplication was only checked for the GAM pair. `animal-behaviour-tracking-analysis/references/statistical-analysis.md`
  and `mixed-models-glmm` share GLMM templates (both derive from one tested script); decide later whether one
  should link instead of copy.
- The two `tool-choice.md` files in the pipeline skills overlap by design (each gives its side of the same decision).
- Planned `reproducible-research-data` would sit between `data-repository-readme`, `git-for-research-projects` and
  the pipeline skills; define its territory against this table before writing it.
- Trigger test 2026-10-23 (proxy): 15 realistic queries in `assets/trigger-queries-clash-areas.json`, three subagent runs with
  shuffled order that saw only names and descriptions (22 skills plus 9 built-in ones). The expected skill was chosen in 45 of 45
  selections and no wrong skill replaced it. Side effects: `hpc-cluster-docs` was co-loaded in nearly every HPC query (by design,
  it is the "use first" gate; the cost is one extra load), and the DLC training query added `hpc-gpu-jobs` in 2 of 3 runs. The
  mixed R/Python "rerun with one command" query loaded both pipeline skills every time, which is the intended behaviour (the user
  must choose). Limits: a subagent reading descriptions is not the real loader, queries were written by the same person who wrote
  the descriptions, and there were no should-not-trigger near misses. Real conversations are still untested.
