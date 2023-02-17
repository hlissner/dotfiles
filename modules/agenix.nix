# modules/agenix.nix -- encrypt secrets in nix store

{ self, lib, options, config, pkgs, ... }:

with builtins;
with lib;
with self.lib;
let secretsDir  = "${self.hostDir}/secrets";
    secretsFile = "${secretsDir}/secrets.nix";
in {
  imports = [ self.modules.agenix.age ];
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "agenix" ''
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
    identityPaths =
      options.age.identityPaths.default ++ (filter pathExists [
        "${config.user.home}/.ssh/id_ed25519"
        "${config.user.home}/.ssh/id_rsa"
      ]);
  };
}
