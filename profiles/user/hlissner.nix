{ self, lib, config, ... }:

with lib;
let pr = config.profiles.active;
in mkMerge [
  {
    user.name = "hlissner";
    i18n.defaultLocale = mkDefault "en_US.UTF-8";
    modules.shell.vaultwarden.config.server = "vault.home.lissner.net";

    # Use more restrictive SSH access to workstations, which I only, ever, need
    # local access to. Other systems, particularly servers, are always on
    # controlled networks. There, I leave access control to the upstream router
    # or local firewall.
    user.openssh.authorizedKeys.keys = [
      (let key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB71rSnjuC06Qq3NLXQJwSz7jazoB+umydddrxL6vg1a";
       in if (elem "role/workstation" pr)
          then ''from="10.0.0.0/12" ${key}''
          else key)
    ];
  }

  # (mkIf (elem "role/server" pr) {

  # })
]
