# Common configuration across systems. This should be required by
# configuration.$HOSTNAME.nix files.

{ config, pkgs, options, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    <home-manager/nixos>
  ];

  nix = {
    nixPath = options.nix.nixPath.default ++ [
      "config=/etc/dotfiles/config"
      "packages=/etc/dotfiles/packages"
    ];
    autoOptimiseStore = true;
    trustedUsers = [ "root" "@wheel" ];
  };
  nixpkgs.config = {
    # Forgive me Stallman senpai
    allowUnfree = true;

    packageOverrides = pkgs: {
      unstable = import <nixpkgs-unstable> {
        config = config.nixpkgs.config;
      };
    };
  };

  # Nothing in /tmp should survive a reboot
  boot.cleanTmpDir = true;
  # Use simple bootloader; I prefer the on-demand BIOs boot menu
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment = {
    systemPackages = with pkgs; [
      # Just the bear necessities~
      libqalculate
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
    ];
    # These are the defaults, but some applications are buggy when these lack
    # explicit values.
    variables = {
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_BIN_HOME = "$HOME/.local/bin";
    };
  };

  location = (if config.time.timeZone == "America/Toronto" then {
    latitude = 43.70011;
    longitude = -79.4163;
  } else if config.time.timeZone == "Europe/Copenhagen" then {
    latitude = 55.88;
    longitude = 12.5;
  } else {});

  # Set up hlissner user account
  users.users.hlissner = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "video" "networkmanager" "vboxusers" ];
    shell = pkgs.zsh;
  };

  home-manager.users.hlissner = {
    xdg.enable = true;
    home.file."bin" = { source = ./bin; recursive = true; };
  };

  networking.firewall.enable = true;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?
}
