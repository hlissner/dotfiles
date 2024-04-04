# modules/dev/ruby.nix --- ...
#
# TODO

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let devCfg = config.modules.dev;
    cfg = devCfg.ruby;
in {
  options.modules.dev.ruby = {
    enable = mkBoolOpt false;
    xdg.enable = mkBoolOpt devCfg.xdg.enable;
  };

  config = mkMerge [
    (mkIf cfg.enable {
      user.packages = [ pkgs.ruby_3_2 ];
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
