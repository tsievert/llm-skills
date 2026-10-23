# Sync, hooks and skills.paths: documented facts

Checked against the Posit Assistant docs on 2026-10-23. Re-read the pages before
changing hook or path config; they may have moved on.

- Hooks: https://assistant.posit.co/docs/features/hooks/
- Config file: https://assistant.posit.co/docs/reference/config-file/
- Skills: https://assistant.posit.co/docs/features/skills/
- Agent Skills spec: https://agentskills.io/specification

## Contents

- Skill discovery
- SessionStart hook behaviour
- How this repo's setup maps onto the facts
- Things that can go wrong, and the audit that catches them

## Skill discovery

- Default search folders, in order, later wins on a name clash: `~/.agents/skills`,
  `~/.posit/assistant/skills`, `.agents/skills`, `.posit/assistant/skills` (the last two
  relative to each workspace root).
- `skills.paths` replaces the defaults, so the defaults must be repeated. A project-level
  `skills.paths` replaces the global one completely (no merge).
- `~` expands to the user profile inside Posit Assistant. R on Windows expands `~` to
  `Documents`, so R code must build the home directory from `USERPROFILE`.
- New skills are available "in your next conversation".
- Frontmatter: spec fields (`name`, `description`, `license`, `compatibility`, `metadata`,
  experimental `allowed-tools`) plus Posit extras `argument-hint`, `user-invocable`,
  `disable-model-invocation`.
- Built-in skills are overridden by user and project skills of the same name. A repo skill
  that reuses a built-in name (for example `report`) silently replaces it.

## SessionStart hook behaviour

- Fires when a conversation is activated: opened, or reopened after eviction from memory.
  `source` is `startup` or `resume`. It can fire many times a day, so the script must
  throttle (this repo's script does: 24 h stamp file).
- Cannot block. Exit 0: plain stdout text becomes additional context (10,000 characters
  per hook). Any other exit code: a warning is logged and the session proceeds (fail open).
- `timeout` is in seconds; default 600 s for events other than `UserPromptSubmit`. Keep it
  short for network work.
- Shell-form commands run under the system shell, `cmd.exe` on Windows. Hence
  `bash <path>.sh` with an explicit `bash`. Handler fields `if`, `async`, `shell` make the
  handler get skipped with a warning.
- Global and project hooks are additive; a project cannot disable a global hook.
- Project hooks need a trusted workspace; global-file hooks always run. `useHooks`
  (`all` / `global` / `none`) and the environment variable `PA_DISABLE_HOOKS=1` switch
  hooks off. `POSIT_ASSISTANT_SETTINGS_ENFORCED` rejects a `hooks` key.
- Hook payload on stdin includes `session_id`, `cwd`, `hook_event_name`. The workspace
  root is also in `PA_PROJECT_DIR`. `CLAUDE_PROJECT_DIR` is not set.

## How this repo's setup maps onto the facts

| Piece | Where | Why it is built this way |
| --- | --- | --- |
| Clone as a skill folder | `skills.paths` last entry | Later paths win; no copies or junctions to keep in sync |
| Defaults repeated | `skills.paths` | Setting the key replaces the defaults |
| `bash <script>` | hook `command` | Shell form runs under `cmd.exe` on Windows |
| `timeout` 20 | hook | A slow or offline fetch must not delay a session |
| 24 h stamp | `~/.posit/state/llm-skills-last-check` | SessionStart fires on every conversation activation |
| `git merge --ff-only`, skip when dirty or ahead | `scripts/sync-skills.sh` | Never overwrite local edits or create merge commits |
| Always `exit 0`, silent when offline | `scripts/sync-skills.sh` | Fail open; stdout becomes context, so print only news |

## Things that can go wrong, and the audit that catches them

`scripts/check_sync_setup.R` covers each of these (read-only):

- settings key missing, wrong, or the clone not last in `skills.paths`
- same skill name in two search folders (a stale copy shadows the repo copy)
- hook script moved, CRLF line endings in the `.sh`, or no `bash` prefix on Windows
- stamp file stale for over a week (hook not running, always offline, or hooks disabled)
- local branch not `main`, uncommitted tracked changes, or local ahead of `origin/main`
  (all of which make the hook skip the pull and print a one-line note)

The same script also audits the lessons hooks (`scripts/lessons-hook.sh`, see the
`skill-lessons` skill). Documented facts it relies on: `PostToolUse` matches on the tool
name (`skill`), `Stop` ignores `matcher`, a Stop hook can block with
`{"decision":"block","reason":...}` and must honour `stop_hook_active` or it can loop,
handlers with `if`/`async`/`shell` are skipped with a warning, hooks run sequentially and
additively, and a matcher that also matches code or shell tools costs one Git Bash start-up
(about 0.5 s on Windows) per call. Checks: both entries present, matcher covers `skill`,
only `type`/`command`/`timeout`, `bash` prefix, timeout at most 30 s, script exists, LF
endings, `bash -n`, exits 0, `stop_hook_active` guard, one shared script. It also reads
`~/.posit/lessons` (usage rows and last time, inbox and processed counts, sessions
reminded vs entries written) and falls back to shell commands when the R session may not
read that folder.

Not covered by any script: whether the model follows the Stop reminder (compare reminded
sessions with inbox files over time), whether a pulled skill is picked up mid-session (docs say next
conversation) and behaviour on a second machine. Test the second machine by running
`check_sync_setup(fetch = TRUE)` there after the first session.

Safety note for edits to the hook script: it runs with the user's privileges at every
conversation start, so keep it free of network calls other than `git fetch origin main`
and never make it execute code from the pulled files.
