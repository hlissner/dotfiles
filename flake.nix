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
      nixpkgs.url = "nixpkgs/nixos-unstable";  # primary nixpkgs
      nixpkgs-unstable.url = "nixpkgs/nixos-unstable";        # for packages on the edge
      home-manager.url = "github:rycee/home-manager/master";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";
      agenix.url = "github:ryantm/agenix";
      agenix.inputs.nixpkgs.follows = "nixpkgs";
      # disko.url = "github:nix-community/disko";
      # disko.inputs.nixpkgs.follows = "nixpkgs";

      # Extras (imported directly by modules/hosts that need them)
      blender-bin.url = "github:edolstra/nix-warez?dir=blender";
      blender-bin.inputs.nixpkgs.follows = "nixpkgs";
      emacs-overlay.url = "github:nix-community/emacs-overlay";
      emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
      nixos-hardware.url = "github:nixos/nixos-hardware";
    };

  outputs = inputs @ { self, nixpkgs, nixos-hardware, ... }:
    let
      args = { inherit self; inherit (nixpkgs) lib; };
      lib = import ./lib args;
    in
      with builtins; with lib; mkFlake inputs {
        inherit lib;
        systems = [ "x86_64-linux" "aarch64-linux" ];

        hosts = mapModules ./hosts import;
        modules.default = import ./.;

        profiles = mergeAttrs' [
          (mkProfiles ["hardware"] "${nixos-hardware}")
          (mkProfiles [] ./profiles)  # highest priority
        ];

        apps.default = mkApp ./bin/hey;
        devShells.default = import ./shell.nix;
        checks = mapModules ./test import;
        overlays = mapModules ./overlays import;
        packages = mapModules ./packages import;
        templates = import ./templates args;

        # I wanted to parameterize this flake (more so for flakes derived from
        # this one). To do so, I rely on bin/hey (my nix{,os} CLI/wrapper) to
        # emulate --arg/--argstr options. default.dir is special though, and
        # communicated using hey's -f/--flake and --host options:
        #
        #   hey rebuild -f /etc/nixos#soba
        #   hey rebuild -f /etc/nixos --host soba
        #
        # But it (and any other default.* attribute) can be set with
        # --arg/--argstr:
        #
        #   hey rebuild --arg dir /etc/nixos --arg host soba
        #
        # The magic that allows this lives in mkFlake, but requires --impure
        # mode. Sorry hermetic purists!
        _heyArgs =
          let args = getEnv "__HEYARGS"; in
          if args == "" then {} else fromJSON args;
      };
}
