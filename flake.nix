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
      nixpkgs.url = "nixpkgs/nixos-24.05";
      nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
      home-manager.url = "github:nix-community/home-manager/release-24.05";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";
      agenix.url = "github:ryantm/agenix";
      agenix.inputs.nixpkgs.follows = "nixpkgs";
      # TODO: Declarative partitions
      # disko.url = "github:nix-community/disko";
      # disko.inputs.nixpkgs.follows = "nixpkgs";

      # Hyprland + core extensions
      hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
      hyprland.inputs.nixpkgs.follows = "nixpkgs-unstable";
      hyprlock.url = "github:hyprwm/Hyprlock";
      hyprlock.inputs.nixpkgs.follows = "nixpkgs-unstable";
      # hypridle.url = "github:hyprwm/hypridle";
      # hypridle.inputs.nixpkgs.follows = "nixpkgs-unstable";
      waybar.url = "github:Alexays/Waybar";
      waybar.inputs.nixpkgs.follows = "nixpkgs-unstable";

      # Extras (imported directly by modules/hosts that need them)
      spicetify-nix.url = "github:Gerg-L/spicetify-nix";
      spicetify-nix.inputs.nixpkgs.follows = "nixpkgs-unstable";
      hyprpicker.url = "github:hyprwm/hyprpicker";
      hyprpicker.inputs.nixpkgs.follows = "nixpkgs-unstable";
      blender-bin.url = "github:edolstra/nix-warez?dir=blender";
      blender-bin.inputs.nixpkgs.follows = "nixpkgs-unstable";
      emacs-overlay.url = "github:nix-community/emacs-overlay";
      emacs-overlay.inputs.nixpkgs.follows = "nixpkgs-unstable";
      emacs-overlay.inputs.nixpkgs-stable.follows = "nixpkgs";
      nixos-hardware.url = "github:nixos/nixos-hardware";
    };

  outputs = inputs @ { self, nixpkgs, nixos-hardware, ... }:
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
