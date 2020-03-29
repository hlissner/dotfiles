# modules/dev/common-lisp.nix --- https://common-lisp.net/
#
# Mostly for my stumpwm config, and the occasional dip into lisp gamedev.

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.dev.common-lisp = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.dev.common-lisp.enable {
    my.packages = with pkgs; [
      sbcl
      lispPackages.quicklisp
    ];
  };
}
