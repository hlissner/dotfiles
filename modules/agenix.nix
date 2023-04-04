# modules/agenix.nix -- encrypt secrets in nix store

{ self, lib, options, config, pkgs, ... }:

with builtins;
with lib;
let secretsDir  = "${self.hostDir}/secrets";
    secretsFile = "${secretsDir}/secrets.nix";
in {
  imports = [ self.modules.agenix.age ];

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "agenix" ''
      exec nix run github:ryantm/agenix -- "$@"
    '')
  ];

  age = {
    secrets =
      if pathExists secretsFile
      then mapAttrs' (n: _: nameValuePair (removeSuffix ".age" n) {
        file = "${secretsDir}/${n}";
        owner = mkDefault config.user.name;
      }) (import secretsFile)
      else {};
    # If this system has secrets, identityPaths must be non-empty, but if no
    # host key has been provided, then it will fail, and it should. Loudly.
    identityPaths = filter pathExists [ "/etc/ssh/ssh_host_ed25519_key" ];
  };
}
