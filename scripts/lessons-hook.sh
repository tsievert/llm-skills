#!/usr/bin/env bash
# Hook for the lessons-learned loop (see the skill-lessons and skill-feedback-triage skills).
# Handles two events, configured in ~/.posit/assistant/settings.json:
#   PostToolUse (matcher "skill|executeCode|executeR|bash")
#     - tool "skill": log which of THIS repo's skills was loaded (deterministic usage log).
#     - other tools: count tool responses that look like errors, but only in sessions
#       that already loaded one of this repo's skills. Only a count is stored, never text.
#   Stop
#     - at most ONCE per session, ask the assistant to write a use-case summary (always) and
#       lesson entries (if any) when a repo skill was used and (an error was seen OR
#       LESSONS_TURN_LIMIT turns have passed) and no entry was written yet. Each reminder
#       is logged to ~/.posit/lessons/reminders.tsv so triggering can be checked.
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
TURN_LIMIT="${LESSONS_TURN_LIMIT:-2}"   # Stop events after the first skill load before the first reminder
REPEAT_EVERY="${LESSONS_REPEAT_EVERY:-5}"   # further Stop events between repeat reminders
CORR_PATTERN="(^|[^a-z])(no[,.!]|wrong|incorrect|that.s not|that is not|not what i|actually|instead|you (missed|forgot|should)|don.t do|doesn.t work|did(n.t| not) work|still (fails|broken|error))"
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
  UserPromptSubmit)
    # Count correction-like prompts (a proxy for "user corrected the assistant"); count only, no text.
    [ -n "$(session_skills)" ] || exit 0
    prompt=${payload#*\"prompt\"}
    if printf '%s' "$prompt" | grep -qiE "$CORR_PATTERN"; then
      date +%s >> "$STATE/$sid.corrections"
    fi
    ;;
  PostToolUse)
    tool=$(jstr tool_name)
    if [ "$tool" = "skill" ]; then
      name=$(jstr skill)
      [ -n "$name" ] && [ -f "$REPO_DIR/$name/SKILL.md" ] || exit 0
      printf '%s\t%s\t%s\t%s\n' "$(date +%Y-%m-%dT%H:%M:%S)" "$sid" "$project" "$name" >> "$USAGE"
      # Loading the capture skill counts as a reminder done now; the next one comes after
      # REPEAT_EVERY more turns (or a new error/correction), not never.
      if [ "$name" = "skill-lessons" ]; then
        printf '%s %s %s\n' "$(count_lines "$STATE/$sid.turns")" "$(count_lines "$STATE/$sid.errors")" "$(count_lines "$STATE/$sid.corrections")" > "$STATE/$sid.reminded"
      fi
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
    errs=$(count_lines "$STATE/$sid.errors")
    turns=$(count_lines "$STATE/$sid.turns")
    corr=$(count_lines "$STATE/$sid.corrections")
    fire=0
    if [ ! -f "$STATE/$sid.reminded" ]; then
      # First reminder: any error or correction, or TURN_LIMIT turns.
      { [ "$errs" -ge 1 ] || [ "$corr" -ge 1 ] || [ "$turns" -ge "$TURN_LIMIT" ]; } && fire=1
    else
      # Repeat reminders: new error or correction since the last one, or REPEAT_EVERY more turns.
      read -r last_turns last_errs last_corr < "$STATE/$sid.reminded"
      { [ "$errs" -gt "${last_errs:-0}" ] || [ "$corr" -gt "${last_corr:-0}" ] \
        || [ $(( turns - ${last_turns:-0} )) -ge "$REPEAT_EVERY" ]; } && fire=1
    fi
    if [ "$fire" -eq 1 ]; then
      printf '%s %s %s\n' "$turns" "$errs" "$corr" > "$STATE/$sid.reminded"
      existing=$(ls "$INBOX"/*_"$sid8".md 2>/dev/null | head -n1)
      file=${existing:-$INBOX/${project}_$(date +%Y%m%d-%H%M%S)_${sid8}.md}
      # JSON-safe path: forward slashes only (a Windows path would need escaped backslashes).
      file=$(cygpath -m "$file" 2>/dev/null || printf '%s' "$file")
      file=$(printf '%s' "$file" | sed 's#\\#/#g')
      printf '%s\t%s\t%s\t%s\terrors=%s\tcorrections=%s\tturns=%s\n' "$(date +%Y-%m-%dT%H:%M:%S)" "$sid" "$project" "$skills" "$errs" "$corr" "$turns" >> "$LESSONS_DIR/reminders.tsv"
      reason="Lessons check (automatic hook; skills used this session: ${skills}; error-like tool results: ${errs}; correction-like user prompts: ${corr}; turns: ${turns}). Load the skill-lessons skill and write to ${file} (append if it exists): (1) a use-case entry if none exists yet in that file (type use-case): generic one to three sentences on what the user was doing with the skill(s), outcome, friction; no data values, names or paths. (2) Review the WHOLE conversation so far, not only recent turns, and add one lesson entry for each unanticipated error or warning, failed advice or code, workaround, user correction or override, version or API mismatch, missing guidance, or recommendation that held up (worked-well) that is not yet recorded. Prefer too many entries over too few; use generality: unsure when in doubt. Do not repeat your earlier answer; keep any reply to one short sentence."
      printf '{"decision":"block","reason":"%s"}\n' "$reason"
    fi
    ;;
esac
exit 0
