# modules/profiles/default.nix

{ hey, lib, options, config, ... }:

with lib;
with hey.lib;
{
  options.modules.profiles = with types; {
    user = mkOpt str "";
    role = mkOpt str "";
    platform = mkOpt str "";
    hardware = mkOpt (listOf str) [];
    networks = mkOpt (listOf str) [];
  };

  config.hey.info.profiles = config.modules.profiles;
}
