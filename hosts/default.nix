# hosts/default.nix --- settings common to all my systems

{ pkgs, ... }:
{
  # Just the bear necessities~
  environment.systemPackages = with pkgs; [
    coreutils
    git
    killall
    unzip
    vim
    wget
    sshfs
  ];


  ### My user settings
  my.username = "hlissner";
  my.env.PATH = [ ../bin ];
  my.user = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "video" "networkmanager" ];
    shell = pkgs.zsh;
  };
  my.alias.nix-env = "NIXPKGS_ALLOW_UNFREE=1 nix-env";
  my.alias.nsh = "nix-shell";
  my.alias.nen = "nix-env";
  my.alias.sc = "systemctl";
  my.alias.ssc = "sudo systemctl";
  my.alias.dots = "make -C ~/.dotfiles";
}
