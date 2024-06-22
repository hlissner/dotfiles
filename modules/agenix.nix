# modules/agenix.nix -- encrypt secrets in nix store

{ self, lib, options, config, pkgs, ... }:

with builtins;
with lib;
let secretDirs = [ "${self.hostDir}/secrets" "${self.configDir}/secrets" ];
    hostKey = "/etc/ssh/host_ed25519";
    globalKey = "/etc/ssh/global_ed25519";
in {
  imports = [ self.modules.agenix.age ];

  assertions = [
    {
      assertion =
        config.age.secrets == {} || (all pathExists [ hostKey globalKey ]);
      message = "Secrets provided, but a host key is missing";
    }
  ];

  # This framework uses two separate keys for its secrets. It's expected that
  # they're provisioned before the system is built (presumably with 'hey ops
  # push-keys $HOST' from a system with bitwarden set up).
  programs.ssh.extraConfig = ''
    Host *
      IdentityFile ${hostKey}
      IdentityFile ${globalKey}
  '';

  # Ensure this hostkey is the default key used by agenix.
  environment.systemPackages = with pkgs; [
    # Respect XDG, damn it!
    (writeShellScriptBin "agenix" ''
      ARGS=( "$@" )
      ${optionalString config.modules.xdg.ssh.enable ''
        if [[ "''${ARGS[*]}" != *"--identity"* && "''${ARGS[*]}" != *"-i"* ]]; then
          for hostkey in "${hostKey}" "${globalKey}"; do
            if [[ -f "$hostkey" ]]; then
              ARGS=( --identity "$hostkey" "''${ARGS[@]}" )
            fi
          done
        fi
      ''}
      exec ${self.inputs.agenix.packages.${system}.default}/bin/agenix "''${ARGS[@]}"
    '')
  ];

  age = {
    identityPaths = [ hostKey globalKey ];
    secrets = foldl (a: b: a // b) {}
      (map (dir: mapAttrs'
        (n: v: nameValuePair (removeSuffix ".age" n) {
          file = "${dir}/${n}";
          owner = mkDefault config.user.name;
        })
        (import "${dir}/secrets.nix"))
        (filter (dir: pathExists "${dir}/secrets.nix") secretDirs));
  };
}
