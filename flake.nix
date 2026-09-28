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
      nixpkgs.follows = "hyprland/nixpkgs";
      agenix.url = "github:ryantm/agenix";
      agenix.inputs.nixpkgs.follows = "nixpkgs";

      # Desktop dependencies
      hyprland.url = "github:hyprwm/Hyprland";
      scroll-overview.url = "github:yayuuu/hyprland-scroll-overview/new-release";
      scroll-overview.inputs.hyprland.follows = "hyprland";
      scroll-overview.inputs.nixpkgs.follows = "nixpkgs";
      noctalia.url = "github:noctalia-dev/noctalia";
      noctalia.inputs.nixpkgs.follows = "nixpkgs";

      # Extras (imported directly by modules/hosts that need them)
      emacs-overlay.url = "github:nix-community/emacs-overlay";
      emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
      nixos-hardware.url = "github:nixos/nixos-hardware";
      llm-agents.url = "github:numtide/llm-agents.nix";
    };

  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"        # hyprland
      "https://noctalia.cachix.org"        # noctalia
      "https://nix-community.cachix.org"   # emacs-overlay
      "https://emacs-ci.cachix.org"        # emacs-overlay
      "https://cache.numtide.com"          # llm-agents
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "emacs-ci.cachix.org-1:B5FVOrxhXXrOL0S+tQ7USrhjMT5iOPH+QN9q0NItom4="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  outputs = inputs @ { self, nixpkgs, nixos-hardware, ... }:
    let
      lib = import ./lib {
        inherit self;
        inherit (nixpkgs) lib;
        pkgs = throw "flake.lib has no package set; use hey.lib from a host";
      };
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
