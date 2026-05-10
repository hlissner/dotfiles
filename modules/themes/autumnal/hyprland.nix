{ hey, heyBin, lib, config, pkgs, ... } @ args:

with lib;
with hey.lib;
let cfg = config.modules.theme;
in {
  modules.desktop.hyprland.extraConfig = ''
    env = HYPRCURSOR_THEME,${cfg.gtk.cursorTheme.name}
    env = HYPRCURSOR_SIZE,${toString cfg.gtk.cursorTheme.size}

    general {
      gaps_in = 8
      gaps_out = 8
      border_size = 2
      col.active_border = rgba(f5c2e7ff) rgba(89b4faff) 45deg
      col.inactive_border = rgba(45475aff)
    }
    decoration {
      rounding = 14
      active_opacity = 1.0
      inactive_opacity = 0.96
      fullscreen_opacity = 1.0
      dim_strength = 0.12
      dim_inactive = false
      dim_special = 0.28
      dim_around = 0.28
      shadow {
        enabled = true
        range = 22
        render_power = 3
        color = rgba(11111bcc)
        color_inactive = rgba(11111b44)
      }
      blur {
        enabled = true
        size = 5
        passes = 2
        ignore_opacity = true
        xray = true
      }
    }

    # Caelestia owns desktop chrome; keep only compositor-level polish here.
    layerrule = match:namespace caelestia.*, blur true
    layerrule = match:namespace caelestia.*, ignore_alpha 0
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
