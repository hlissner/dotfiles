# modules/hardware/razer.nix --- support for razer devices

{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.hardware.razer;
in {
  options.modules.hardware.razer = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hardware.openrazer.enable = true;

    user.extraGroups = [ "plugdev" ];

    environment.systemPackages = with pkgs; [
      # TODO Install polychromatic
    ];
  };
}
