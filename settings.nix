{ config, options, lib, utils, pkgs, ... }:

with lib;
{
  imports = [
    <home-manager/nixos>
  ];

  options = {
    username = mkOption {
      type = types.str;
      default = "hlissner";
      description = "My username";
    };

    home = mkOption {
      type = options.home-manager.users.type.functor.wrapped;
      default = {};
      description = "Home-manager configuration for my user";
    };

    # TODO
    # paths = mkOption {
    #   type = types.listOf types.path;
    #   default = [];
    #   description = "Custom PATH entries";
    # };

    my = mkOption {
      type = types.listOf types.functor;
      default = [];
      description = "Nix config helpers";
    };
  };

  config = {
    home-manager.users = {
      ${config.username} = mkAliasDefinitions options.home;
    };

    # environment.extraInit = ''
    #   export PATH="${lib.concatStringsSep ":" (map builtins.toString config.paths)}:$PATH"
    # '';
  };
}
