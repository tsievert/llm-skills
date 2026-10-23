# llm-skills

Repository of custom Posit Assistant skills, synced via GitHub
(https://github.com/tsievert/llm-skills, branch `main`).

## Layout

- One folder per skill at the repo root: `<skill-name>/SKILL.md`
  (YAML frontmatter with `name` and `description`; optional `scripts/`,
  `references/`, `assets/`). Follows the Agent Skills spec (https://agentskills.io).
- Folder name must match the `name` in the frontmatter.
- Use the `create-skill` skill when authoring a new skill.

## Working rules

- When writing or changing skill files (SKILL.md, frontmatter, scripts, references),
  always look up current references and guidance online first (Agent Skills spec at
  https://agentskills.io, Posit Assistant docs at https://assistant.posit.co/docs/,
  and best-practice sources) rather than relying on memory.
- The same applies to hooks and sync scripting: check the hooks docs
  (https://assistant.posit.co/docs/features/hooks/) before changing hook config.

## Auto-sync protocol (status: installed and tested in isolation; not yet verified in a live session)

Goal: skills are installed globally (all projects) and kept current with GitHub.

- Install location: `~/.posit/assistant/skills/<skill-name>/SKILL.md` (user level).
  Project-level skills (`.posit/assistant/skills/`) are NOT used for this.
- Mechanism: a `SessionStart` hook in `~/.posit/assistant/settings.json`
  (global file, so it runs regardless of workspace trust).
- Hook script (`~/.posit/hooks/sync-skills.sh`, to be written):
  1. Exit early if a timestamp file shows a check within the last 24 h.
  2. `git fetch origin main`; compare local `HEAD` with `origin/main` (commit hash).
  3. If different, `git pull --ff-only`, then copy/sync skill folders into
     `~/.posit/assistant/skills/` (or use a junction if the clone is placed there).
  4. Print one line to stdout (e.g. `Skills updated: abc123 -> def456`), which is
     added to the session context. Stay silent on no change or when offline.
- Hook settings: `timeout` ~20 s; fails open on error. On Windows shell-form
  commands run under `cmd.exe`, so call `bash <script>` (Git Bash) explicitly.
- Caveat: newly pulled skills may only be available from the next conversation;
  mid-session rescan is unverified.
- Existing user skill `openalex` lives in `~/.posit/assistant/skills/` and is not
  in this repo yet. Decide whether to move it in before syncing, so a sync never
  overwrites or deletes it.

## Implementation notes (from docs, 2026-10-23)

- Posit Assistant supports `skills.paths` in `~/.posit/assistant/settings.json`
  (https://assistant.posit.co/docs/reference/config-file/). This makes junctions/copies
  unnecessary: point `skills.paths` at this clone. Later paths win on name conflicts.
- Setting `skills.paths` REPLACES the defaults, so repeat them: `~/.agents/skills`,
  `~/.posit/assistant/skills`, `.agents/skills`, `.posit/assistant/skills`, plus this clone
  (`~/Sync_Home_Work/llm-skills`) last.
- Script: `scripts/sync-skills.sh` (versioned in this repo). Derives the repo dir from its
  own location, throttles via `~/.posit/state/llm-skills-last-check`, fails open.
- Hook entry (installed in global settings on 2026-10-23, together with `skills.paths`):
  `{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"bash C:/Users/thorb/Sync_Home_Work/llm-skills/scripts/sync-skills.sh","timeout":20}]}]}}`
- Docs say new skills are available "in your next conversation".

## Open decisions

- ~~Clone-in-place vs. copy~~ Resolved: use `skills.paths` (see implementation notes).
- After sync works, delete the old `~/.posit/assistant/skills/openalex` (repo copy replaces it).
- Whether sync should delete skills removed from the repo (default: no).
- Handling local uncommitted edits in the clone (default: skip pull and warn).

## Log

- 2026-10-23: Approach chosen (SessionStart hook + `git pull --ff-only`). Repo is
  currently empty of skills.
- 2026-10-23: `openalex` skill copied into the repo; first commit pushed to origin/main.
- 2026-10-23: `scripts/sync-skills.sh` written. Tested against a scratch bare repo with an
  isolated HOME: up to date, throttled, dirty tree (skip + warn), clean fast-forward, local
  ahead (skip + warn), offline (silent). All exit 0.
- 2026-10-23: SessionStart hook and `skills.paths` added to `~/.posit/assistant/settings.json`.
  TODO: in a new conversation, verify `/openalex` resolves and
  `~/.posit/state/llm-skills-last-check` is created; then delete the old
  `~/.posit/assistant/skills/openalex`.
