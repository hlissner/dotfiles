# modules/hyprland/dms.nix
#
# DankMaterialShell: the shell itself, its plugins, and the login screen it
# puts in front of them. Follows modules.hyprland.enable.

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.hyprland;
    primaryMonitor = findFirst (x: x.primary) {} cfg.monitors;
    dmsPlugin = { owner, repo, rev, hash, subdir ? null }:
      let src = pkgs.fetchFromGitHub { inherit owner repo rev hash; };
      in if subdir == null then src else "${src}/${subdir}";

    dankHooksSrc = dmsPlugin {
      owner = "AvengeMedia"; repo = "dms-plugins"; subdir = "DankHooks";
      rev = "6fc7f25bfb24f93b6488fb8a36ed67b5f242abdb";
      hash = "sha256-KGpNgxN/zXiMjLLm4zLX+Wgnj1vx8bGGd6WwGBWo7Ds=";
    };

    # Every event the pinned plugin reads, all pointed back at `hey hook`.
    dankHooksSettings =
      pkgs.runCommand "dank-hooks.json" { nativeBuildInputs = [ pkgs.jq ]; } ''
        grep -oE 'pluginData\.[a-zA-Z]+' ${dankHooksSrc}/DankHooks.qml \
          | sed 's/^pluginData\.//' | sort -u > keys
        [ "$(wc -l < keys)" -ge 20 ] \
          || { echo "only $(wc -l < keys) hooks found in DankHooks.qml" >&2; exit 1; }
        jq -Rs 'split("\n")
                | map(select(length > 0) | { key: ., value: "hey hook -f" })
                | from_entries' keys > $out
      '';
in {
  config = mkIf cfg.enable {
    programs.dms-shell = {
      enable = true;
      systemd.enable = true;
      enableCalendarEvents = false;

      # Only puts them on disk; still have to toggle them on in DMS settings.
      plugins = {
        dankHooks.src = dankHooksSrc;
        hyprlandSubmapIndicator.src = dmsPlugin {
          owner = "nderscore"; repo = "dms-plugins"; subdir = "HyprlandSubmapIndicator";
          rev = "568fd7682a53ef07482799b91f81dc3383a91967";
          hash = "sha256-kRCa4feK4c+6VjvUHsOYetM+WBM38ZVU4s2IBYEoat4=";
        };
        screenkey.src = dmsPlugin {
          owner = "hthienloc"; repo = "dms-screenkey";
          rev = "526c08eeab486ca3b5b5fc88a99bfcc0c0007ec9";
          hash = "sha256-CURkyFRVcQ7P+IpaHW7Dv7Z//cM3Da64is6UMBcRMHk=";
        };
        timer.src = dmsPlugin {
          owner = "hthienloc"; repo = "dms-timer";
          rev = "73fade01762bd88a19e45bf5d1d663b93ce79fcf";
          hash = "sha256-Jf6pU2ouHGVO+QeY+vqBt+0CYXV6p5+sy7D6IAlog18=";
        };
        systemMonitor.src = dmsPlugin {
          owner = "chr314"; repo = "dms-system-monitor";
          rev = "c7cb5fbbd393ff8c1d76bf73633abd9fe9859236";
          hash = "sha256-eyQ/Y4gqJVjatmolgGnpTsnVAnN6xUYpU//cC4wgIjo=";
        };

        dankscale = {
          enable = elem "ts0" config.modules.profiles.networks;
          src = dmsPlugin {
            owner = "dwright134"; repo = "dms-dankscale";
            rev = "bddebf0e2935ba23b0614ff9af5bf8f4ed6d3d9f";
            hash = "sha256-o5kcFV7VAmHJqsKgnjDuuryubnuI9U+GQIPOlENZ5ao=";
          };
        };
        gameControllerBattery = {
          enable = config.modules.apps.steam.enable;
          src = dmsPlugin {
            owner = "Hujair"; repo = "gameControllerBattery";
            rev = "8ab63f4274e505cbefc2432e9a2e1dd8a1809113";
            hash = "sha256-irWI2LI8IOhva/DpfF8nI23wQMKyOPGNv86G9ZDjJ4g=";
          };
        };
        dankKDEConnect = {
          enable = config.programs.kdeconnect.enable;
          src = dmsPlugin {
            owner = "AvengeMedia"; repo = "dms-plugins"; subdir = "DankKDEConnect";
            rev = "6fc7f25bfb24f93b6488fb8a36ed67b5f242abdb";
            hash = "sha256-KGpNgxN/zXiMjLLm4zLX+Wgnj1vx8bGGd6WwGBWo7Ds=";
          };
        };
      };
    };

    # Needed for changing charge thresholds in Settings > Power & Security >
    # Battery since 26.11 (the setuid wrapper is opt-in from NixOS 26.11+)
    security.polkit.enablePkexecWrapper = true;

    services.greetd.enable = true;

    services.displayManager = {
      # In case I ever want to enable greetd's autologin in the future.
      # dms-greeter greeter doesn't respect this otherwise.
      defaultSession = "hyprland-uwsm";

      dms-greeter = {
        enable = true;
        logs.save = true;
        compositor.name = "hyprland";
        compositor.customConfig = ''
          hl.config({
            misc = {
              background_color = 0xff000000,
              force_default_wallpaper = 0,
              disable_hyprland_logo = true,
              disable_splash_rendering = true
            },
            ecosystem = {
              no_update_news = true,
              no_donation_nag = true
            },
            cursor = {
              inactive_timeout = 1,
              hide_on_key_press = true
            }
          })

          ${optionalString (primaryMonitor ? output)
              # Name every monitor I don't want, rather than sweeping them all
              # away with `output = ""` and putting the primary back a frame
              # later. That wildcard took the primary down with it, and on
              # nvidia every re-enable is a full link retrain -- the monitor
              # physically blinking off and on. The others still flicker; they
              # have to, they're being turned off.
              (concatStringsSep "\n" (map (m:
                if m.output == primaryMonitor.output
                then ''
                  hl.monitor({
                    output = "${m.output}",
                    mode = "${m.mode}",
                    position = "0x0",
                    scale = ${toString m.scale}
                  })
                ''
                else ''
                  hl.monitor({ output = "${m.output}", disabled = true })
                '')
                cfg.monitors))}
        '';
        # The user's wallpaper and theme, carried onto the login screen. Wants the
        # home directory itself, not $XDG_CONFIG_HOME; the module appends the XDG
        # paths to it.
        configHome = config.home.dir;
      };
    };

    systemd.services.greetd.preStart = mkBefore ''
      # The module's own preStart copies the user's config in but never clears
      # what the last boot left behind.
      rm -f /var/lib/dms-greeter/session.json /var/lib/dms-greeter/wallpaper*
    '';

    # Configure Dank Hooks, since its key to this entire config. However,
    # because DMS doesn't reread its config file, it must be restarted (or the
    # system rebooted) for it to see this change:
    #
    #   systemctl restart --user dms
    systemd.user.services.dms-hooks = {
      description = "Merge declarative Dank Hooks settings into DMS";
      wantedBy = [ "dms.service" ];
      before = [ "dms.service" ];
      path = with pkgs; [ coreutils jq ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        file="${config.home.configDir}/DankMaterialShell/plugin_settings.json"
        mkdir -p "$(dirname "$file")"
        [ -e "$file" ] || echo '{}' > "$file"

        if ! jq -e 'type == "object"' "$file" >/dev/null 2>&1; then
          echo "$file is not a JSON object, leaving it alone" >&2
          exit 0
        fi

        tmp="$(mktemp "$file.XXXXXX")"
        # `enabled` is only seeded, never asserted -- the on/off switch stays mine.
        jq --slurpfile hooks ${dankHooksSettings} \
           '.dankHooks = (.dankHooks // { enabled: true }) * $hooks[0]' \
           "$file" > "$tmp"
        mv "$tmp" "$file"
      '';
    };

    environment.systemPackages = with pkgs; [
      adw-gtk3       # for DMS
      libinput       # For screenkey plugin
    ];

    user.extraGroups = [ "input" ];   # For DMS Screenkey plugin

    ## So DMS+Matugen can theme QT apps
    qt = {
      enable = true;
      platformTheme = "qt5ct";
    };

    environment.sessionVariables = {
      QT_QPA_PLATFORMTHEME = "qt5ct";
      QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
    };
    # If DMS is launched vya systemd, it won't see the profile envvars, so...
    home.configFile."environment.d/90-dms.conf".text = ''
      QT_QPA_PLATFORMTHEME = "qt5ct";
      QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
    '';

    user.packages = [
      (mkLauncherEntry "Toggle night mode" {
        icon = "redshift";
        exec = "dms ipc night toggle";
      })
      (mkLauncherEntry "Color picker: grab RGB at point" {
        icon = "com.github.finefindus.eyedropper";
        exec = "dms color pick --rgb -a";
      })
      (mkLauncherEntry "Color picker: grab HSL at point" {
        icon = "com.github.finefindus.eyedropper";
        exec = "dms color pick --hsl -a";
      })
      (mkLauncherEntry "Color picker: grab hex at point" {
        icon = "com.github.finefindus.eyedropper";
        exec = "dms color pick --hex -a";
      })
    ];
  };
}
