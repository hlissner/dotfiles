{ config, options, lib, utils, pkgs, ... }:

with lib;
{
  imports = [ <home-manager/nixos> ];

  options.my = {
    username = mkOption {
      type = types.str;
      default = "hlissner";
    };

    home = mkOption {
      type = options.home-manager.users.type.functor.wrapped;
      default = {};
    };

    user = mkOption {
      type = types.submodule;
      default = {};
      description = "My users.users.NAME submodule";
    };

    env = mkOption {
      type = with types; attrsOf (either (either str path) (listOf (either str path)));
      default = {};
      description = "...";
      apply = mapAttrs
        (n: v: if isList v
               then concatMapStringsSep ":" (x: toString x) v
               else (toString v));
    };

    alias = mkOption {
      type = with types; nullOr (attrsOf (nullOr (either str path)));
      default = {};
      description = "...";
    };

    packages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "The set of packages to appear in the user environment.";
    };

    init = mkOption {
      type = types.lines;
      default = "";
      description = "...";
    };

    zsh = {
      rc = mkOption {
        type = types.lines;
        default = "";
        description = "...";
      };
      env = mkOption {
        type = types.lines;
        default = "";
        description = "...";
      };
    };
  };

  config = {
    users.users.${config.my.username} = mkAliasDefinitions options.my.user;
    home-manager.users.${config.my.username} = mkAliasDefinitions options.my.home;

    my.user.packages = config.my.packages;
    my.env.PATH = [ "$PATH" ];

    environment.shellAliases = config.my.alias;
    environment.extraInit =
      let exportLines = mapAttrsToList (n: v: "export ${n}=\"${v}\"") config.my.env;
      in ''
        ${concatStringsSep "\n" exportLines}
        ${config.my.init}
      '';

    my.home.xdg.configFile."zsh/extra.zshrc".text = config.my.zsh.rc;
    my.home.xdg.configFile."zsh/extra.zshenv".text = config.my.zsh.env;
  };
}
