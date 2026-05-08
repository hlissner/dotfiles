{ hey, heyBin, lib, config, pkgs, ... } @ args:

with lib;
with hey.lib;
let cfg = config.modules.theme;
in {
  modules.desktop.hyprland.extraConfig = ''
    env = HYPRCURSOR_THEME,${cfg.gtk.cursorTheme.name}
    env = HYPRCURSOR_SIZE,${toString cfg.gtk.cursorTheme.size}

    general {
      gaps_in = 0
      gaps_out = 0
      border_size = 1
      col.active_border = rgba(e6818388) rgba(363637ff) 45deg
      col.inactive_border = rgba(161617ff)
    }
    decoration {
      rounding = 0
      dim_strength = 0.2
      dim_inactive = true
      dim_special = 0.4
      dim_around = 0.4
      shadow {
        enabled = true
        range = 10
        render_power = 4
        color = rgba(0f0f0f88)
      }
      blur {
        enabled = true
        size = 4
        passes = 1
      }
    }

    # DMS/Quickshell layers own shell surfaces.
    layerrule = match:namespace rofi, dim_around true
    layerrule = match:namespace rofi, animation slide top
    layerrule = match:namespace quickshell, blur true
    layerrule = match:namespace quickshell, ignore_alpha 0
  '';

  home.configFile."doom/config.local.el".text = ''
    ;; -*- lexical-binding: t -*-
    (add-to-list 'default-frame-alist '(alpha-background . 95))
    (setq doom-theme 'doom-tomorrow-night)
    (custom-theme-set-faces! 'doom-tomorrow-night
      '(default :background "#1d1f21")
      '(solaire-default-face :background "#191B1A"))
  '';
}
