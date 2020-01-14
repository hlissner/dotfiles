{ config, options, lib, utils, pkgs, ... }:

with lib;
{
  imports = [ <home-manager/nixos> ];

  options.my = {
    username = mkOption {
      type = types.str;
      default = "hlissner";
    };

    email = mkOption {
      type = types.str;
      default = "henrik@lissner.net";
    };

    home = mkOption {
      type = options.home-manager.users.type.functor.wrapped;
      default = {};
      description = "A convenience alias for home-manager.users.{my.username}.";
    };

    user = mkOption {
      type = types.submodule;
      default = {};
      description = "A convenience alias for users.users.{my.username}.";
    };

    env = mkOption {
      type = with types; attrsOf (either (either str path) (listOf (either str path)));
      default = {};
      description = ''
        An map of environment variables that are set later than
        environment.variables or environment.sessionVariables. This is insurance
        that XDG variables (and other essentials) are initialized by the time
        these are set.
      '';
      apply = mapAttrs
        (n: v: if isList v
               then concatMapStringsSep ":" (x: toString x) v
               else (toString v));
    };

    alias = mkOption {
      type = with types; nullOr (attrsOf (nullOr (either str path)));
      default = {};
      description = "Shell-independent aliases for interactive shells.";
    };

    packages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "The set of packages to appear in the user environment.";
    };

    init = mkOption {
      type = types.lines;
      default = "";
      description = ''
        An init script that runs after the environment has been rebuilt or
        booted. Anything done here should be idempotent and inexpensive.
      '';
    };

    zsh = {
      rc = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Zsh lines to be written to $XDG_CONFIG_HOME/zsh/extra.zshrc and
          sourced by $XDG_CONFIG_HOME/zsh/.zshrc
        '';
      };
      env = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Zsh lines to be written to $XDG_CONFIG_HOME/zsh/extra.zshenv and
          sourced by $XDG_CONFIG_HOME/zsh/.zshenv
        '';
      };
    };
  };

  config = {
    users.users.${config.my.username} = mkAliasDefinitions options.my.user;
    home-manager.users.${config.my.username} = mkAliasDefinitions options.my.home;

    my.user.packages = config.my.packages;
    my.env.PATH = [ "$PATH" ];

    environment.extraInit =
      let exportLines = mapAttrsToList (n: v: "export ${n}=\"${v}\"") config.my.env;
      in ''
        ${concatStringsSep "\n" exportLines}
        ${config.my.init}
      '';

    my.home.xdg.configFile."zsh/extra.zshrc".text =
      let aliasLines = mapAttrsToList (n: v: "alias ${n}=\"${v}\"") config.my.alias;
      in ''
         ${concatStringsSep "\n" aliasLines}
         ${config.my.zsh.rc}
      '';
    my.home.xdg.configFile."zsh/extra.zshenv".text = config.my.zsh.env;
  };
}
