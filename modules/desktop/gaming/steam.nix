{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.gaming.steam;
in {
  options.modules.desktop.gaming.steam = with types; {
    enable = mkBoolOpt false;
    hardware.enable = mkBoolOpt false;
    libDir = mkOpt str "$XDG_DATA_HOME/steamlib";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # I avoid programs.steam.enable because it installs another steam binary,
      # which the xdesktop package invokes, instead of my steam shims below.
      hardware.opengl.enable = true;
      hardware.opengl.driSupport32Bit  = true;
      hardware.pulseaudio.support32Bit = config.hardware.pulseaudio.enable;

      user.packages = with pkgs; [
        # Get steam to keep its garbage out of $HOME
        (writeScriptBin "steam" ''
          #!${stdenv.shell}
          HOME="${cfg.libDir}" exec ${steam}/bin/steam "$@"
        '')
        # for running GOG and humble bundle games
        (writeScriptBin "steam-run" ''
          #!${stdenv.shell}
          HOME="${cfg.libDir}" exec ${steam-run-native}/bin/steam-run "$@"
        '')
        # So a rofi entry exists
        (makeDesktopItem {
          name = "steam";
          desktopName = "Steam";
          icon = "steam";
          exec = "steam";
          terminal = "false";
          mimeType = "x-scheme-handler/steam";
          categories = "Network;FileTransfer;Game";
        })
      ];
      system.userActivationScripts.setupSteamDir = ''mkdir -p "${cfg.libDir}"'';

      # better for steam proton games
      systemd.extraConfig = "DefaultLimitNOFILE=1048576";
    }

    (mkIf cfg.hardware.enable {
      hardware.steam-hardware.enable = true;
    })
  ]);
}
