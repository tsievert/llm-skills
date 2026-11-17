# Tested and not tested

Moved out of SKILL.md. The hook test list lives in the "Tested and not tested" section of
[hooks-reference.md](hooks-reference.md); this file is only the summary.

- `lint_skills()`: run against the repo's skills on Windows (R 4.6.0); found a truncated description, CRLF
  working-copy scripts and a dead link in earlier rounds. `check_versions()` ran with CRAN and PyPI lookups.
- `check_sync_setup()`: tested with synthetic good and bad `cfg` lists (clone missing from paths, no defaults, missing
  script, `useHooks = "none"`, wrong matcher, `async` field, no stamp), live git state, and the real
  `settings.json` content read with bash and passed as `cfg` (the R session cannot read that path directly).
- Skill-trigger hook (R1, 2026-10-24) and file-signal hook (R2, 2026-10-24): tested with synthetic piped payloads;
  one real turn confirmed the R1 `Stop` handler (2026-10-26).
- Not tested: Linux or macOS, `bash -n` on non-Windows, a second machine, `SubagentStop`, the hooks firing across real
  turns beyond the one confirmation, the cost of scanning every skill's frontmatter at scale, and the manual trigger
  protocol end to end.

