{ hey, lib, config, pkgs, ... }:

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
    user.openssh.authorizedKeys.keys = [ key ];

    # Allow key-based root access only from private ranges.
    users.users.root.openssh.authorizedKeys.keys = [
      (if role == "workstation"
       then ''from="10.0.0.0/16,100.100.4.0/24,192.168.10.0/24" ${key} ${username}''
       else key)
    ];
  }

  (mkIf (role == "workstation") {
    environment.systemPackages = with pkgs; [
      cloudflared           # for authenticated ssh
    ];

    programs.ssh.extraConfig = ''
      Match originalhost git.henrik.io exec "nc -z -w1 10.0.0.1 22"
        Port 33014
        ProxyCommand none
      Host git.henrik.io
        User git
        ProxyCommand cloudflared access ssh --hostname %h

      Match originalhost dev.henrik.io exec "nc -z -w1 10.0.0.1 22"
        ProxyCommand none
      Host dev.henrik.io
        ProxyCommand cloudflared access ssh --hostname %h
    '';
  })
])
