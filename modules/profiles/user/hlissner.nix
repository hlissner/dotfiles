{ hey, lib, config, ... }:

with lib;
let cfg = config.modules.profiles;
    username = cfg.user;
    role = cfg.role;
    key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB71rSnjuC06Qq3NLXQJwSz7jazoB+umydddrxL6vg1a";
in mkIf (username == "hlissner") (mkMerge [
  {
    user.name = username;
    user.description = "Henrik";
    i18n.defaultLocale = mkDefault "en_US.UTF-8";
    modules.shell.vaultwarden.settings.server = "vault.home.lissner.net";

    # Be slightly more restrictive about SSH access to workstations, which I
    # only need LAN access to, if ever. Other systems, particularly servers, are
    # remoted into often, so I leave their access control to an upstream router
    # or local firewall.
    user.openssh.authorizedKeys.keys = [
      (if role == "workstation"
       then ''from="10.0.0.0/8" ${key} ${username}''
       else key)
    ];

    # Allow key-based root access only from private ranges.
    users.users.root.openssh.authorizedKeys.keys = [
      ''from="10.0.0.0/8" ${key} ${username}''
    ];
  }
])
