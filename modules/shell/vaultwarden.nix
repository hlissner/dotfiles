{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.shell.vaultwarden;
    package = pkgs.unstable.bitwarden-cli;
in {
  options.modules.shell.vaultwarden = with types; {
    enable = mkBoolOpt false;
    settings = mkOpt attrs {};
  };

  config = mkIf cfg.enable {
    user.packages = [ package ];

    modules.shell.zsh.rcInit = ''
      hey.cache ${package}/bin/bw completion --shell zsh && compdef _bw bw;
    '';

    system.userActivationScripts = mkIf (cfg.settings != {}) {
      initVaultwarden = ''
        if command -v bw >/dev/null; then
          echo "Configuring bitwarden-cli..."
          ${concatStringsSep "\n"
            (mapAttrsToList (n: v: "bw config ${n} ${v}") cfg.settings)}
        fi
      '';
    };
  };
}
