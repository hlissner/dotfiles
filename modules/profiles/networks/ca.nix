# modules/profiles/networks/ca.nix --- TODO

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
mkIf (elem "ca" config.modules.profiles.networks) {
  time.timeZone = "America/Toronto";
}
