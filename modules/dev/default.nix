# modules/dev --- common settings for dev modules

{ pkgs, ... }:
{
  imports = [
    ./cc.nix
    ./clojure.nix
    ./common-lisp.nix
    ./godot.nix
    # ./haskell.nix
    # ./latex.nix
    ./lua.nix
    ./node.nix
    ./python.nix
    ./rust.nix
    ./scala.nix
    ./unity3d.nix
    ./zsh.nix
  ];

  options = {};
  config = {};
}
