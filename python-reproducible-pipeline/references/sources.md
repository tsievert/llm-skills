# Sources

- [Documentation read](#documentation-read) | [Versions seen](#versions-seen) | [Papers](#papers) | [Look here for changes](#look-here-for-changes) | [Not read](#not-read)

Looked up on 2026-10-23. Full notes with quotes of what each page did and did not say are in
the repository research ledger (`research/pipeline-resources-ledger.md`, not part of the skill).

## Documentation read

| Topic | URL |
|---|---|
| Snakemake home, deployment, reporting, rules (partly), CLI, profiles | https://snakemake.readthedocs.io/en/stable/ |
| Slurm executor plugin | https://snakemake.github.io/snakemake-plugin-catalog/plugins/executor/slurm.html |
| uv project layout, sync, scripts | https://docs.astral.sh/uv/concepts/projects/layout/ , .../sync/ , https://docs.astral.sh/uv/guides/scripts/ |
| pixi | https://pixi.sh/latest/ |
| DVC pipelines | https://dvc.org/doc/start/data-pipelines/data-pipelines |
| pytask, comparison page | https://pytask-dev.readthedocs.io/en/stable/ |
| Prefect intro, task runners, prefect-dask | https://docs.prefect.io/v3/get-started |
| Dagster overview, installation, run executors | https://docs.dagster.io/ |
| Nextflow overview, install, cache and resume | https://www.nextflow.io/docs/latest/overview.html |
| Agent Skills specification | https://agentskills.io/specification |

## Versions seen

PyPI JSON API, 2026-10-23: snakemake 9.27.1, snakemake-executor-plugin-slurm 2.8.0,
snakemake-storage-plugin-fs 1.1.3, snakedeploy 0.17.1, snakefmt 2.1.0, dvc 3.67.1,
prefect 3.9.0, dagster 1.13.26, pytask 0.6.0. Installed locally: uv 0.12.5 (PyPI listed a newer
number). The PyPI packages named `pixi` and `reticulate` are unrelated to the tools of those names.

## Papers

Found with OpenAlex (authors, venues and DOIs verified via the API; abstracts not read):

- Köster J, Rahmann S (2012) Snakemake: a scalable bioinformatics workflow engine. Bioinformatics. https://doi.org/10.1093/bioinformatics/bts480 (W2110417468)
- Mölder F et al. (2021) Sustainable data analysis with Snakemake. F1000Research. https://doi.org/10.12688/f1000research.29032.2 (W3122109253)
- Di Tommaso P et al. (2017) Nextflow enables reproducible computational workflows. Nature Biotechnology. https://doi.org/10.1038/nbt.3820 (W2605897695)
- Sandve GK, Nekrutenko A, Taylor J et al. (2013) Ten simple rules for reproducible computational research. PLoS Comput Biol. https://doi.org/10.1371/journal.pcbi.1003285 (W2036318837)
- Wilson G et al. (2017) Good enough practices in scientific computing. PLoS Comput Biol. https://doi.org/10.1371/journal.pcbi.1005510 (W2963508088)

## Look here for changes

Snakemake changelog and the Slurm plugin page (flag names, resource keys); uv release notes
(`--locked`, `exclude-newer`); the Snakemake workflow catalog and `snakemake-workflow-template`
for layout conventions; the pixi plugin if Snakemake 10 is released.

## Not read

Remaining part of the Snakemake rules page (after 90k characters), Snakemake linting and
testing pages, Kedro, Hamilton, Luigi, doit documentation, the Snakemake workflow template
repository, `snakemake --containerize` in practice.
