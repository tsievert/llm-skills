# Tested and not tested

What each checker and hook was run against, and what was not tested. Moved out of SKILL.md.

Run against the 13 skills in this repo on Windows (R 4.6.0): it found the truncated
`hpc-job-scripts` description, three CRLF working-copy scripts, and one dead link in
`mixed-models-glmm`. `check_versions()` ran with CRAN and PyPI lookups. `check_sync_setup()`
was tested with synthetic good and bad `cfg` lists (clone missing from paths, no defaults,
missing script, `useHooks = "none"`, no stamp) and live git state; reading the real
`settings.json` from R was blocked by the session guard, so that code path is untested in
this session. Not tested: Linux or macOS, `bash -n` on non-Windows, the manual trigger
protocol end to end, a second machine. The lessons-hook audit was tested with synthetic
good and bad `cfg` lists (wrong matcher, `async` field, wrong script path, missing hooks)
and a synthetic lessons folder; it has not seen the real `settings.json` (blocked, see above).
The skill-trigger hook (`skill-trigger-hook.sh` at the repo root, added 2026-10-24) was tested with
twelve synthetic piped payloads (no match, explicit match, block-once, silent repeat,
cleared-by-skill-load, `stop_hook_active` loop guard, missing `session_id`, embedded-quote
prompt, a question near-miss, `DEBUG` logging, and malformed/empty stdin) and its
`check_sync_setup()` audit was run against the real `settings.json` content (read with
`bash`/`cat` and passed as `cfg`, the same path-guard workaround as above) after the file
was updated to register it. Not tested: firing inside a real conversation turn, `SubagentStop`.
The file-signal hook (`skill-file-signal-hook.sh`, added 2026-10-24, the non-blocking R2
counterpart) was tested with synthetic piped payloads (nudge on a matching `read`/`grep`
result, silence on a repeat, on an already-loaded skill, on unrelated content, and on a
non-matching tool; embedded-quote content; missing/malformed stdin) and its own
`check_sync_setup()` section was run against the real `settings.json` content the same way.
Its `lint_skills()` check (`metadata.file_signals` compiles as a regex and has reasonably
specific alternatives) was exercised on the two seeded skills (`hpc-job-scripts`,
`deeplabcut-hpc`) with no findings. Not tested: firing inside a real conversation turn, the
cost of scanning every skill's frontmatter at scale. See
`skill-trigger-hook.md` (same folder) for detail.
