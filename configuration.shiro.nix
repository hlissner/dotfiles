# Shiro -- my laptop

{ config, lib, pkgs, ... }:

let nixos-hardware = builtins.fetchTarball https://github.com/NixOS/nixos-hardware/archive/master.tar.gz;
in {
  imports = [
    ./.  # import common settings

    # Hardware specific
    "${nixos-hardware}/dell/xps/13-9370"

    ./modules/desktop/bspwm.nix

    ./modules/audio/spotify.nix
    ./modules/browser/firefox.nix
    ./modules/dev
    ./modules/graphics/aseprite.nix
    ./modules/graphics/gimp.nix
    ./modules/editors/emacs.nix
    ./modules/editors/vim.nix
    ./modules/shell/direnv.nix
    ./modules/shell/git.nix
    ./modules/shell/gnupg.nix
    ./modules/shell/pass.nix
    ./modules/shell/zsh.nix
    # ./modules/video/obs.nix

    #
    ./modules/services/syncthing.nix

    # Themes
    ./themes/pianocat
  ];

  networking.hostName = "shiro";
  networking.wireless.enable = true;

  # Optimize power use
  environment.systemPackages = [ pkgs.acpi ];
  services.tlp.enable = true;
  powerManagement = {
    powertop.enable = true;
    cpuFreqGovernor = "ondemand";
  };

  # Monitor backlight control
  programs.light.enable = true;

  # Encrypted /home
  boot.initrd.luks.devices = [
    {
      name = "home";
      device = "/dev/nvme0n1p8";
      preLVM = true;
      allowDiscards = true;
    }
  ];
}
