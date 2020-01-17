# hosts/personal.nix --- settings common to my personal systems

{ pkgs, ... }:
{
  imports = [ ./. ];

  environment.systemPackages = with pkgs; [
    # Support for more filesystems
    exfat
    ntfs3g
    hfsprogs
  ];

  # Nothing in /tmp should survive a reboot
  boot.tmpOnTmpfs = true;
  # Use simple bootloader; I prefer the on-demand BIOs boot menu
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  ### Universal defaults
  networking.firewall.enable = true;
  networking.hosts = {
    "192.168.1.2"  = [ "ao" ];
    "192.168.1.3"  = [ "aka" ];
    "192.168.1.10" = [ "kuro" ];
    "192.168.1.11" = [ "shiro" ];
    "192.168.1.12" = [ "midori" ];
  };


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
  # Conform more programs to XDG conventions. The rest are handled by their
  # respective modules.
  my.env = {
    __GL_SHADER_DISK_CACHE_PATH = "$XDG_CACHE_HOME/nv";
    CUDA_CACHE_PATH = "$XDG_CACHE_HOME/nv";
    HISTFILE = "$XDG_DATA_HOME/bash/history";
    INPUTRC = "$XDG_CACHE_HOME/readline/inputrc";
    LESSHISTFILE = "$XDG_CACHE_HOME/lesshst";
    WGETRC = "$XDG_CACHE_HOME/wgetrc";
  };
}
