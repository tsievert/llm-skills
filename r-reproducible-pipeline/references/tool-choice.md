# targets or something else?

Contents: comparison; reasons to prefer each; tools not recommended here.

| Tool | Unit of work | Rerun logic | Slurm route | Fit |
|---|---|---|---|---|
| targets | R function returning an R object or file | content hashes of code, dependencies, files | crew.cluster (maturing); older clustermq / future | mostly-R analysis, one report, per-sample branching |
| Snakemake | rule with input and output files, script in any language | mtime, code, params, input, software env triggers | Slurm executor plugin 2.8.0 | Python-centred, mixed languages, file pipelines |
| Nextflow | process in any language | task hash, cached work directories | built-in SLURM executor | reuse of nf-core pipelines; needs Java; Windows only via WSL |
| pytask | Python function | hashes | none verified | laptop-scale Python |
| Prefect, Dagster | Python flows or assets | platform | no HPC route found in their docs | not recommended for this use |

Prefer targets when the steps pass R objects (model fits, data frames), the report should
rebuild from results, and the user thinks in functions. Prefer Snakemake when steps are
scripts in several languages, files are the natural interface, or the user already runs it.
Both can call the other's language: targets calls Python through `uv run` (tested in the
template); Snakemake runs R scripts through `script:` (see `python-reproducible-pipeline`).

Differences worth explaining: targets ignores mtime-only changes and comment edits and stops
downstream reruns when an output hash is unchanged; Snakemake reruns a rule after any edit to
its script, including comments, and does not track a config value unless it reaches the rule
through `params:` or an input file. Neither was tested on a shared filesystem with clock skew.

`drake` is superseded by targets (the manual says so). `workflowr`, `orderly`, `rix` (Nix) and
`rrtools` (GitHub only) were looked at as metadata only and are not part of this skill.
