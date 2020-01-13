{ config, lib, pkgs, ... }:
{
  my.packages = with pkgs; [
    clojure
    joker
    leiningen
  ];
}
