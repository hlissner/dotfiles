# modules/profiles/default.nix

{ hey, lib, options, config, ... }:

with lib;
with hey.lib;
{
  options.modules.profiles = with types; {
    # Null, not "": these name a thing or they don't, and an empty string is a
    # value that quietly compares unequal to everything while still being a
    # string. Every consumer tests them with ==, which is null-safe.
    user = mkOpt (nullOr str) null;
    role = mkOpt (nullOr str) null;
    platform = mkOpt (nullOr str) null;
    hardware = mkOpt (listOf str) [];
    networks = mkOpt (listOf str) [];
  };

  config.hey.info.profiles = config.modules.profiles;
}
