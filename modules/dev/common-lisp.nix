# modules/dev/common-lisp.nix --- https://common-lisp.net/
#
# Mostly for the occasional dip into lisp gamedev.

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
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
      # Moves ~/.sbclrc to ~/.config/sbcl/rc
      environment.etc."sbclrc".text = ''
        (require :asdf)
        (setf db-ext:*userinit-pathname-function*
              (lambda () (uiop:xdg-config-home #P"sbcl/rc")))
      '';
    })
  ];
}
