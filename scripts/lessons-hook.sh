#!/usr/bin/env bash
# Hook for the lessons-learned loop (see the skill-lessons and skill-feedback-triage skills).
# Handles two events, configured in ~/.posit/assistant/settings.json:
#   PostToolUse (matcher "skill|executeCode|executeR|bash")
#     - tool "skill": log which of THIS repo's skills was loaded (deterministic usage log).
#     - other tools: count tool responses that look like errors, but only in sessions
#       that already loaded one of this repo's skills. Only a count is stored, never text.
#   Stop
#     - at most ONCE per session, ask the assistant to record lessons if a repo skill was
#       used and (an error was seen OR many turns have passed) and no lesson was written yet.
# Always exits 0 (fail open). Output on stdout is JSON only when it blocks a Stop.
# Local state only: ~/.posit/lessons/{usage.tsv,state/,inbox/}. Nothing leaves the machine.
#
# Debug: `touch ~/.posit/lessons/state/DEBUG` appends raw payloads to state/debug-payloads.jsonl
# (may contain private content; delete the file afterwards).

LESSONS_DIR="${LESSONS_DIR:-$HOME/.posit/lessons}"
INBOX="$LESSONS_DIR/inbox"
STATE="$LESSONS_DIR/state"
USAGE="$LESSONS_DIR/usage.tsv"
REPO_DIR="${LLM_SKILLS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TURN_LIMIT="${LESSONS_TURN_LIMIT:-6}"   # Stop events after the first skill load
ERR_PATTERN='Error( in|:)|Traceback|Execution halted|could not find function|there is no package|ModuleNotFoundError|command not found|No such file or directory|unused argument|object .* not found'

payload=$(cat 2>/dev/null) || exit 0
mkdir -p "$INBOX" "$STATE" 2>/dev/null || exit 0

jstr() { printf '%s' "$payload" | sed -n "s/.*\"$1\" *: *\"\([^\"]*\)\".*/\1/p" | head -n1; }

event=$(jstr hook_event_name)
sid=$(jstr session_id)
[ -n "$sid" ] || exit 0
sid8=${sid:0:8}
cwd=$(jstr cwd | sed 's#\\\\#/#g; s#\\#/#g')
project=$(printf '%s' "$(basename "${cwd:-unknown}")" | tr -c 'A-Za-z0-9._-' '_')

[ -f "$STATE/DEBUG" ] && printf '%s\n' "$payload" >> "$STATE/debug-payloads.jsonl"

session_skills() { [ -f "$USAGE" ] && awk -F'\t' -v s="$sid" '$2 == s {print $4}' "$USAGE" | sort -u; }
count_lines() { [ -f "$1" ] && echo $(( $(wc -l < "$1") )) || echo 0; }

case "$event" in
  PostToolUse)
    tool=$(jstr tool_name)
    if [ "$tool" = "skill" ]; then
      name=$(jstr skill)
      [ -n "$name" ] && [ -f "$REPO_DIR/$name/SKILL.md" ] || exit 0
      printf '%s\t%s\t%s\t%s\n' "$(date +%Y-%m-%dT%H:%M:%S)" "$sid" "$project" "$name" >> "$USAGE"
      # Loading the capture skill means lessons are being written: no reminder needed.
      [ "$name" = "skill-lessons" ] && touch "$STATE/$sid.captured"
      # Housekeeping: drop per-session state older than 30 days.
      find "$STATE" -maxdepth 1 -type f -name '*.*' -mtime +30 -delete 2>/dev/null
    else
      [ -n "$(session_skills)" ] || exit 0
      response=${payload#*\"tool_response\"}
      if printf '%s' "$response" | grep -qE "$ERR_PATTERN"; then
        date +%s >> "$STATE/$sid.errors"
      fi
    fi
    ;;
  Stop)
    case "$payload" in *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;; esac
    skills=$(session_skills | paste -sd, -)
    [ -n "$skills" ] || exit 0
    date +%s >> "$STATE/$sid.turns"
    [ -f "$STATE/$sid.reminded" ] && exit 0
    [ -f "$STATE/$sid.captured" ] && exit 0
    ls "$INBOX"/*_"$sid8".md >/dev/null 2>&1 && exit 0
    errs=$(count_lines "$STATE/$sid.errors")
    turns=$(count_lines "$STATE/$sid.turns")
    if [ "$errs" -ge 1 ] || [ "$turns" -ge "$TURN_LIMIT" ]; then
      touch "$STATE/$sid.reminded"
      file="$INBOX/${project}_$(date +%Y%m%d-%H%M%S)_${sid8}.md"
      # JSON-safe path: forward slashes only (a Windows path would need escaped backslashes).
      file=$(cygpath -m "$file" 2>/dev/null || printf '%s' "$file")
      file=${file//\\//}
      reason="Lessons check (automatic hook; skills used this session: ${skills}; error-like tool results: ${errs}). If any of these happened while using a skill: an unanticipated error, advice or code that failed, a user correction, a version or API mismatch, or missing guidance, load the skill-lessons skill and write the entry to ${file}. If none applies, do nothing. Do not repeat your earlier answer; keep any reply to one short sentence."
      printf '{"decision":"block","reason":"%s"}\n' "$reason"
    fi
    ;;
esac
exit 0
