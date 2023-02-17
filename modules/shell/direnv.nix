{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.shell.direnv;
in {
  options.modules.shell.direnv = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = [ pkgs.direnv ];
    modules.shell.zsh.rcInit = ''eval "$(direnv hook zsh)"'';
  };
}
