# modules/dev/common-lisp.nix --- https://common-lisp.net/
#
# Mostly for my stumpwm config, and the occasional dip into lisp gamedev.

{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.dev.common-lisp;
in {
  options.modules.dev.common-lisp = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      sbcl
      lispPackages.quicklisp
    ];
  };
}
