{ config, lib, pkgs, ... }:

{
  my.packages = with pkgs; [
    libqalculate # calculator cli w/ currency & unit conversion

    rxvt_unicode
    (writeScriptBin "urxvt-scratch" ''
      #!${stdenv.shell}
      SCRID=urxvt-scratch
      focused=$(xdotool getactivewindow)
      scratch=$(xdotool search --onlyvisible --classname $SCRID)
      if [[ -n $scratch ]]; then
        if [[ $focused == $scratch ]]; then
          xdotool windowkill $scratch
        else
          xdotool windowactivate $scratch
        fi
      else
        urxvt -name $SCRID \
              -geometry 100x26 \
              -e $SHELL -c '${tmux}/bin/tmux new-session -A -s scratch -n scratch'
      fi
    '')
    (writeScriptBin "urxvt-calc" ''
      #!${stdenv.shell}
      SCRID=urxvt-calc
      scratch=$(xdotool search --onlyvisible --classname $SCRID)
      [ -n "$scratch" ] && xdotool windowkill $scratch
      urxvt -name $SCRID \
            -geometry 80x20 \
            -e $SHELL -c 'qalc'
    '')
    (makeDesktopItem {
      name = "urxvt-calc";
      desktopName = "Calculator";
      icon = "calc";
      exec = "urxvt-calc";
      categories = "Development";
    })
  ];
}
