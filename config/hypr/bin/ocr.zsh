#!/usr/bin/env zsh
# Copy text out of a region of the screen, via OCR.
#
# SYNOPSIS:
#   ocr [-l LANG] [all|full|last|region|window|output]
#
# DESCRIPTION:
#   Screenshots a region (with `hey .screenshot`), processes it with tesseract,
#   and sends the result to your clipboard (with notifications).
#
# DEPENDENCIES:
#   grim, pngquant, imagemagick*, tesseract*
#
#   * Auto-installed with cached-nix-shell on demand.
#
# OPTIONS:
#   -l, --lang LANG
#     The tesseract language to recognize, or several joined by "+"
#     (e.g. eng+jpn). Defaults to eng.
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
  setopt localoptions extendedglob
  hey.requires cached-nix-shell wl-copy
  local -a lang
  zparseopts -D -F -- l:=lang -lang:=lang || exit 1
  local spec=${lang[2]:-eng}
  # It lands in a nix expression below, so it doesn't get to be arbitrary.
  [[ $spec == [[:alnum:]_]##(+[[:alnum:]_]##)# ]] \
    || hey.abort "Not a tesseract language: $spec"
  # Unoverridden, nixpkgs' tesseract carries every language it has ever heard
  # of: a 1.1G closure to read a tooltip. Take only what I asked for (112M).
  local -a langs=( ${(s:+:)spec} )
  local pkg="tesseract.override { enableLanguages = [ ${(j: :)${(@qqq)langs}} ]; }"

  local img=$(hey path runtime ocr.png)
  trap "rm -f $img" EXIT
  # A cancelled selection is not an error worth announcing twice.
  hey .screenshot -o $img ${1:-region} || exit $?

  hyprctl notify 1 5000 0 "Processing capture..."
  local text
  text=$(hey.do -! -p "$pkg" -p imagemagick \
           sh -c "magick png:'$img' -colorspace Gray -resize 300% -sharpen 0x1 png:- |
                  tesseract --dpi 300 - - -l '$spec'") || exit $?
  hyprctl dismissnotify
  # tesseract ends every page with a form feed.
  text=${text//$'\f'/}
  if [[ -z ${text//[[:space:]]/} ]]; then
    hey.toast -c ocr warn "Nothing to read" "OCR found no text there"
    exit 1
  fi

  print -rn -- $text | wl-copy
  local preview=${${text//[[:space:]]##/ }##[[:space:]]#}
  (( $#preview > 120 )) && preview="${preview[1,119]}…"
  hey.toast -c ocr -i text-scan-2 info "Copied $#text characters" "$preview"
}

main $@
