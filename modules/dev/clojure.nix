# modules/dev/clojure.nix --- https://clojure.org/
#
# I don't use clojure. Perhaps one day...

{ pkgs, ... }:
{
  my.packages = with pkgs; [
    clojure
    joker
    leiningen
  ];
}
