# flake.nix --- the heart of my dotfiles
#
# Welcome to ground zero. Where the whole flake gets set up and all its modules
# are loaded.

{
  description = "A grossly incandescent nixos config.";

  inputs = 
    {
      # Core dependecies
      nixpkgs.follows = "niri/nixpkgs";
      agenix.url = "github:ryantm/agenix";
      agenix.inputs.nixpkgs.follows = "nixpkgs";

      # Desktop dependencies
      niri.url = "github:epireyn/niri-flake";
      niri.inputs.nixpkgs-stable.follows = "nixpkgs";  # for features I don't use
      noctalia.url = "github:noctalia-dev/noctalia/cachix";

      # Extras (imported directly by modules/hosts that need them)
      emacs-overlay.url = "github:nix-community/emacs-overlay";
      nixos-hardware.url = "github:nixos/nixos-hardware";
      llm-agents.url = "github:numtide/llm-agents.nix";
    };

  nixConfig = {
    extra-substituters = [
      "https://niri-epireyn.cachix.org"    # niri
      "https://noctalia.cachix.org"        # noctalia
      "https://nix-community.cachix.org"   # emacs-overlay
      "https://cache.numtide.com"          # llm-agents
    ];
    extra-trusted-public-keys = [
      "niri-epireyn.cachix.org-1:tlVyFN7CtsDT+ZcLPS+ekFWeT1X6X4OqvWqbBMyIzFA="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  outputs = inputs:
    with import ./lib { inherit (inputs.nixpkgs) lib; };
    mkFlake inputs {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      hosts = mapHosts ./hosts;
      modules.default = import ./.;

      apps.install = mkApp ./install.sh;
      devShells.default = import ./shell.nix;
      checks = mapModules ./test import;
      overlays = mapModules ./overlays import;
      packages = mapModules ./packages import;
    };
}
