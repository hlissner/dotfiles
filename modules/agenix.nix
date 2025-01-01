# modules/agenix.nix -- encrypt secrets in nix store

{ hey, lib, options, config, pkgs, ... }:

with builtins;
with lib;
with hey.lib;
let hostKey = "/etc/ssh/host_ed25519";
in {
  imports = [ hey.modules.agenix.age ];

  options.modules.agenix = with types; {
    dirs = mkOpt (listOf (either str path)) [
      "${hey.hostDir}/secrets"
      "${hey.configDir}/secrets"
    ];
  };

  config = {
    assertions = [
      {
        assertion =
          config.age.secrets == {} || (pathExists hostKey);
        message = "Secrets provided, but no host key was found";
      }
    ];

    # Each system gets a host key, used for decrypting Agenix secrets and as a
    # deployment key via Git. It's expected to be provisioned before the system
    # is initially installe (presumably with 'hey ops push-keys $HOST' from a
    # system with bitwarden set up).
    programs.ssh.extraConfig = ''
      Host *
        IdentityFile ${hostKey}
    '';

    # Ensure this hostkey is the default key used by agenix.
    environment.systemPackages = with pkgs; [
      # Respect XDG, damn it!
      (writeShellScriptBin "agenix" ''
        ARGS=( "$@" )
        ${optionalString config.modules.xdg.ssh.enable ''
          if [[ "''${ARGS[*]}" != *"--identity"* && "''${ARGS[*]}" != *"-i"* ]]; then
            for hostkey in "${hostKey}"; do
              if [[ -f "$hostkey" ]]; then
                ARGS=( --identity "$hostkey" "''${ARGS[@]}" )
              fi
            done
          fi
        ''}
        exec ${hey.inputs.agenix.packages.${system}.default}/bin/agenix "''${ARGS[@]}"
      '')
    ];

    age = {
      identityPaths = [ hostKey ];
      secrets = foldl (a: b: a // b) {}
        (map (dir: mapAttrs'
          (n: v: nameValuePair (removeSuffix ".age" n) {
            file = "${dir}/${n}";
            owner = mkDefault config.user.name;
          })
          (import "${dir}/secrets.nix"))
          (filter (dir: pathExists "${dir}/secrets.nix")
            config.modules.agenix.dirs));
    };
  };
}
