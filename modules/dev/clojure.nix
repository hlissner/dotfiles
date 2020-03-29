# modules/dev/clojure.nix --- https://clojure.org/
#
# I don't use clojure. Perhaps one day...

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.dev.clojure = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.dev.clojure.enable {
    my.packages = with pkgs; [
      clojure
      joker
      leiningen
    ];
  };
}
