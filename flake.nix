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
      # Hyprland is the pickiest thing in this stack and I want its fixes as
      # they land, so it gets to pin nixpkgs: the system follows the flake's
      # rather than the other way round. That's also what keeps
      # hyprland.cachix.org's hashes matching ours.
      hyprland.url = "github:hyprwm/Hyprland";
      nixpkgs.follows = "hyprland/nixpkgs";
      agenix.url = "github:ryantm/agenix";
      agenix.inputs.nixpkgs.follows = "nixpkgs";
      scroll-overview.url = "github:yayuuu/hyprland-scroll-overview/new-release";
      scroll-overview.inputs.hyprland.follows = "hyprland";
      scroll-overview.inputs.nixpkgs.follows = "nixpkgs";

      # Extras (imported directly by modules/hosts that need them)
      emacs-overlay.url = "github:nix-community/emacs-overlay";
      emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
      nixos-hardware.url = "github:nixos/nixos-hardware";
      noctalia.url = "github:noctalia-dev/noctalia";
      noctalia.inputs.nixpkgs.follows = "nixpkgs";
      llm-agents.url = "github:numtide/llm-agents.nix";
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
