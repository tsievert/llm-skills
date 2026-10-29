# llm-skills

A collection of custom [Agent Skills](https://agentskills.io) for [Posit
Assistant](https://assistant.posit.co), mostly aimed at reproducible research
workflows in R and Python: statistics and modelling (GAMs, GLMMs), HPC/Slurm
job scripts, data deposits and citation files, Git hygiene, and a few
project-maintenance skills for the skills themselves.

These are personal, actively-evolving notes-as-skills rather than a
polished, versioned product — expect some skills to be more mature than
others (see the status table in [AGENTS.md](AGENTS.md)). They're public so
others can read, fork, or adapt them; issues and pull requests are welcome
but may not get fast turnaround.

## Layout

Each top-level folder is one skill:

```
<skill-name>/
  SKILL.md        # YAML frontmatter (name, description) + instructions
  scripts/        # optional: R/Python/shell helpers the skill can execute
  references/     # optional: longer documentation loaded on demand
  assets/         # optional: templates, example files
```

`scripts/sync-skills.sh` and the `scripts/*-hook.sh` files are maintenance
hooks for keeping a local clone in sync with this repo and for triggering
`codebase-map`/`skill-lessons` bookkeeping; they aren't skills themselves.

`AGENTS.md` is this repository's own project memory for Posit Assistant
(working rules, a status table of skills, and a pointer to `HISTORY.md`, a
longer dated development log). `research/` holds working notes gathered
while building a skill, kept separate from the skills themselves.

## Skills

| Skill | Purpose |
|---|---|
| [agents-md-maintenance](agents-md-maintenance) | Audits and trims bloated `AGENTS.md`/`CLAUDE.md`/`DATABOT.md` project-memory files |
| [animal-behaviour-tracking-analysis](animal-behaviour-tracking-analysis) | DeepLabCut pose output → behavioural metrics (distance, speed, immobility, ROI) and their statistics |
| [codebase-map](codebase-map) | Self-updating file inventory/dependency map for a large project |
| [data-repository-readme](data-repository-readme) | READMEs and data dictionaries for research data deposits (Dryad, Zenodo, Figshare, OSF) |
| [deeplabcut-hpc](deeplabcut-hpc) | DeepLabCut training/inference on HPC clusters and headless GPU machines |
| [gam-interpretation](gam-interpretation) | Plotting and reporting fitted GAMs (gratia, ggplot2) |
| [gam-mgcv](gam-mgcv) | Fitting and checking GAMs/GAMMs with mgcv |
| [git-for-research-projects](git-for-research-projects) | `.gitignore`/`.gitattributes`, secrets cleanup, Zenodo/CITATION.cff releases |
| [github-skill-maintenance](github-skill-maintenance) | Lints, tests and links the skills in this repo |
| [hpc-cluster-docs](hpc-cluster-docs) | Identifies a cluster's scheduler and looks up its docs before writing job scripts |
| [hpc-gpu-jobs](hpc-gpu-jobs) | GPU batch jobs on Slurm, including multi-GPU PyTorch launches |
| [hpc-job-scripts](hpc-job-scripts) | Writing, reviewing and debugging Slurm `sbatch` scripts |
| [hpc-python-code](hpc-python-code) | Python code patterns for HPC batch jobs (logging, checkpointing, parallelism) |
| [hpc-r-code](hpc-r-code) | R batch jobs on HPC: parallelism, RNG, renv, job arrays |
| [hpc-resource-allocation](hpc-resource-allocation) | Sizing CPU/memory/GPU/time requests; diagnosing OOM/TIMEOUT kills |
| [job-opportunity-watch](job-opportunity-watch) | Periodic check of job-portal links against a personal profile |
| [keypoint-moseq](keypoint-moseq) | keypoint-MoSeq behavioural syllables from DLC/SLEAP keypoints: fitting, known problems, species checks, syllable statistics |
| [manuscript-figures-ggplot](manuscript-figures-ggplot) | Journal-ready ggplot2 figures (colour-blind-safe, sized, exported) |
| [mixed-models-glmm](mixed-models-glmm) | Mixed models with glmmTMB/lme4, DHARMa diagnostics, emmeans contrasts |
| [openalex](openalex) | Literature search, citation counts and alerts via the OpenAlex API |
| [python-reproducible-pipeline](python-reproducible-pipeline) | uv + Snakemake pipelines, including HPC execution |
| [r-reproducible-pipeline](r-reproducible-pipeline) | targets + renv + Quarto pipelines, including HPC execution |
| [recipe-notes-formatter](recipe-notes-formatter) | Converts recipes into consistent Obsidian notes |
| [reproducible-research-data](reproducible-research-data) | Planning a FAIR data/code deposit for a paper |
| [skill-feedback-triage](skill-feedback-triage) | Triages lessons collected from real skill usage into fixes |
| [skill-lessons](skill-lessons) | Records anonymised lessons learned while using a skill |
| [social-research-search](social-research-search) | Searches Bluesky/Mastodon without API keys |
| [web-fetching-r](web-fetching-r) | Polite, rate-limited web fetching helpers in R |

## Using these skills

Posit Assistant discovers skills from a few default locations, and you can
point it at an arbitrary extra directory (such as a clone of this repo) via
`skills.paths` in `~/.posit/assistant/settings.json`. See the [Posit
Assistant configuration reference](https://assistant.posit.co/docs/reference/config-file/)
for the current syntax. This is the only setup required for the skills
themselves to load.

Each `SKILL.md` follows the [Agent Skills specification](https://agentskills.io):
YAML frontmatter with `name` and `description` (the description is what the
assistant matches against a user's request to decide whether to load the
skill), followed by instructions, with optional `scripts/`, `references/`
and `assets/` subdirectories for progressive disclosure.

## Hooks (optional)

A few scripts in [`scripts/`](scripts) hook into Posit Assistant's [hook
events](https://assistant.posit.co/docs/features/hooks/) for automation on
top of the skills above. None of these are required for the skills to work;
each one's own doc has the exact `settings.json` entry (paths are
machine-specific, so they aren't duplicated here).

| Hook | Event(s) | Purpose | Setup |
|---|---|---|---|
| `sync-skills.sh` | `SessionStart` | Fast-forwards this clone from `origin/main` at most once a day | this file's own header comment |
| `lessons-hook.sh` | `PostToolUse`, `Stop` | Logs skill usage and nudges the assistant to record lessons learned about a skill | [skill-lessons/references/hook-setup.md](skill-lessons/references/hook-setup.md) |
| `skill-trigger-hook.sh` | `UserPromptSubmit`, `PostToolUse`, `Stop` | Catches an explicit "use/trigger a skill" instruction that was never followed up | [github-skill-maintenance/references/skill-trigger-hook.md](github-skill-maintenance/references/skill-trigger-hook.md) |
| `skill-file-signal-hook.sh` | `PostToolUse` | Nudges toward a skill when file content strongly implies it, even with no explicit ask | [github-skill-maintenance/references/skill-trigger-hook.md](github-skill-maintenance/references/skill-trigger-hook.md) (same doc, "The file-signal hook" section) |
| `codebase-map/scripts/codemap-hook.sh` | `PostToolUse` | Regenerates a project's file inventory/dependency map after edits, once the project crosses a size threshold | [codebase-map/references/triggering-and-updating.md](codebase-map/references/triggering-and-updating.md) |

All hooks fail open (a script error or missing dependency never blocks a
session) and are additive in `settings.json` — adding one doesn't replace
another's entry for the same event.

## Caveats

These skills encode one person's working conventions and were developed
and tested primarily on Windows with RStudio, often against a single
project's data and a single HPC site's scheduler conventions. Facts that
are specific to one cluster, journal, or institution are flagged as such in
the skill text, but review any generated job script, statistical choice, or
file-handling command before relying on it — these are not a substitute for
reading the tool's own documentation.

## License

Code and text in this repository are released under the [MIT
license](LICENSE) unless noted otherwise in a specific file. See
[CITATION.cff](CITATION.cff) if you want to cite this repository.

## Contributing

Issues and pull requests are welcome. If you add or change a skill, please
follow the conventions in [AGENTS.md](AGENTS.md) (one folder per skill,
frontmatter `name` matching the folder name, a "Related skills" section,
etc.) and run the linter in
[github-skill-maintenance](github-skill-maintenance) before opening a PR.
