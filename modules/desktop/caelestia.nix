{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.caelestia;
    system = pkgs.stdenv.hostPlatform.system;
    themeWallpaper = config.modules.theme.wallpapers."*" or {};
    defaultWallpaperPath = themeWallpaper.path or null;
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
    qtPlatformThemePackage = pkgs.unstable.qt6Packages.qt6ct;
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
      background.wallpaperEnabled = cfg.wallpaper.enable;
      general.apps = {
        terminal = [ terminalCommand ];
        audio = [ "pavucontrol" ];
        playback = [ "mpv" ];
        explorer = [ "thunar" ];
      };
      launcher.enableDangerousActions = false;
    } cfg.settings;
in {
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
      user.packages = with pkgs; [
        cfg.package
        cfg.cliPackage
        qtPlatformThemePackage

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
          ExecStart = "${cfg.package}/bin/caelestia-shell --no-duplicate";
          Restart = "on-failure";
          RestartSec = 5;
          TimeoutStopSec = 5;
          Slice = "session.slice";
        } // optionalAttrs (cfg.wallpaper.enable && cfg.wallpaper.path != null) {
          ExecStartPre = "${seedWallpaperScript}";
        };
        environment = {
          QT_QPA_PLATFORM = "wayland";
          QT_QPA_PLATFORMTHEME = "qt6ct";
        };
      };

      home.configFile = {
        "caelestia/shell.json".text = builtins.toJSON shellSettings;
      } // optionalAttrs (cfg.cli.settings != {}) {
        "caelestia/cli.json".text = builtins.toJSON cfg.cli.settings;
      };

      hey.hooks.reload."94-caelestia-shell" = ''
        hey.do systemctl --user restart caelestia-shell.service
      '';
    })
  ]);
}
