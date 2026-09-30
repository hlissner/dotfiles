# modules/services/guix.nix
#
# The superior package manager inside NixOS.

{ self, lib, config, options, ... }:

with lib;
with self.lib;
let cfg = config.modules.services.guix;
in {
  options.modules.services.guix = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.guix.enable = true;

      # Don't start guix at boot; use socket activation to lazily activate the
      # service, and keep it off when it's disabled.
      systemd.services.guix-daemon = {
        wantedBy = mkForce [];
        serviceConfig = {
          Restart = mkForce "no";
          RemainAfterExit = mkForce "no";
        };
      };

      environment.variables.PATH = [ "$XDG_CONFIG_HOME/guix/current/bin" ];
    }
  ]);
}
