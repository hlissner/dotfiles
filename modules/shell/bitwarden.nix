{ config, options, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.bitwarden;
in {
  options.modules.shell.bitwarden = with types; {
    enable = mkBoolOpt false;
    config = mkOpt attrs {};
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      bitwarden-cli
    ];

    modules.shell.zsh.rcInit = "_cache bw completion --shell zsh; compdef _bw bw;";

    system.userActivationScripts = mkIf (cfg.config != {}) {
      initBitwarden = ''
        ${concatStringsSep "\n" (mapAttrsToList (n: v: "bw config ${n} ${v}") cfg.config)}
      '';
    };
  };
}
