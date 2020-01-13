# ...

{ config, lib, pkgs, ... }:
{
  # Nothing in /tmp should survive a reboot
  boot.cleanTmpDir = true;
  # Use simple bootloader; I prefer the on-demand BIOs boot menu
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Just the bear necessities~
  environment.systemPackages = with pkgs; [
    coreutils
    git
    killall
    unzip
    vim
    wget
    # Support for extra filesystems
    sshfs
    exfat
    ntfs3g
    hfsprogs
    # cached-nix-shell, for instant nix-shell scripts
    (callPackage
      (builtins.fetchTarball
        https://github.com/xzfc/cached-nix-shell/archive/master.tar.gz) {})
  ];

  ###
  # My user settings
  my = {
    username = "hlissner";
    env.PATH = [ <my/bin> ];
    user = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = [ "wheel" "video" "networkmanager" ];
      shell = pkgs.zsh;
    };
  };

  # Obey XDG conventions; a tidy $HOME is a tidy mind.
  my.home.xdg.enable = true;
  environment.variables = {
    # These are the defaults, but some applications are buggy when these lack
    # explicit values.
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_BIN_HOME = "$HOME/.local/bin";
  };

  ### Universal defaults
  networking.firewall.enable = true;
}
