{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.services.ssh;
in {
  options.modules.services.ssh = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      kbdInteractiveAuthentication = false;
      # Require keys over passwords. Ensure target machines are provisioned with
      # authorizedKeys!
      passwordAuthentication = false;
      # Then key-only access, it's safe to allow root, just don't give them keys
      # on machines you don't want root access to.
      permitRootLogin = true;
      # Suppress superfluous TCP traffic on new connections. Undo if using SSSD.
      extraConfig = ''GSSAPIAuthentication no'';
      # Deactive short moduli
      moduliFile = pkgs.runCommand "filterModuliFile" {} ''
        awk '$5 >= 3071' "${config.programs.ssh.package}/etc/ssh/moduli" >"$out"
      '';
      # Removes the default RSA key (not that it represents a vulnerability, per
      # se, but is one less key (that I don't plan to use) to the castle laying
      # around) and ensures the ed25519 key is generated with 100 rounds, rather
      # than the default (16), to better ensure its entropy.
      hostKeys = [
        {
          comment = "${config.networking.hostName}.local";
          path = "/etc/ssh/ssh_host_ed25519_key";
          rounds = 100;
          type = "ed25519";
        }
      ];
    };
  };
}
