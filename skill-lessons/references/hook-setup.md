# Hook setup for the lessons loop

Contents: what the hooks do, settings entry, files, tuning, test recipe, known limits.

## What the hooks do

Script: `scripts/lessons-hook.sh` at the repo root (next to `sync-skills.sh`). One script
handles two events, chosen from the `hook_event_name` in the JSON payload on stdin.

| Event | Matcher | Action |
|---|---|---|
| `PostToolUse` | `skill` | Appends `timestamp, session, project folder, skill` to `~/.posit/lessons/usage.tsv`, only for skills that exist in this repo. Loading `skill-lessons` marks the session as captured. |
| `PostToolUse` | optional `executeCode\|executeR\|bash` | Counts error-like tool responses (a pattern in `ERR_PATTERN`), only in sessions that already loaded a repo skill. Stores a count, never text. Costs about 0.5 s per call on Windows (Git Bash start-up), so it is off by default. |
| `Stop` | none | If a repo skill was used and no entry exists yet, once per session, when an error was counted or `LESSONS_TURN_LIMIT` (pilot default 2) Stop events have passed, appends a row to `reminders.tsv` and returns `{"decision":"block","reason":...}`. The reason asks the assistant to load `skill-lessons` and write to a named inbox path: always a `use-case` summary, plus lesson entries if any. |

`Stop` ignores `matcher`. `stop_hook_active: true` always exits quietly so a block can
never loop. All paths exit 0 (fail open). `SessionEnd` is not used: it cannot inject
anything and has a 5 s budget.

## Settings entry

Global `~/.posit/assistant/settings.json` (hooks are additive, the sync hook stays):

```json
"PostToolUse": [{"matcher": "skill", "hooks": [{"type": "command",
  "command": "bash C:/Users/<you>/Sync_Home_Work/llm-skills/scripts/lessons-hook.sh", "timeout": 10}]}],
"Stop": [{"hooks": [{"type": "command",
  "command": "bash C:/Users/<you>/Sync_Home_Work/llm-skills/scripts/lessons-hook.sh", "timeout": 10}]}]
```

Unsupported handler fields (`if`, `async`, `shell`) make Posit Assistant skip the handler
with a warning, so keep entries to `type`, `command`, `timeout`.

## Files (all under `~/.posit/lessons/`)

| Path | Content |
|---|---|
| `inbox/<project>_<YYYYMMDD-HHMMSS>_<session8>.md` | lesson entries |
| `usage.tsv` | skill load log, tab-separated, no header |
| `reminders.tsv` | one row per Stop reminder issued (time, session, project, skills, errors, turns); compare with inbox files to see whether reminders were followed |
| `state/<session>.{errors,turns,reminded,captured}` | per-session counters and flags, deleted after 30 days |
| `state/DEBUG` | create this empty file to dump raw hook payloads to `state/debug-payloads.jsonl` (may hold private content; delete afterwards) |

## Tuning

- `LESSONS_TURN_LIMIT` (pilot default 2; raise once capture is shown to work): Stop events (after the first repo-skill load) before a reminder
  without an error. Lower is more reminders, higher misses more user corrections.
- `LESSONS_DIR`, `LLM_SKILLS_DIR`: override the data and repo locations (used for tests).
- Add the tool matcher to `PostToolUse` only if the turn limit proves too blunt.

## Test recipe (no real session needed)

Pipe synthetic payloads into the script with `LESSONS_DIR` pointing at a scratch folder:
a Stop before any skill is silent; a non-repo skill is not logged; a repo skill is logged;
a Stop after a counted error returns valid JSON once and then stays silent; the turn limit
triggers on the sixth Stop; `stop_hook_active: true` is silent; Windows paths in `cwd` become
a clean project name. Check the JSON with `jq`.

## Known limits

- The reminder is a heuristic. It cannot see user corrections; the turn limit is the
  stand-in. The transcript file format is undocumented, so the script does not parse it.
- Whether the assistant follows the reminder is up to the model; measure it from
  `usage.tsv` against the number of inbox files.
- The assistant's R session cannot write outside the project; the `write` tool can
  (this may prompt for permission in some workspaces).
