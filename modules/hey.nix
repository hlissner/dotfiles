# modules/hey.nix -- powering my binscripts
#
# ZSH and Janet are the powerhouses of my dotfiles. This module configures both
# for my scripting needs (particularly by bin/hey).

{ hey, lib, options, config, pkgs, ... }:

with builtins;
with lib;
with hey.lib;
let cfg = config.hey;

    janet = pkgs.janet;
    jpmWrapped = mkWrapper pkgs.jpm ''
      wrapProgram $out/bin/jpm --add-flags '--tree="$JANET_TREE" --binpath="$XDG_BIN_HOME" --headerpath=${janet}/include --libpath=${janet}/lib'
    '';
    jpmPkg = if pkgs.stdenv.isDarwin then pkgs.jpm else jpmWrapped;
    janetTreeDir = "${config.home.dataDir}/janet/jpm_tree";
    isDarwin = pkgs.stdenv.isDarwin;
    heyWrapper = pkgs.writeShellScriptBin "hey" ''
      export JANET_PATH=${hey.libDir}:${janetTreeDir}/lib
      export JANET_TREE=${janetTreeDir}
      exec ${janet}/bin/janet ${hey.binDir}/hey "$@"
    '';
in {
  options = with types; {
    hey = {
      info = mkOpt (attrsOf attrs) {};
      hooks = mkOpt (attrsOf (attrsOf lines)) {};
    };
  };

  config = mkMerge [
    {
    # So systemd services in downstream modules/profiles can call hey without
    # dealing with PATH shenanigans.
    _module.args.heyBin = "${janet}/bin/janet ${hey.binDir}/hey";

    environment.systemPackages =
      [ heyWrapper janet jpmPkg pkgs.jq pkgs.git pkgs.zsh ]
      ++ optional (!isDarwin) pkgs.gcc
      ++ optional (!isDarwin) pkgs.cached-nix-shell
      ++ optional (!isDarwin) pkgs.bind
      ++ optional (!isDarwin) pkgs.dash
      ++ optional (!isDarwin) pkgs.wget
      ++ optional (!isDarwin) pkgs.nix-prefetch-git;

    environment.variables =
      {
        JANET_PATH = hey.libDir;
        JANET_TREE = hey.libDir;
      }
      // (optionalAttrs (!isDarwin) {
        JANET_PATH = mkForce "${janetTreeDir}/lib";
        JANET_TREE = mkForce janetTreeDir;
      });
  }

    (optionalAttrs (!isDarwin) {
      # Compile bin/hey to trivialize janet startup time
      # TODO: Include gcc for 'jpm deps'
      system.userActivationScripts.initHey = ''
        ${pkgs.zsh}/bin/zsh -c 'echo $PATH' >"$XDG_DATA_HOME/hey/path"

        export JANET_PATH="${janetTreeDir}/lib"
        export JANET_TREE="${janetTreeDir}"
        ${pkgs.zsh}/bin/zsh -c "cd '${hey.dir}'; jpm deps"
        ${pkgs.zsh}/bin/zsh -c "cd '${hey.dir}'; jpm run deploy"
      '';

      systemd.user.tmpfiles.rules = [
        "d %h/.local/share/janet/jpm_tree 755 - - - -"
      ];

      environment.sessionVariables = {
        JANET_PATH = "${janetTreeDir}/lib";
        JANET_TREE = janetTreeDir;
      };
    })

    (optionalAttrs isDarwin {
      environment.variables = {
        JANET_PATH = hey.libDir;
        JANET_TREE = hey.libDir;
      };
    })

    {
      programs.zsh.shellInit = mkBefore ''
        export DOTFILES_HOME="${hey.dir}"
        export fpath=( "${hey.libDir}/zsh" "''${fpath[@]}" )
        autoload -Uz "''${fpath[1]}"/hey.*(.:t)
      '';

      home.dataFile = {
        # This file is intended as a reference for shell scripts to peek into to
        # do cheap feature-detection (using `hey vars ...`)
        "hey/info.json".text = toJSON cfg.info;
      } //
      # FIXME: Refactor me?
      (listToAttrs
        (flatten
          (mapAttrsToList
            (hook: hooks: mapAttrsToList
              (n: v: nameValuePair
                (let filename =
                       if (match "^[0-9]{2}-.+" n) == null
                       then "50-${n}"
                       else n;
                 in "hey/hooks.d/${hook}.d/${filename}") {
                   text = ''
                     #!/usr/bin/env zsh
                     ${v}
                   '';
                   executable = true;
                 }) hooks)
            config.hey.hooks)));
    }
  ];
}
