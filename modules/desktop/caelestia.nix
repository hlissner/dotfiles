{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.caelestia;
    system = pkgs.stdenv.hostPlatform.system;
    themeWallpaper = config.modules.theme.wallpapers."*" or {};
    defaultWallpaperPath = themeWallpaper.path or null;
    qtPlatform = "wayland;xcb";
    qtPlatformTheme = "qtengine";
    caelestiaFontFamilies = {
      clock = "Rubik";
      material = "Material Symbols Rounded";
      mono = "CaskaydiaCove NF";
      sans = "Rubik";
    };
    defaultShellPackage =
      if pkgs.stdenv.isLinux
      then hey.inputs.caelestia-shell.packages.${system}.with-cli
      else pkgs.runCommand "caelestia-shell-unavailable" {} "mkdir -p $out";
    defaultCliPackage =
      if pkgs.stdenv.isLinux
      then hey.inputs.caelestia-shell.inputs.caelestia-cli.packages.${system}.default
      else pkgs.runCommand "caelestia-cli-unavailable" {} "mkdir -p $out";
    terminalCommand = config.modules.desktop.term.default or "foot";
    wallpaperStateDir = "${config.home.stateDir}/caelestia/wallpaper";
    wallpaperStatePath = "${wallpaperStateDir}/path.txt";
    wallpaperGeneratedPath = "${wallpaperStateDir}/generated.jpg";
    seedWallpaperScript =
      if cfg.wallpaper.path == null then null else pkgs.writeShellScript "caelestia-seed-wallpaper" ''
        set -eu
        source=${escapeShellArg cfg.wallpaper.path}
        state_dir=${escapeShellArg wallpaperStateDir}
        state_path=${escapeShellArg wallpaperStatePath}
        generated=${escapeShellArg wallpaperGeneratedPath}
        desired=

        ${pkgs.coreutils}/bin/install -d -m 0755 "$state_dir"

        if [ -f "$source" ]; then
          desired="$source"

          if [ ! -s "$generated" ] || [ "$source" -nt "$generated" ]; then
            tmp="$(${pkgs.coreutils}/bin/mktemp "$generated.XXXXXX.jpg")"
            trap '${pkgs.coreutils}/bin/rm -f "$tmp"' EXIT
            if ${pkgs.imagemagick}/bin/magick "$source" -auto-orient -resize '3840x2160>' -strip -quality 92 "$tmp"; then
              ${pkgs.coreutils}/bin/mv -f "$tmp" "$generated"
              trap - EXIT
            else
              ${pkgs.coreutils}/bin/rm -f "$tmp"
              trap - EXIT
              printf 'caelestia-seed-wallpaper: failed to generate decode-safe wallpaper from %s\n' "$source" >&2
            fi
          fi

          if [ -s "$generated" ]; then
            desired="$generated"
          fi
        fi

        current=
        if [ -s "$state_path" ]; then
          current="$(${pkgs.coreutils}/bin/cat "$state_path")"
        fi

        if [ -n "$desired" ] && { [ -z "$current" ] || [ "$current" = "$source" ]; }; then
          printf '%s\n' "$desired" > "$state_path"
        fi
      '';
    shellSettings = recursiveUpdate {
      appearance.font.family = caelestiaFontFamilies;
      background.wallpaperEnabled = cfg.wallpaper.enable;
      general.apps = {
        terminal = [ terminalCommand ];
        audio = [ "pavucontrol" ];
        playback = [ "mpv" ];
        explorer = [ "thunar" ];
      };
      launcher.enableDangerousActions = false;
      utilities.toasts.kbLayoutChanged = false;
    } cfg.settings;
    shellSettingsFile = pkgs.writeText "caelestia-shell.json" (builtins.toJSON shellSettings);
    shellConfigDir = "${config.home.configDir}/caelestia";
    shellConfigPath = "${shellConfigDir}/shell.json";
    seedShellConfigScript = pkgs.writeShellScript "caelestia-seed-shell-config" ''
      set -eu
      config_dir=${escapeShellArg shellConfigDir}
      config_path=${escapeShellArg shellConfigPath}
      seed=${escapeShellArg "${shellSettingsFile}"}

      ${pkgs.coreutils}/bin/install -d -m 0755 "$config_dir"

      replace_shell_config=false
      if [ ! -e "$config_path" ] && [ ! -L "$config_path" ]; then
        replace_shell_config=true
      elif [ -L "$config_path" ]; then
        target="$(${pkgs.coreutils}/bin/readlink "$config_path")"
        case "$target" in
          /nix/store/*) replace_shell_config=true ;;
        esac
      fi

      if [ "$replace_shell_config" = true ]; then
        tmp="$(${pkgs.coreutils}/bin/mktemp "$config_path.XXXXXX")"
        trap '${pkgs.coreutils}/bin/rm -f "$tmp"' EXIT
        ${pkgs.coreutils}/bin/install -m 0644 "$seed" "$tmp"
        ${pkgs.coreutils}/bin/mv -f "$tmp" "$config_path"
        trap - EXIT
      fi
    '';
in {
  imports = optional pkgs.stdenv.isLinux hey.inputs.qtengine.nixosModules.default;

  options.modules.desktop.caelestia = with types; {
    enable = mkBoolOpt false;
    package = mkOpt package defaultShellPackage;
    cliPackage = mkOpt package defaultCliPackage;
    settings = mkOpt attrs {};
    cli.settings = mkOpt attrs {};
    wallpaper = {
      enable = mkBoolOpt false;
      path = mkOpt (nullOr str) defaultWallpaperPath;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [{
        assertion = pkgs.stdenv.isLinux;
        message = "Caelestia shell is Linux-only and must not be enabled on Darwin.";
      }];
    }

    (mkIf pkgs.stdenv.isLinux {
      programs.qtengine = {
        enable = true;
        config = {
          theme = {
            colorScheme = "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";
            iconTheme = config.modules.theme.gtk.iconTheme.name;
            style = "breeze";
            font = {
              family = config.modules.theme.fonts.sans.name;
              size = 12;
              weight = -1;
            };
            fontFixed = {
              family = config.modules.theme.fonts.mono.name;
              size = 12;
              weight = -1;
            };
          };
          misc = {
            menusHaveIcons = true;
            singleClickActivate = false;
            shortcutsForContextMenus = true;
          };
        };
      };

      environment.systemPackages = with pkgs.kdePackages; [
        breeze
        breeze.qt5
        breeze-icons
      ];

      user.packages = with pkgs; [
        cfg.package
        cfg.cliPackage

        hicolor-icon-theme
        adwaita-icon-theme
        papirus-icon-theme
        shared-mime-info
        xdg-utils
      ];

      fonts.packages = with pkgs; [
        material-symbols
        rubik
        nerd-fonts.caskaydia-cove
      ];

      systemd.user.services.caelestia-shell = {
        description = "Caelestia desktop shell";
        wantedBy = [ "hyprland-session.target" ];
        after = [ "hyprland-session.target" ];
        partOf = [ "hyprland-session.target" ];
        path = [
          cfg.cliPackage
          pkgs.unstable.app2unit
          pkgs.util-linux
        ] ++ config.users.users.${config.user.name}.packages
          ++ config.environment.systemPackages;
        serviceConfig = {
          ExecStartPre = [ "${seedShellConfigScript}" ]
            ++ optional (cfg.wallpaper.enable && cfg.wallpaper.path != null) "${seedWallpaperScript}";
          ExecStart = "${cfg.package}/bin/caelestia-shell --no-duplicate";
          Restart = "on-failure";
          RestartSec = 5;
          TimeoutStopSec = 5;
          Slice = "session.slice";
        };
        environment = {
          QT_QPA_PLATFORM = qtPlatform;
          QT_QPA_PLATFORMTHEME = qtPlatformTheme;
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
          QT_AUTO_SCREEN_SCALE_FACTOR = "1";
        };
      };

      home.configFile = optionalAttrs (cfg.cli.settings != {}) {
        "caelestia/cli.json".text = builtins.toJSON cfg.cli.settings;
      };

      hey.hooks.reload."94-caelestia-shell" = ''
        hey.do systemctl --user restart caelestia-shell.service
      '';
    })
  ]);
}
