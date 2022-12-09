# modules/dev/ruby.nix --- ...
#
# TODO

{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let devCfg = config.modules.dev;
    cfg = devCfg.ruby;
in {
  options.modules.dev.ruby = {
    enable = mkBoolOpt false;
    xdg.enable = mkBoolOpt devCfg.xdg.enable;
  };

  config = mkMerge [
    (mkIf cfg.enable {
      user.packages = [ pkgs.ruby_3_1 ];
      environment.shellAliases = {
        rb = "ruby";
      };
    })

    (mkIf cfg.xdg.enable {
      env.BUNDLE_USER_CACHE = "$XDG_CACHE_HOME/bundle";
      env.BUNDLE_USER_CONFIG = "$XDG_CONFIG_HOME/bundle";
      env.BUNDLE_USER_PLUGIN = "$XDG_DATA_HOME/bundle";
    })
  ];
}
