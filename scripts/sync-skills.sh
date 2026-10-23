#!/usr/bin/env bash
# SessionStart hook: fast-forward this clone from origin/main at most once per 24 h.
# stdout becomes session context, so print only when something noteworthy happens.
# Always exits 0 (fail open): a sync problem must never block a session.

BRANCH="main"
MAX_AGE_SECONDS=$((24 * 60 * 60))
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${HOME}/.posit/state"
STAMP="${STATE_DIR}/llm-skills-last-check"

# Never prompt for credentials; fail instead of hanging the session.
export GIT_TERMINAL_PROMPT=0
git_() { git -C "$REPO_DIR" "$@"; }

# Drain the hook JSON payload on stdin (not needed).
cat >/dev/null 2>&1 || true

mkdir -p "$STATE_DIR" 2>/dev/null || exit 0

# Throttle: skip if checked recently.
if [ -f "$STAMP" ]; then
  now=$(date +%s)
  last=$(stat -c %Y "$STAMP" 2>/dev/null || echo 0)
  [ $((now - last)) -lt "$MAX_AGE_SECONDS" ] && exit 0
fi

# Only operate on the expected branch of a repo that has commits.
[ "$(git_ rev-parse --abbrev-ref HEAD 2>/dev/null)" = "$BRANCH" ] || exit 0
before=$(git_ rev-parse --short HEAD 2>/dev/null) || exit 0

# Offline or remote error: stay silent and retry next session (stamp not touched).
timeout 15 git -C "$REPO_DIR" fetch --quiet origin "$BRANCH" 2>/dev/null || exit 0
remote=$(git_ rev-parse --short "origin/$BRANCH" 2>/dev/null) || exit 0

if [ "$before" = "$remote" ]; then
  touch "$STAMP"
  exit 0
fi

# Remote differs. Pull only if local is strictly behind (fast-forward possible).
if ! git_ merge-base --is-ancestor HEAD "origin/$BRANCH" 2>/dev/null; then
  touch "$STAMP"
  echo "llm-skills: local $BRANCH has commits not on origin (or diverged); skipped pull. Push or reconcile."
  exit 0
fi

if [ -n "$(git_ status --porcelain --untracked-files=no 2>/dev/null)" ]; then
  touch "$STAMP"
  echo "llm-skills: origin has updates ($before -> $remote) but the working copy has uncommitted changes; skipped pull."
  exit 0
fi

if git_ merge --ff-only --quiet "origin/$BRANCH" >/dev/null 2>&1; then
  touch "$STAMP"
  echo "llm-skills: skills updated $before -> $remote. New or changed skills may only apply from the next conversation."
fi
exit 0
