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
      nixpkgs-darwin.url = "nixpkgs/nixpkgs-25.11-darwin";
      home-manager.url = "github:nix-community/home-manager/release-25.11";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";
      darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
      agenix.url = "github:ryantm/agenix";
      agenix.inputs.nixpkgs.follows = "nixpkgs";
      disko.url = "github:nix-community/disko";
      disko.inputs.nixpkgs.follows = "nixpkgs";

      # Hyprland + core extensions
      # hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
      # hyprland.inputs.nixpkgs.follows = "nixpkgs";
      # hyprlock.url = "github:hyprwm/Hyprlock";
      # hyprlock.inputs.nixpkgs.follows = "nixpkgs-unstable";

      # Extras (imported directly by modules/hosts that need them)
      # hyprpicker.url = "github:hyprwm/hyprpicker";
      # hyprpicker.inputs.nixpkgs.follows = "nixpkgs-unstable";
      caelestia-shell.url = "github:caelestia-dots/shell";
      caelestia-shell.inputs.nixpkgs.follows = "nixpkgs-unstable";
      blender-bin.url = "github:edolstra/nix-warez?dir=blender";
      blender-bin.inputs.nixpkgs.follows = "nixpkgs-unstable";
      emacs-overlay.url = "github:nix-community/emacs-overlay";
      emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
      nixos-hardware.url = "github:nixos/nixos-hardware";

      # nix-ld
      nix-ld.url = "github:Mic92/nix-ld";
      # this line assume that you also have nixpkgs as an input
      nix-ld.inputs.nixpkgs.follows = "nixpkgs";

      nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

      # Zen is not exposed by the pinned nixpkgs/unstable set, so keep the
      # browser source narrow rather than promoting another browser baseline.
      zen-browser.url = "github:0xc000022070/zen-browser-flake";
      zen-browser.inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

  outputs = inputs @ { self, nixpkgs, nixpkgs-unstable, nixos-hardware, ... }:
    let
      detectSystem =
        let
          inherit (nixpkgs.lib.strings) hasInfix toLower;
          envSystem = builtins.getEnv "NIX_SYSTEM";
          envHost = toLower (builtins.getEnv "HOSTTYPE");
          envOs = toLower (builtins.getEnv "OSTYPE");
          isDarwin = hasInfix "darwin" envOs;
          isArm = hasInfix "arm" envHost || hasInfix "aarch64" envHost;
        in
          if builtins ? currentSystem then builtins.currentSystem
          else if envSystem != "" then envSystem
          else if isDarwin then (if isArm then "aarch64-darwin" else "x86_64-darwin")
          else if isArm then "aarch64-linux"
          else "x86_64-linux";

      args = {
        inherit self;
        inherit (nixpkgs) lib;
        pkgs = import nixpkgs { system = detectSystem; };
      };
      lib = import ./lib args;
    in
      with builtins; with lib; mkFlake inputs {
        systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
        inherit lib;

        hosts = mapHosts ./hosts;
        modules = {
          nixos.default = import ./.;
          darwin.default = import ./darwin;
        };

        apps.install = mkApp ./install.zsh;
        devShells.default = import ./shell.nix;
        checks = mapModules ./test import;
        overlays = mapModules ./overlays import;
        packages = mapModules ./packages import;
        # templates = import ./templates args;
      };
}
