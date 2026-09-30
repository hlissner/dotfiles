{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.shell.direnv;
in {
  options.modules.shell.direnv = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      # This deploys its init to /etc/zshrc, which runs before my .zshrc (and
      # unconditionally), interfering with my $DUMB/$EMACS terminal guard and
      # p10k's instant prompt feature. I'll just load it myself.
      enableZshIntegration = false;

      # Workaround for nix-community/nix-direnv#786
      # REVIEW: Remove when pkgs.direnv gets beyond 3.2.0
      direnvrcExtra = ''
        _nix_refresh_gcroots() { :; }
      '';
    };

    modules.shell.zsh.rcInit = ''
      eval "$(${getExe config.programs.direnv.package} hook zsh)"
    '';
  };
}
