# flake.nix --- the heart of my dotfiles
#
# Author:  Henrik Lissner <contact@henrik.io>
# URL:     https://github.com/hlissner/dotfiles
# License: MIT
#
# Welcome to ground zero. Where the whole flake gets set up and all its modules
# are loaded.

{
  description = "A grossly incandescent nixos config.";

  inputs = 
    {
      # Core dependecies
      nixpkgs.url = "nixpkgs/nixos-25.11";
      nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
      home-manager.url = "github:nix-community/home-manager/release-25.11";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";
      agenix.url = "github:ryantm/agenix";
      agenix.inputs.nixpkgs.follows = "nixpkgs";

      # Extras (imported directly by modules/hosts that need them)
      dms.url = "github:AvengeMedia/DankMaterialShell";
      dms.inputs.nixpkgs.follows = "nixpkgs-unstable";
      emacs-overlay.url = "github:nix-community/emacs-overlay";
      emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
      nixos-hardware.url = "github:nixos/nixos-hardware";
    };

  outputs = inputs @ { self, nixpkgs, nixpkgs-unstable, nixos-hardware, ... }:
    let
      args = {
        inherit self;
        inherit (nixpkgs) lib;
        pkgs = import nixpkgs {};
      };
      lib = import ./lib args;
    in
      with builtins; with lib; mkFlake inputs {
        systems = [ "x86_64-linux" "aarch64-linux" ];
        inherit lib;

        hosts = mapHosts ./hosts;
        modules.default = import ./.;

        apps.install = mkApp ./install.zsh;
        devShells.default = import ./shell.nix;
        checks = mapModules ./test import;
        overlays = mapModules ./overlays import;
        packages = mapModules ./packages import;
        # templates = import ./templates args;
      };
}
