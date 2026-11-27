# Lessons triage 2026-11-27 research ledger

Generic wording only (public repo). Created 2026-11-27. Entry numbers are valid for this run only; entries are identified by skill and title.

## Section index

1. Requirements
2. Round 2026-11-27: one row per issue (research checklist)
3. Reproductions and sources
4. Open research items
5. Log

## 1. Requirements

| # | Requirement | Date |
|---|---|---|
| R1 | Approved table: fix 1-7, 9, 11, 13; add-note 3, 8, 10, 14; needs-info 12, 15; park 16; reject 17; rework of `skill-feedback-triage` and `github-skill-maintenance` deferred | 2026-11-27 |
| R2 | Write this ledger before any skill edit | 2026-11-27 |
| R3 | Evidence is entries only unless a row says a check was run; fixes go to references or scripts, not SKILL.md, where the patch gate said rework-or-defer | 2026-11-27 |

## 2. Round 2026-11-27: issue rows

| # | Issue | Reproduction | Upstream / docs | CRAN | Skill text read | Outcome |
|---|---|---|---|---|---|---|
| 1 | Edit tool and sed turn LF files into CRLF; lint eol message weak | done: 41 tracked files have a CRLF working copy now although `.gitattributes` sets `eol=lf`; lint lists at most 5 names | n/a | n/a | `lint_skills.R`, pitfalls, hpc-python-code | fix (enforcement: `fix_eol()` helper and fuller lint message) |
| 2 | OpenAlex `req_url_query` and quoted wildcards | done 2026-11-27 (section 3) | OpenAlex API error text | n/a | `query-refinement.md`, `r-workflow.md` | fix: correct two existing claims (both were already written 2026-11-26 after the entries) |
| 3 | Alert audit recipe; weak source for grey literature | recipe already present (`query-refinement.md`, 2026-11-26) | n/a | n/a | read | 308 already-present; 188 add-note |
| 4 | `check_skill_links` row, backticked cross-skill paths, clash grep | not re-run (entries state fixes made); 321 row format read in script | n/a | n/a | script and pitfalls read | fix: pitfall plus clash step |
| 5 | No evals template | n/a | agentskills.io evals convention not re-fetched | n/a | `testing-skills.md` read | fix: template asset |
| 6 | Triage process gaps | n/a | n/a | n/a | `SKILL.md`, `rework.md`, `triage-method.md` read | fix (references only) |
| 7 | kpms tie-break and ensemble size | n/a | docs and paper: 20 restarts, EML ranking; no tie-break rule in the docs (section 3) | n/a | ensemble size 20 already in workflow reference | fix: tie-break text; ensemble size stated in SKILL.md step 4 (entry 128 was a failed text placement, not absent) |
| 8 | Chunk margin on memory-driving quantity | not possible (cluster, cause unproven) | n/a | n/a | `capacity-benchmark.md` read | add-note, hedged |
| 9 | sacct after empty squeue, dry-run side effects, backup in same block | not possible (cluster); dry-run point is generic shell logic | n/a | n/a | `chaining-and-orchestrators.md` read | fix |
| 10 | Convention stated as fact | n/a | n/a | n/a | n/a | add-note |
| 11 | DLC snapshot selection, skeleton pre-flight, short names | not possible (cluster install); claims are the reporter's observations on one install | DLC docs not fetched | n/a | `pitfall-details.md` read | fix with "verify on the installed version" wording |
| 12 | Merge single/multi-animal H5, auto_track | not possible | n/a | n/a | n/a | needs-info |
| 13 | Ragged nested JSON, schema inventory, print n= | done (section 3) | n/a | `jsonlite` and `tidyr::unnest_wider` exist (not tested here) | `import-and-messy-inputs.md` read | fix |
| 14 | Windows symlink and runpy in local tests | done: `os.symlink` needs privilege on Windows (WinError 1314 reported) | n/a | n/a | `hpc-python-code/SKILL.md` read | add-note |
| 15 | nvidia-smi `-f` buffering | not possible (no GPU) | n/a | n/a | n/a | needs-info |

## 3. Reproductions and sources

All run 2026-11-27 against `https://api.openalex.org/works` with `httr2` and an API key set.

| Test | Result |
|---|---|
| `req_url_query(filter = "...search:bank vole OR small rodent")` (spaces) | URL encodes spaces as `%20`; 34386 hits; same as hand-built `+` URL |
| `req_url_query(filter = "...search:bank+vole+OR+small+rodent")` (already `+`) | `+` becomes `%2B`; 200 with 462 hits, not zero: a wrong, silently different query |
| `I()` wrapper around the `+` string | URL keeps `+`; 34386 hits |
| `title_and_abstract.search.exact:"bank vole*"` (wildcard in quotes) | 200, 2933 hits (literal phrase gives 1935): works, so the existing "returns HTTP 400" claim is wrong |
| `title_and_abstract.search.exact:"small rodent*"` | 200 |
| `title_and_abstract.search:"bank vole*"` (non-exact field) | 400 with a clear message: wildcards need the exact field |

Facts for issue 7 (kpms): docs (keypoint-moseq.readthedocs.io, Advanced, "Model selection and comparison") fit 20 restarts and select the highest EML; the paper reports 20 seeds. Neither states a tie-break rule, so the tie-break is a researcher choice to fix in advance, not an upstream method.

Issue 13: ragged-record failure is generic `as.data.frame` behaviour on list elements of unequal length; recipe is a NULL-to-NA helper per field (to be tested before writing, see log).

Skipped sources: none beyond the above.

## 4. Open research items

- Issue 8: the 80%-of-pool peak figure has no source; not made a rule.
- Issues 11, 12, 15: need output from the cluster install.
- `uvx --from skills-ref agentskills validate` for each edited skill (user shell).

## 5. Log

- 2026-11-27: ledger written before edits; triage table approved.
