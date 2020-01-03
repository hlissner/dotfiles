# Kuro -- my desktop

{ config, pkgs, ... }:

{
  imports = [
    ./.  # import common settings

    ./modules/desktop/bspwm.nix

    ./modules/audio/audacity.nix
    ./modules/audio/lmms.nix
    ./modules/audio/spotify.nix
    ./modules/browser/firefox.nix
    ./modules/dev
    ./modules/dev/rust.nix
    ./modules/editors/emacs.nix
    ./modules/editors/vim.nix
    ./modules/gaming/steam.nix
    ./modules/graphics/aseprite.nix
    # ./modules/graphics/blender.nix
    ./modules/graphics/gimp.nix
    ./modules/misc/virtualbox.nix
    ./modules/shell/direnv.nix
    ./modules/shell/git.nix
    ./modules/shell/gnupg.nix
    ./modules/shell/pass.nix
    ./modules/shell/zsh.nix
    # ./modules/video/kdenlive.nix
    # ./modules/video/obs.nix

    # Services
    ./modules/services/syncthing.nix

    # Themes
    ./themes/aquanaut
  ];

  networking.hostName = "kuro";
  networking.networkmanager.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  # For ergodox ez
  environment = {
    systemPackages = [ pkgs.teensy-loader-cli ];
    shellAliases.teensyload = "sudo teensy-loader-cli -w -v --mcu=atmega32u4";
  };
}
