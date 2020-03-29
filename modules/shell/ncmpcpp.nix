{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.shell.ncmpcpp = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.shell.ncmpcpp.enable {
    my.packages = with pkgs; [
      (ncmpcpp.override { visualizerSupport = true; })
    ];

    my.alias.rate = "mpd-rate";
    my.alias.mpcs = "mpc search any";
    my.alias.mpcsp = "mpc searchplay any";

    my.env.NCMPCPP_HOME = "$XDG_CONFIG_HOME/ncmpcpp";

    # Symlink these one at a time because ncmpcpp writes other files to
    # ~/.config/ncmpcpp, so it needs to be writeable.
    my.home.xdg.configFile = {
      "ncmpcpp/config".source = <config/ncmpcpp/config>;
      "ncmpcpp/bindings".source = <config/ncmpcpp/bindings>;
    };
  };
}
