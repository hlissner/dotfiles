{ config, options, lib, pkgs, ... }:

with lib;
{
  options.modules.shell.direnv = {
    enable = mkOption { type = types.bool; default = false; };
  };

  config = mkIf config.modules.shell.direnv.enable {
    my = {
      packages = [ pkgs.direnv ];
      zsh.rc = "_cache direnv hook zsh";
    };

    services.lorri.enable = true;
  };
}
