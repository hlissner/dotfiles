# flake.nix --- the heart of my dotfiles
#
# Author:  Henrik Lissner <henrik@lissner.net>
# URL:     https://github.com/hlissner/dotfiles
# License: MIT
#
# Welcome to ground zero. Where the whole flake gets set up and all its modules
# are loaded.

{
  description = "A grossly incandescent nixos config.";

  inputs = 
    {
      # Core dependencies
      nixos.url          = "nixpkgs/nixos-20.09";
      nixos-unstable.url = "nixpkgs/nixos-unstable";
      home-manager.url   = "github:rycee/home-manager/master";
      home-manager.inputs.nixpkgs.follows = "nixos-unstable";

      # Extras
      emacs-overlay.url  = "github:nix-community/emacs-overlay";
      nixos-hardware.url = "github:nixos/nixos-hardware";
    };

  outputs = inputs @ { self, nixos, nixos-unstable, home-manager, ... }:
    let
      inherit (builtins) baseNameOf;
      inherit (lib) nixosSystem mkIf removeSuffix attrNames attrValues;
      inherit (lib.my) dotFilesDir mapModules mapModulesRec mapModulesRec';

      system = "x86_64-linux";

      lib = nixos.lib.extend
        (self: super: { my = import ./lib { inherit pkgs; lib = self; }; });

      mkPkgs = pkgs: extraOverlays: import pkgs {
        inherit system;
        config.allowUnfree = true;  # forgive me Stallman senpai
        overlays = extraOverlays ++ (attrValues self.overlays);
      };
      pkgs     = mkPkgs nixos [ self.overlay ];
      unstable = mkPkgs nixos-unstable [];
    in {
      overlay =
        final: prev: {
          inherit unstable;
          user = self.packages."${system}";
        };

      overlays =
        mapModules (toString ./overlays) import;

      packages."${system}" =
        mapModules (toString ./packages)
          (p: pkgs.callPackage p {});

      nixosModules =
        mapModulesRec (toString ./modules) import;

      nixosConfigurations =
        mapModules (toString ./hosts)
          (modulePath: nixosSystem {
            inherit system;
            specialArgs = { inherit lib inputs; };
            modules = [
              # Common config for all nixos machines; and to ensure the flake
              # operates soundly
              {
                networking.hostName = removeSuffix ".nix" (baseNameOf modulePath);
                environment.variables.NIXPKGS_ALLOW_UNFREE = "1";
                environment.variables.DOTFILES = dotFilesDir;
                nixpkgs.pkgs = pkgs;
                nix = {
                  package = unstable.nixFlakes;
                  extraOptions = "experimental-features = nix-command flakes";
                  nixPath = [
                    "nixpkgs=${nixos}"
                    "nixpkgs-unstable=${nixos-unstable}"
                    "nixpkgs-overlays=${dotFilesDir}/overlays"
                    "home-manager=${home-manager}"
                    "dotfiles=${dotFilesDir}"
                  ];
                  binaryCaches = [
                    "https://cache.nixos.org/"
                    "https://nix-community.cachix.org"
                  ];
                  binaryCachePublicKeys = [
                    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                  ];
                  registry = {
                    nixos.flake = nixos;
                    nixpkgs.flake = nixos-unstable;
                  };
                };
                system.configurationRevision = mkIf (self ? rev) self.rev;
                system.stateVersion = "20.09";
              }

              # I use home-manager to deploy files to $HOME; little else
              home-manager.nixosModules.home-manager

              # All my personal modules
              { imports = mapModulesRec' (toString ./modules) import; }

              ./hosts       # config common to all hosts
              modulePath    # host-specific config
            ];
          });
    };
}
