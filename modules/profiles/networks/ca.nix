# modules/profiles/networks/ca.nix --- TODO

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
mkIf (elem "ca" config.modules.profiles.networks) {
  time.timeZone = "America/Toronto";
}
