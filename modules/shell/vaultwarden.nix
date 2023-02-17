{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.shell.vaultwarden;
in {
  options.modules.shell.vaultwarden = with types; {
    enable = mkBoolOpt false;
    config = mkOpt attrs {};
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      bitwarden-cli
    ];

    modules.shell.zsh.rcInit = ''
      _cache bw completion --shell zsh && compdef _bw bw;
    '';

    system.userActivationScripts = mkIf (cfg.config != {}) {
      initVaultwarden = ''
        if command -v bw; then
          ${concatStringsSep "\n" (mapAttrsToList (n: v: "bw config ${n} ${v}") cfg.config)}
        fi
      '';
    };
  };
}
