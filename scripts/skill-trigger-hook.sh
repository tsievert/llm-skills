#!/usr/bin/env bash
# Hook that enforces an explicit, pending "trigger the appropriate skill" instruction
# (see github-skill-maintenance/references/skill-trigger-hook.md and the lesson logged
# 2026-10-24, ~/.posit/lessons/inbox/anon_20261024-162307_manual.md).
#
# Handles three events, configured in ~/.posit/assistant/settings.json:
#   UserPromptSubmit
#     - if the prompt text matches TRIGGER_RE (an imperative "trigger/use/load ... skill"
#       phrase, not a question about one), record a pending marker for this session.
#       Never blocks; this event only observes.
#   PostToolUse (matcher "skill")
#     - any skill() call clears the pending marker for this session (some skill was
#       loaded; the hook cannot judge whether it was the *right* one).
#   Stop
#     - if a pending marker still exists and this session has not already been reminded,
#       block once, asking the assistant to load the matching skill or say why none
#       applies. The reminder is logged to reminders.tsv. stop_hook_active prevents a loop,
#       and the one-reminder-per-session flag prevents nagging after the first block.
#
#     - Also checks for escalation markers ("$sid.pending.fs.<skill>") written by
#       skill-file-signal-hook.sh when that hook's own non-blocking nudge for a skill has
#       fired twice in one session without a skill() load. This bridges a real recurrence
#       (2026-10-26, dlc-pig-method-paper conversation; see the lesson logged the same day
#       and research/skill-trigger-hooks-ledger.md section 8): a file-signal nudge is
#       visible in the transcript but was ignored twice in a row for two different skills.
#       skill-file-signal-hook.sh itself still never blocks (that invariant is unchanged and
#       still checked by check_sync_setup()); this script is the only one that emits
#       decision:"block", now triggered by either source. The reason names the specific
#       skill(s) when known from an escalation marker, unlike the explicit-instruction case
#       (still a fixed generic string, see "Why the phrase match..." above).
#
# This only checks "was some skill() call made after the instruction", not "was it the
# right skill" or "did the assistant actually act on it" — a deliberate limit, see the
# reference doc's "Known limits" section.
#
# Always exits 0 (fail open). Output on stdout is JSON only when it blocks a Stop.
# Local state only: ~/.posit/skill-triggers/{reminders.tsv,state/}. Nothing leaves the
# machine, and no user text is stored or echoed back (state files hold only a timestamp).
#
# Debug: `touch ~/.posit/skill-triggers/state/DEBUG` appends raw payloads to
# state/debug-payloads.jsonl (may contain private content; delete the file afterwards).

TRIGGER_DIR="${SKILL_TRIGGER_DIR:-$HOME/.posit/skill-triggers}"
STATE="$TRIGGER_DIR/state"
REMINDERS="$TRIGGER_DIR/reminders.tsv"

# Imperative "trigger/use/load/invoke/apply ... skill(s)" (or the passive form, "skill(s)
# ... triggered/loaded/used/invoked/applied"), in either order, within one clause (stops at
# '.', '?', '!' or a newline) and not immediately followed by '?' (a question about
# triggering a skill, e.g. "is this a reason to trigger ... skills?", is not an instruction).
# Known false positive (accepted, see the reference doc): a question with more words after
# the skill mention, e.g. "Should we use a different skill here?", still matches, because
# the '?' is more than a few characters past the match.
TRIGGER_RE='\b(trigger|use|load|invoke|apply)\b[^.?!\n]{0,60}\bskills?\b(?!\s*\?)'
TRIGGER_RE="$TRIGGER_RE"'|\bskills?\b[^.?!\n]{0,60}\b(triggered|loaded|used|invoked|applied)\b(?!\s*\?)'

payload=$(cat 2>/dev/null) || exit 0
mkdir -p "$STATE" 2>/dev/null || exit 0

jstr() { printf '%s' "$payload" | sed -n "s/.*\"$1\" *: *\"\([^\"]*\)\".*/\1/p" | head -n1; }

event=$(jstr hook_event_name)
sid=$(jstr session_id)
[ -n "$sid" ] || exit 0
cwd=$(jstr cwd | sed 's#\\\\#/#g; s#\\#/#g')
project=$(printf '%s' "$(basename "${cwd:-unknown}")" | tr -c 'A-Za-z0-9._-' '_')

[ -f "$STATE/DEBUG" ] && printf '%s\n' "$payload" >> "$STATE/debug-payloads.jsonl"

case "$event" in
  UserPromptSubmit)
    # Scan the whole payload, not just an isolated "prompt" field: extracting a JSON
    # string value with a single sed capture breaks on embedded quotes, which arbitrary
    # user text will contain. The other fields (session_id, transcript_path, cwd,
    # hook_event_name, permission_mode) cannot plausibly contain this phrase, so the risk
    # of matching outside the prompt text is negligible.
    if printf '%s' "$payload" | grep -qiP "$TRIGGER_RE"; then
      date +%s > "$STATE/$sid.pending"
    fi
    ;;
  PostToolUse)
    tool=$(jstr tool_name)
    [ "$tool" = "skill" ] && rm -f "$STATE/$sid.pending"
    ;;
  Stop)
    case "$payload" in *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;; esac

    explicit=0
    [ -f "$STATE/$sid.pending" ] && explicit=1

    fs_cands=""
    for f in "$STATE/$sid.pending.fs."*; do
      [ -e "$f" ] || continue
      cand="${f#"$STATE/$sid.pending.fs."}"
      fs_cands="$fs_cands $cand"
    done
    fs_cands="${fs_cands# }"

    { [ "$explicit" -eq 1 ] || [ -n "$fs_cands" ]; } || exit 0
    [ -f "$STATE/$sid.reminded" ] && exit 0
    touch "$STATE/$sid.reminded"
    rm -f "$STATE/$sid.pending"
    for f in "$STATE/$sid.pending.fs."*; do rm -f "$f" 2>/dev/null; done
    printf '%s\t%s\t%s\n' "$(date +%Y-%m-%dT%H:%M:%S)" "$sid" "$project" >> "$REMINDERS"
    # Housekeeping: drop per-session state older than 30 days.
    find "$STATE" -maxdepth 1 -type f -mtime +30 -delete 2>/dev/null

    if [ -n "$fs_cands" ] && [ "$explicit" -eq 1 ]; then
      reason="Skill-trigger check (automatic hook): an earlier message in this session asked you to trigger/use/load a skill, and file content read since then also repeatedly matched the declared file signal of:$fs_cands. No skill() call has been made since. Before finishing, either load the matching skill(s) now, or say in one sentence why none applies. This check fires at most once per session."
    elif [ -n "$fs_cands" ]; then
      reason="Skill-trigger check (automatic hook): file content read earlier in this session repeatedly matched the declared file signal of:$fs_cands, and it has not been loaded. Before finishing, either load it now, or say in one sentence why it does not apply. This check fires at most once per session."
    else
      reason="Skill-trigger check (automatic hook): an earlier message in this session asked you to trigger/use/load a skill, and no skill() call has been made since. Before finishing, either load the matching skill now, or say in one sentence why none applies. This check fires at most once per session."
    fi
    printf '{"decision":"block","reason":"%s"}\n' "$reason"
    ;;
esac
exit 0
