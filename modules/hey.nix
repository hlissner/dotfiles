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
    jpm = pkgs.jpm;
    janetTreeDir = "${config.home.dataDir}/janet/jpm_tree";
in {
  options = with types; {
    hey = {
      info = mkOpt (attrsOf attrs) {};
      hooks = mkOpt (attrsOf (attrsOf lines)) {};
    };
  };

  config = {
    # So systemd services in downstream modules/profiles can call hey without
    # dealing with PATH shenanigans.
    _module.args.heyBin = "${janet}/bin/janet ${hey.binDir}/hey";

    environment.systemPackages = with pkgs; [
      gcc
      janet
      jpm
      jq
      bind
      cached-nix-shell
      nix-prefetch-git
      dash
      file
      git
      wget
      zsh
    ];

    environment.sessionVariables = {
      JANET_TREE = janetTreeDir;
      JANET_PATH = "${janetTreeDir}/lib";
      JANET_LIBPATH = "${janet}/lib";
      JANET_HEADERPATH = "${janet}/include";
      JANET_BINPATH = "${config.home.binDir}";
    };

    # Compile bin/hey to trivialize janet startup time. And no, I don't want
    # this to be done in /nix/store, because I tinker with 'hey' too often.
    system.activationScripts.initHey =
      # TODO: Use pkgs.buildEnv instead
      let script = pkgs.writeShellScript "initHey" ''
            export PATH="${pkgs.gcc}/bin:${janet}/bin:${jpm}/bin:$PATH"
            export DOTFILES_HOME="${hey.dir}"
            export XDG_RUNTIME_DIR="/run/user/${toString config.user.uid}"
            export XDG_BIN_HOME="${config.home.binDir}"
            export XDG_CACHE_HOME="${config.home.cacheDir}"
            export XDG_CONFIG_HOME="${config.home.configDir}"
            export XDG_DATA_HOME="${config.home.dataDir}"
            export XDG_STATE_HOME="${config.home.stateDir}"
            export JANET_TREE="${janetTreeDir}"
            export JANET_PATH="${janetTreeDir}/lib";
            export JANET_LIBPATH="${janet}/lib";
            export JANET_HEADERPATH="${janet}/include";
            export JANET_BINPATH="${config.home.binDir}";
            mkdir -p "$JANET_TREE"
            cd '${hey.dir}'
            jpm deps --verbose
            jpm run deploy --verbose
          '';
      in ''
        runuser -u ${config.user.name} -- ${script}
      '';

    # Setting PATH in both environment.{variables,sessionVariables} causes
    # merge-conflict errors, so do these separately.
    environment.extraInit = mkAfter ''
      export PATH="${janetTreeDir}/bin:${hey.binDir}:$PATH"
    '';

    programs.zsh.shellInit = mkBefore ''
      export DOTFILES_HOME="${hey.dir}"
      export fpath=( "${hey.libDir}/zsh" "''${fpath[@]}" )
      autoload -Uz "''${fpath[1]}"/hey.*(.:t)
    '';

    systemd.user.tmpfiles.rules = [
      "d %h/.local/share/janet/jpm_tree 755 - - - -"
    ];

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
  };
}
