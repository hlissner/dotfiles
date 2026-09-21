#!/usr/bin/env zsh
# Capture a screenshot to clipboard.
#
# SYNOPSIS:
#   screenshot [-o FILE] [all|full|last|region|window|output]
#
# DESCRIPTION:
#   Captures a screenshot with grim (selecting through `hey .slurp`), compresses
#   it with pngquant, then copies it to your clipboard. If you want graphics,
#   use `noctalia msg annotate` to draw on the screen before calling this
#   script.
#
# OPTIONS:
#   -o, --output FILE @files
#     Write the PNG to FILE (- for stdout) and say nothing, instead of copying
#     it to the clipboard. For scripts that want the image rather than my
#     clipboard, like `hey wm ocr`.
#
# ARGUMENTS:
#   1 TARGET
#     all       -- Capture all outputs combined
#     full      -- Capture the focused output
#     last      -- Capture the previous selection.
#     region    -- Select a region interactively (the default).
#     window    -- Select selected window.
#     output    -- Select a monitor.

main() {
  set -eo pipefail
  hey.requires grim pngquant
  local -a outfile
  zparseopts -D -F -- o:=outfile -output:=outfile || exit 1
  local -a args
  case ${1:-region} in
    all) ;;
    full) args=( -o "$(hyprctl activeworkspace -j | jq -r .monitor)" ) ;;
    last|region|window|output) args=( -g "$(hey .slurp $1)" ) ;;
    *) hey.abort "Unknown target: $1" ;;
  esac
  if [[ $outfile ]]; then
    local dest=${outfile[2]}
    [[ $dest == - ]] && dest=/dev/stdout
    grim "${args[@]}" - | pngquant --strip -s 10 - >| $dest
    return
  fi
  local preview_file=$(hey path runtime screenshot.png)
  if grim "${args[@]}" - | \
       pngquant --strip -s 10 - >$preview_file | \
       wl-copy -t image/png; then
    trap "rm -f $preview_file" EXIT
    hey.toast -i $preview_file info "Screenshot captured" "Copied to clipboard"
  else
    hey.toast warn "Aborted"
  fi
}

main $@
