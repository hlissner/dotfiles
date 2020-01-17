{ config, lib, pkgs, ... }:

{
  my.packages = with pkgs; [
    (ncmpcpp.override { visualizerSupport = true; })
  ];

  my.env.MPD_HOME = "$XDG_CONFIG_HOME/mpd";
  my.env.NCMPCPP_HOME = "$XDG_CONFIG_HOME/ncmpcpp";

  my.alias.rate = "mpd-rate";
  my.alias.mpcs = "mpc search any";
  my.alias.mpcsp = "mpc searchplay any";

  my.home.xdg.configFile = {
    "ncmpcpp/config".source = <config/ncmpcpp/config>;
    "ncmpcpp/bindings".source = <config/ncmpcpp/bindings>;
  };
}
