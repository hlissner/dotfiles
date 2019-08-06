{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gnupg
    pinentry
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
