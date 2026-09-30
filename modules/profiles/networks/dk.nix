# modules/profiles/networks/dk.nix --- TODO

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
mkIf (elem "dk" config.modules.profiles.networks) {
  time.timeZone = "Europe/Copenhagen";
}
