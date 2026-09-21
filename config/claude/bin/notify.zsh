#!/usr/bin/env zsh
# Toast me when claude-code finishes a turn or wants something from me.
#
# SYNOPSIS:
#   hey @claude notify
#
# DESCRIPTION:
#   Reads a hook payload on stdin and branches on its hook_event_name. Wired up
#   in config/claude/managed-settings.d/20-notify.json; teaching it a new event
#   means adding it there and an arm below. Anything not wired up still toasts,
#   just blandly, so a new hook is never silent.

emulate -L zsh
set -uo pipefail

local payload=$(cat)

# Each arm digs its own fields out of the same blob -- they share almost
# nothing but the payload -- and `preview` is the one thing they do share:
# flatten to a single line and clip it to what a toast can show.
jqp() {
  jq -r 'def preview($n): gsub("\\s+"; " ") | sub("^ "; "") | sub(" $"; "")
                          | if length > $n then .[0:($n - 1)] + "…" else . end;
         def preview: preview(160);
         '"$1" <<<"$payload"
}

local event=$(jqp '.hook_event_name // ""')
# The :=, belt to jq's // braces: if the payload isn't JSON at all, jq exits
# non-zero and hands back nothing rather than the default.
local project=$(jqp '.cwd // "" | split("/") | map(select(length>0)) | last // ""')
: "${project:=session}"
local body icon level

case $event in
  Stop)
    # last_assistant_message, not the transcript: the latter is flushed
    # asynchronously and may not have this turn's reply in it yet.
    body=$(jqp '(.last_assistant_message // "") | preview')
    : "${body:=Turn complete}"
    icon=dialog-information level=info
    ;;
  Notification)
    # Only the matchers in 20-notify.json get this far -- permission prompts and
    # agents blocked on input -- so every one of them is critical: the session
    # is stopped dead until I look at it.
    body=$(jqp '(.message // "") | preview')
    : "${body:=Claude Code is waiting on you}"
    icon=dialog-question level=error
    ;;
  *)
    body=$(jqp '(.message // .last_assistant_message // "") | preview')
    : "${body:=${event:-An unknown event} fired}"
    icon=dialog-information level=info
    ;;
esac

hey.toast -a "Claude Code" -c claude-code -i $icon -H \
  $level "Claude ($project)" "$body"
