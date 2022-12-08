{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.profiles.users.hlissner;
in {
  options.profiles.users.hlissner = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      time.timeZone = mkDefault "America/Toronto";
      i18n.defaultLocale = mkDefault "en_US.UTF-8";

      # So the vaultwarden CLI knows where to find my server.
      modules.shell.vaultwarden.config.server = "vault.lissner.net";

      # Only allow local SSH access over the VPN or trusted local machines.
      user.openssh.authorizedKeys.keys = [
        ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB71rSnjuC06Qq3NLXQJwSz7jazoB+umydddrxL6vg1a hlissner''
      ];
    }
  ]);
}
