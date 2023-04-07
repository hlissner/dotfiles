{ self, lib, config, ... }:

with lib;
mkMerge [
  {
    user.name = "hlissner";
    i18n.defaultLocale = mkDefault "en_US.UTF-8";
    modules.shell.vaultwarden.config.server = "vault.lissner.net";

    # Be slightly more restrictive about SSH access to workstations, which I
    # only ever need LAN access to. Other systems, particularly servers, are
    # remoted into, and I can leave access control to the upstream router or
    # local firewall.
    user.openssh.authorizedKeys.keys = [
      (let key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB71rSnjuC06Qq3NLXQJwSz7jazoB+umydddrxL6vg1a hlissner"; in
       if (elem "role/workstation" config.profiles.active)
       then ''from="10.0.0.0/8" ${key} hlissner''
       else key)
    ];
  }

  # (mkIf (elem "role/server" pr) {

  # })
]
