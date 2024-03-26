# modules/profiles/default.nix

{ self, lib, options, config, ... }:

with lib;
with self.lib;
{
  options.modules.profiles = with types; {
    user = mkOpt str "";
    role = mkOpt str "";
    platform = mkOpt str "";
    hardware = mkOpt (listOf str) [];
    networks = mkOpt (listOf str) [];
  };
}
