# modules/dev/common-lisp.nix --- https://common-lisp.net/
#
# Mostly for my stumpwm config, and the occasional dip into lisp gamedev.

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let devCfg = config.modules.dev;
    cfg = devCfg.common-lisp;
in {
  options.modules.dev.common-lisp = {
    enable = mkBoolOpt false;
    xdg.enable = mkBoolOpt devCfg.xdg.enable;
  };

  config = mkMerge [
    (mkIf cfg.enable {
      user.packages = with pkgs; [
        sbcl
        lispPackages.quicklisp
      ];
    })

    (mkIf cfg.xdg.enable {
      # TODO
    })
  ];
}
