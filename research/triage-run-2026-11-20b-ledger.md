# Triage run 2026-11-20 (eleventh): ledger

Inbox: 30 new entries (5 use-case, 6 worked-well), 25 parked from earlier runs, 169 closed. Entry numbers are `L$n` of this run.

## Research rows

| Issue | Entries | Reproduction | Upstream | CRAN | OpenAlex | Skill text read | Result |
|---|---|---|---|---|---|---|---|
| 1 kpms float32 NaN from AR iteration 1; float64 alone fixes it; x64 before `load_config`, in every step | 112, 113, 116, 147, 151, 97 (parked), 110, 111 | not possible (needs GPU and a large real dataset) | kpms FAQ and release notes through 0.8.7 read 2026-11-20 (earlier today): silent on precision; absence is weak evidence | n/a | n/a (software behaviour) | `hpc-and-troubleshooting.md` row "NaNs during fitting" says "do not treat float32 as the cause"; `SKILL.md` rule 10 | unverified, source: reporting sessions (two sessions, one project); supports add-note in a reference, not SKILL.md |
| 2 CRLF re-added by the edit tool | 114, 149, 223 | n/a | n/a | n/a | n/a | `hpc-python-code/SKILL.md` l.90 and `github-skill-maintenance/SKILL.md` l.110 already say run `file` after every edit | already-present |
| 3 sed/awk `\n` in replacement text became literal | 119 (120 already covered) | not run locally (GNU sed in Git Bash normally expands `\n`, so cause is likely the tool-call layer) | n/a | n/a | n/a | `hpc-python-code` l.90 covers Python heredocs only, not sed/awk | unverified; add-note in a reference |
| 4 subprocess `text=True` decode error on Windows | 121 | not run | Python docs: `encoding`/`errors` params of `subprocess.run` | n/a | n/a | no mention in `hpc-python-code` | add-note |
| 5 unquoted paths with spaces in eval test expectations | 122 | not run | n/a | n/a | n/a | `chaining-and-orchestrators.md` has no quoting note | add-note |
| 6 capacity benchmark: dense ladder per round, bundle-then-single ablation, peak memory is not headroom, `peak_bytes_in_use` | 123, 124, 148, 117, 79 (parked) | not possible (cluster) | n/a | n/a | n/a | `capacity-benchmark.md` read in full: has descending ladder and bisection, nothing on these | add-note, merged into existing bullets |
| 7 orchestrator-read limits file not seen by jobs | 150 | not run | n/a | n/a | n/a | `capacity-benchmark.md` "Feed the result back"; `chaining-and-orchestrators.md` silent | add-note |
| 8 lint: heading or list marker mid-line | 220 | cheap regex test on repo pending | n/a | n/a | n/a | `lint_skills()` has no such check | fix if zero false positives, else park |
| 9 triage skill: leftover variant folders, keep-list form, docs absence not proof | 218, 219, 221, 222 | n/a | n/a | n/a | n/a | `work-copy.md` covers variant folders; step 7 builds the keep list from `L$status`; 221 resolved in the session itself | 218, 219, 221 already-present; 222 add-note |

## Not re-researched

Parked entries other than 79 and 97 (23 remain): `parked_recheck` flagged 13 as likely stale, but grep of the distinctive terms of 168, 162, 161, 144, 71 and 205 found no covering text, so they stay parked.

## Log

- 2026-11-20: ledger written before the table was shown.
