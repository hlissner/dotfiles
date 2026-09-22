#!/usr/bin/env zsh
# Claude Code's statusline: model, workspace, context, session spend, and how
# much of the plan I've burned.
#
# Wired up in config/claude/managed-settings.d/30-statusline.json, which points
# at `hey @claude statusline`. Claude Code pipes the session JSON in and prints
# whatever comes back, once per assistant message.
#
# `rate_limits` only exists on a claude.ai subscription, and not until the
# session's first API response, so the windows turn up a beat after the model
# does. Claude Code also drops one once its reset time passes. `context_window`
# is null until then too, and again after a /compact.

emulate -L zsh
set -uo pipefail
setopt extended_glob  # for the backreference in abbrev()
zmodload zsh/datetime

local model effort workspace ctx ctx_used ctx_size
local five_hour five_reset seven_day spend usd transcript project
IFS=$'\t' read -r model effort workspace ctx ctx_used ctx_size \
                  five_hour five_reset seven_day spend usd transcript project < <(jq -r '[
  # "Opus 5 (1M context)" is a third of the bar. Squeeze the id down to "O5"
  # instead: family initial + every version number in it, so claude-haiku-4-5
  # is H4.5 and the old claude-3-5-sonnet is S3.5. Unrecognised ids, say from a
  # gateway with its own naming, fall back to the display name.
  # sub() order matters: the "[1m]" suffix and the date have to go before the
  # split, or the version number comes out attached to them and stops matching.
  ((.model.id // "" | ascii_downcase | sub("\\[.*$";"") | sub("-\\d{8}";"") | split("-")) as $t
   | ($t | map(select(test("^(opus|sonnet|haiku|fable)$"))) | first) as $family
   | if $family
     then ($family[0:1] | ascii_upcase) + ($t | map(select(test("^\\d+$"))) | join("."))
     else .model.display_name // "?" end),
  # Absent on models that have no effort parameter at all.
  .effort.level // "-",
  (.worktree.name
   // .workspace.git_worktree
   // (.workspace.project_dir // .cwd // "" | split("/") | map(select(length > 0)) | last)
   // "?"),
  # "-" rather than empty everywhere below: tab is an IFS *whitespace* char, so
  # `read` collapses a run of them and an empty field would shift every field
  # after it one to the left.
  .context_window.used_percentage // "-",
  ((.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0)),
  .context_window.context_window_size // 0,
  .rate_limits.five_hour.used_percentage // "-",
  .rate_limits.five_hour.resets_at // 0,
  .rate_limits.seven_day.used_percentage // "-",
  .rate_limits.spend_limit.used_percentage // "-",
  .cost.total_cost_usd // 0,
  .transcript_path // "-",
  .workspace.project_dir // .cwd // "-"
] | @tsv')
[[ $effort == - ]] && effort=

# Bold is spelled out rather than %B/%b: prompt expansion remembers the last
# colour it emitted, so %b comes back as "reset, then re-apply that colour" and
# smears grey over whatever follows. 22m turns bold off and touches nothing else.
local bold=$'\e[1m' unbold=$'\e[22m'
local off=${(%):-%f} dim=${(%):-%F{8}}
local -A hue=( ok ${(%):-%F{green}} warn ${(%):-%F{yellow}} hot ${(%):-%F{red}} )
# rgb(136,136,136) is promptBorder in Claude Code's dark themes — the grey it
# rules the prompt pane's top and bottom in. Lifted out of the binary with
# `grep -ao 'promptBorder:"[^"]*"'`, because nothing in the session JSON says
# which theme is live. Light themes use #999999 and the ansi theme plain white,
# so it's a shade off on those.
local rule=$'\e[38;2;136;136;136m'

local -a segs
meter() {  # LABEL PCT [NOTE] -- appends "5h 91% 2h13m", or nothing if PCT is "-"
  [[ $2 == - ]] && return
  local color=$hue[ok]
  (( $2 >= 70 )) && color=$hue[warn]
  (( $2 >= 90 )) && color=$hue[hot]
  segs+=( "$dim$1$off $color$(printf '%.0f%%' $2)$off${3:+ $dim$3$off}" )
}

tokens() {  # 47320 -> 47k, 1722198 -> 1.7M, 1000000 -> 1M
  (( $1 >= 1000000 )) && { local m=$(printf '%.1f' $(( $1 / 1000000.0 ))); printf '%sM' ${m%.0}; return }
  printf '%dk' $(( $1 / 1000 ))
}

countdown() {  # EPOCH -> "2h13m", "47m", or nothing once it's in the past
  local -i s=$(( $1 - EPOCHSECONDS ))
  (( s <= 0 )) && return
  (( s >= 3600 )) && { printf '%dh%02dm' $(( s / 3600 )) $(( s % 3600 / 60 )); return }
  printf '%dm' $(( (s + 59) / 60 ))
}

abbrev() {  # /home/me/projects/config/dotfiles -> ~/p/c/dotfiles
  local p=${(D)1}
  [[ $p == */* && $p != / ]] || { print -r -- $p; return }
  print -r -- "${${p:h}//(#b)([^\/])[^\/]#/$match[1]}/${p:t}"
}

local ctx_note=
(( ctx_size )) && ctx_note="$(tokens $ctx_used)/$(tokens $ctx_size)"
meter ctx $ctx $ctx_note

# Nothing in the session JSON totals the tokens a session has burned —
# context_window is only what's live right now. The transcript has every API
# response's usage, though, so add them up: one jq pass streaming id + tokens,
# then awk to dedupe (a response is logged once per content block) and sum.
# All four counters, because this is meant to answer "what would the API have
# charged me for this?" and cache_read is billed too, just at a tenth. It also
# dwarfs everything else — the whole prefix is re-read every single turn — so
# expect this to sit in the millions and climb on its own while I'm idle.
if [[ $transcript != - && -r $transcript ]]; then
  local -i spent=$(jq -rc '
    select(.message.usage) | [
      (.message.id // .uuid),
      (.message.usage | (.input_tokens // 0) + (.cache_creation_input_tokens // 0)
                      + (.cache_read_input_tokens // 0) + (.output_tokens // 0))
    ] | @tsv' $transcript \
    | awk -F'\t' '!seen[$1]++ { n += $2 } END { print n + 0 }')
  # total_cost_usd is Claude Code's own client-side estimate at list price, so
  # it's indicative, not a bill. Both reset when /clear starts a new session.
  (( spent )) && segs+=( "$(tokens $spent) $dim$(printf '$%.2f' $usd)$off" )
fi

meter 5h $five_hour $(countdown $five_reset)
meter 7d $seven_day
meter spend $spend

# The separator has to be a variable: the j: : flag's argument only expands one
# parameter, so an inline " $rule|$off " comes out literal.
local sep=" $rule|$off "
[[ $project != - ]] && workspace=$(abbrev $project)
local head="$bold$model$unbold${effort:+$dim:$off$effort}$dim:$off$workspace"
print -r -- "$head${segs:+$sep${(pj:$sep:)segs}}"
