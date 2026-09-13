# modules/profiles/networks/dk.nix --- TODO

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
mkIf (elem "dk" config.modules.profiles.networks) {
  time.timeZone = "Europe/Copenhagen";
}
