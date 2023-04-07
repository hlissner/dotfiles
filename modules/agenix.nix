# modules/agenix.nix -- encrypt secrets in nix store

{ self, lib, options, config, pkgs, ... }:

with builtins;
with lib;
let secretsDir  = "${self.hostDir}/secrets";
    secretsFile = "${secretsDir}/secrets.nix";
    hostKey = "/etc/ssh/host_ed25519";
in {
  imports = [ self.modules.agenix.age ];

  assertions = [
    {
      assertion = config.age.secrets == {} || pathExists hostKey;
      message = "Secrets provided, but host key is missing";
    }
  ];

  # This framework uses a separate host key for its secrets. It's expected to be
  # provisioned before the system is built (presumably with 'hey ops push-keys
  # $HOST' from a system with bitwarden set up).
  programs.ssh.extraConfig = ''
    Host *
      IdentityFile ${hostKey}
  '';

  # Ensure this hostkey is the default key used by agenix.
  environment.systemPackages = with pkgs; [
    # Respect XDG, damn it!
    (writeShellScriptBin "agenix" ''
      ARGS=( "$@" )
      ${optionalString config.xdg.ssh.enable ''
        if [[ "''${ARGS[*]}" != *"--identity"* && "''${ARGS[*]}" != *"-i"* ]]; then
          hostkey="${hostKey}"
          if [[ -f "$hostkey" ]]; then
            ARGS=( --identity "$hostkey" "''${ARGS[@]}" )
          fi
        fi
      ''}
      exec ${self.inputs.agenix.packages.x86_64-linux.default}/bin/agenix "''${ARGS[@]}"
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
    identityPaths = [ hostKey ];
  };
}
