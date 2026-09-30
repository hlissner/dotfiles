# profiles/hardware/pc/laptop.nix ---
#
# TODO

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
let hardware = config.modules.profiles.hardware;
in mkMerge [
  (mkIf (any (s: hasPrefix "pc/laptop" s) hardware) {
    # Noctalia reads battery state from UPower over DBus
    services.upower.enable = true;

    user.packages = with pkgs; [
      brightnessctl  # instead of programs.light
      acpi
    ];
  })
]
