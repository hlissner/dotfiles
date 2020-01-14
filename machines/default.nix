# ...

{ config, options, lib, pkgs, ... }:
{
  # Nothing in /tmp should survive a reboot
  boot.tmpOnTmpfs = true;
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


  ### Universal defaults
  networking.firewall.enable = true;

  ### A tidy $HOME is a tidy mind.
  # Obey XDG conventions;
  my.home.xdg.enable = true;
  environment.variables = {
    # These are the defaults, but some applications are buggy when these lack
    # explicit values.
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_CACHE_HOME  = "$HOME/.cache";
    XDG_DATA_HOME   = "$HOME/.local/share";
    XDG_BIN_HOME    = "$HOME/.local/bin";
  };

  # Conform more programs to XDG conventions. The rest are handle by their
  # respective modules.
  my.env = {
    __GL_SHADER_DISK_CACHE_PATH = "$XDG_CACHE_HOME/nv";
    CUDA_CACHE_PATH = "$XDG_CACHE_HOME/nv";
    HISTFILE = "$XDG_DATA_HOME/bash/history";
    INPUTRC = "$XDG_CACHE_HOME/readline/inputrc";
    LESSHISTFILE = "$XDG_CACHE_HOME/lesshst";
    WGETRC = "$XDG_CACHE_HOME/wgetrc";
  };

  # Prevents ~/.esd_auth files by disabling the esound protocol module for
  # pulseaudio, which I likely don't need. Is there a better way?
  hardware.pulseaudio.configFile =
    let paConfigFile =
          with pkgs; runCommand "disablePulseaudioEsoundModule"
            { buildInputs = [ pulseaudio ]; } ''
              mkdir "$out"
              cp ${pulseaudio}/etc/pulse/default.pa "$out/default.pa"
              sed -i -e 's|load-module module-esound-protocol-unix|# ...|' "$out/default.pa"
            '';
      in lib.mkIf config.hardware.pulseaudio.enable
        "${paConfigFile}/default.pa";
}
