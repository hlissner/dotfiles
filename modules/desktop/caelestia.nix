{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.caelestia;
    system = pkgs.stdenv.hostPlatform.system;
    defaultShellPackage =
      if pkgs.stdenv.isLinux
      then hey.inputs.caelestia-shell.packages.${system}.with-cli
      else pkgs.runCommand "caelestia-shell-unavailable" {} "mkdir -p $out";
    defaultCliPackage =
      if pkgs.stdenv.isLinux
      then hey.inputs.caelestia-shell.inputs.caelestia-cli.packages.${system}.default
      else pkgs.runCommand "caelestia-cli-unavailable" {} "mkdir -p $out";
    terminalCommand = config.modules.desktop.term.default or "foot";
    shellSettings = recursiveUpdate {
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
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [{
        assertion = pkgs.stdenv.isLinux;
        message = "Caelestia shell is Linux-only and must not be enabled on Darwin.";
      }];
    }

    (mkIf pkgs.stdenv.isLinux {
      user.packages = [ cfg.package cfg.cliPackage ];

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
        serviceConfig = {
          ExecStart = "${cfg.package}/bin/caelestia-shell";
          Restart = "on-failure";
          RestartSec = 5;
          TimeoutStopSec = 5;
          Slice = "session.slice";
        };
        environment = {
          QT_QPA_PLATFORM = "wayland";
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
