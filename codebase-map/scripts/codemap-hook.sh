#!/usr/bin/env bash
# PostToolUse hook for the codebase-map skill. There is no file-watcher/timer hook event
# (checked assistant.posit.co/docs/features/hooks/), so "self-updating" is implemented the
# only way it can be: react to the assistant's own write/edit/bash calls, walk up from the
# tool's cwd to find the nearest *.Rproj (this skill's scope is RStudio projects only --
# see the user's own R5 decision in research/codebase-navigation-ledger.md), and
# regenerate .codemap/{INVENTORY.md,CODEMAP.md,DEPENDS.tsv} via build_codemap.R.
#
# Configure in ~/.posit/assistant/settings.json (or a project settings file) as:
#   "PostToolUse": [{"matcher": "write|edit|bash",
#                     "hooks": [{"type": "command", "command": "bash <path>/codemap-hook.sh"}]}]
#
# Two independent throttles (see references/triggering-and-updating.md):
#   - a 30s per-project build throttle, so a burst of edits doesn't rescan repeatedly;
#   - a once-per-session additionalContext nudge, only on the build that first creates
#     .codemap/ for a project (routine refreshes afterward are silent).
#
# Always exits 0 (fail open) -- a missing Rscript, a non-RStudio directory, or any error
# here must never block or visibly disrupt the assistant's own tool call.

STATE="${CODEMAP_STATE_DIR:-$HOME/.posit/codemap/state}"
mkdir -p "$STATE/throttle" "$STATE/notified" 2>/dev/null || exit 0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
[ -n "$SCRIPT_DIR" ] || exit 0
BUILD_R="$SCRIPT_DIR/build_codemap.R"
[ -f "$BUILD_R" ] || exit 0

payload=$(cat 2>/dev/null) || exit 0
jstr() { printf '%s' "$payload" | sed -n "s/.*\"$1\" *: *\"\([^\"]*\)\".*/\1/p" | head -n1; }

event=$(jstr hook_event_name)
[ "$event" = "PostToolUse" ] || exit 0
sid=$(jstr session_id)
[ -n "$sid" ] || exit 0
tool=$(jstr tool_name)
case "$tool" in write|edit|bash) ;; *) exit 0 ;; esac
cwd=$(jstr cwd)
[ -n "$cwd" ] && [ -d "$cwd" ] || exit 0

find_rproj_root() {
  local dir="$1" i=0
  while [ "$i" -lt 12 ]; do
    if ls "$dir"/*.Rproj >/dev/null 2>&1; then printf '%s' "$dir"; return 0; fi
    local parent
    parent="$(dirname "$dir")"
    [ "$parent" = "$dir" ] && return 1
    dir="$parent"
    i=$((i + 1))
  done
  return 1
}

root=$(find_rproj_root "$cwd") || exit 0
[ -f "$root/.codemapignore" ] && exit 0
command -v Rscript >/dev/null 2>&1 || exit 0

root_hash=$(printf '%s' "$root" | cksum | cut -d' ' -f1)
throttle_file="$STATE/throttle/$root_hash"
now=$(date +%s)
if [ -f "$throttle_file" ]; then
  last=$(cat "$throttle_file" 2>/dev/null || echo 0)
  case "$last" in ''|*[!0-9]*) last=0 ;; esac
  elapsed=$((now - last))
  [ "$elapsed" -ge 30 ] || exit 0
fi
echo "$now" > "$throttle_file" 2>/dev/null

output=$(Rscript "$BUILD_R" "$root" 2>/dev/null) || exit 0
first=$(printf '%s' "$output" | grep -o 'CODEMAP_FIRST_BUILD=1')

if [ -n "$first" ]; then
  notified_file="$STATE/notified/$sid.$root_hash"
  if [ ! -f "$notified_file" ]; then
    touch "$notified_file" 2>/dev/null
    msg="This RStudio project just crossed the codebase-map skill's size threshold: .codemap/INVENTORY.md (file list), .codemap/CODEMAP.md (greppable heading ledger) and .codemap/DEPENDS.tsv (dependency edges) were generated and are pointed to from this project's AGENTS.md/DATABOT.md. They refresh automatically; grep CODEMAP.md before reading a long file in full."
    esc=$(printf '%s' "$msg" | sed 's/\\/\\\\/g; s/"/\\"/g')
    printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
  fi
fi

# Housekeeping: drop throttle/notified markers older than 30 days.
find "$STATE/throttle" "$STATE/notified" -maxdepth 1 -type f -mtime +30 -delete 2>/dev/null
exit 0
