# profiles/hardware/pc/laptop.nix ---
#
# TODO

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let hardware = config.modules.profiles.hardware;
in mkMerge [
  (mkIf (any (s: hasPrefix "pc/laptop" s) hardware) {
    user.packages = with pkgs; [
      brightnessctl  # instead of programs.light
      acpi
    ];
  })
]
