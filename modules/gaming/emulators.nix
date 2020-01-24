{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    epsxe      # PSX
    desmume    # DS
  ];
}
