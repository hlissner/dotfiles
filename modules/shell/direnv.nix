{ config, lib, pkgs, ... }:

{
  services.lorri.enable = true;

  my = {
    packages = [ pkgs.direnv ];
    zsh.rc = "_cache direnv hook zsh";
  };
}
