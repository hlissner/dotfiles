# modules/hey.nix -- powering my binscripts
#
# ZSH and Janet are the powerhouses of my dotfiles. This module configures both
# for my scripting needs. Builds bin/hey.

{ hey, lib, options, config, pkgs, ... }:

with builtins;
with lib;
with hey.lib;
let cfg = config.hey;
    janet = pkgs.janet;

    heyPkg = hey.packages.hey;

    # My own janet tree, deliberately outside the store, so `jpm install` has
    # somewhere to put things.
    janetTreeDir = "${config.home.dataDir}/janet";

    # "10-foo" -> [ "10" "foo" ]; "foo" -> [ "50" "foo" ]
    splitHookName = name:
      let m = match "([0-9]{2})-(.+)" name; in
      if m == null then [ "50" name ] else m;
    hookNames = unique (map (n: elemAt (splitHookName n) 1)
                            (concatMap attrNames (attrValues cfg.hooks)));

    # { onFoo = { bar = "..."; }; } -> { "hey/hooks.d/bar.d/50-onFoo" = {...}; }
    hookFiles =
      concatMapAttrs
        (hook: scripts:
          mapAttrs'
            (name: script:
              let parts = splitHookName name; in
              nameValuePair "hey/hooks.d/${elemAt parts 1}.d/${head parts}-${hook}" {
                text = ''
                  #!/usr/bin/env zsh
                  ${script}
                '';
                # `hey hook` ignores non-executable scripts
                executable = true;
              })
            scripts)
        cfg.hooks;

    # Mirrors `wm` in lib/hey/lib.janet.
    wmDir = { hyprland = "hypr"; niri = "niri"; }.${cfg.desktop};
in {
  options.hey = with types; {
    desktop = mkOpt' (nullOr str) null
      "The desktop this system runs, naming the config/NAME hey looks in.";
    info = mkOpt' (attrsOf (pkgs.formats.json {}).type) {}
      "Facts about this system, for scripts to sniff at runtime.";
    hooks = mkOpt' (attrsOf (attrsOf lines)) {}
      "Zsh script fragments, as { HOOK = { NAME = script; } }, run by `hey hook`.";
    hookPaths = mkOpt' (listOf (coercedTo path toString str)) []
      "Directories `hey hook` searches for [NN-]HOOK scripts, in tie-break order.";
  };

  config = {
    # So systemd services in downstream modules/profiles can call hey without
    # dealing with PATH shenanigans.
    _module.args.heyBin = getExe heyPkg;

    environment.systemPackages = with pkgs; [
      heyPkg
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

    # For the global Janet ecosystem (separate from Hey's).
    #
    # janet makes the LAST JANET_PATH entry :syspath and searches it ahead of
    # every other, so mine goes last and wins. hey's own libraries are the
    # fallback behind it, there for the scripts hey dispatches to but doesn't
    # compile in (config/rofi/bin/*.janet). hey itself reads none of this; it's
    # a quickbin and carries its libraries inside.
    environment.sessionVariables = {
      JANET_TREE = janetTreeDir;
      JANET_PATH = "${heyPkg.janetLibs}:${janetTreeDir}/lib";
      JANET_BINPATH = "${janetTreeDir}/bin";
      JANET_LIBPATH = "${janet}/lib";
      JANET_HEADERPATH = "${janet}/include";
    };

    # Where lib/hey/lib.janet gets a usable PATH from, for hey invocations
    # in systemd units with no/incomplete $PATH.
    system.userActivationScripts.initHeyPath = ''
      mkdir -p "$XDG_DATA_HOME/hey"
      ${pkgs.zsh}/bin/zsh -c 'echo $PATH' >"$XDG_DATA_HOME/hey/path"
    '';

    # Let me know when Hey is rebuilt.
    system.activationScripts.heyVersion =
      let stamp = "/var/lib/hey/installed"; in ''
        if [ "$(cat ${stamp} 2>/dev/null)" != "${heyPkg}" ]; then
          printf '\033[32m✓ hey rebuilt:\033[0m %s\n' "${heyPkg}"
          mkdir -p "${dirOf stamp}"
          printf '%s\n' "${heyPkg}" >${stamp}
        fi
      '';


    # Setting PATH in both environment.{variables,sessionVariables} causes
    # merge-conflict errors, so do these separately.
    environment.extraInit = mkAfter ''
      export PATH="${janetTreeDir}/bin:$PATH:${hey.binDir}"
    '';

    programs.zsh.shellInit = mkBefore ''
      export DOTFILES_HOME="${hey.dir}"
      export fpath=( "${hey.libDir}/zsh" "${hey.libDir}/zsh/completions" "''${fpath[@]}" )
      autoload -Uz "''${fpath[1]}"/hey.*(.:t)
    '';

    environment.shellAliases.heyops = "hey ops";  # lazy fingers

    systemd.user.tmpfiles.rules = [
      "d ${janetTreeDir} 755 - - - -"
    ];

    hey.info.host = config.networking.hostName;
    hey.info.desktop = cfg.desktop;
    hey.info.profiles = config.modules.profiles;
    hey.info.hooks = cfg.hookPaths;

    hey.hookPaths = mkBefore (
      [ "${hey.dir}/hosts/${baseNameOf (toString hey.hostDir)}/hooks" ]
      ++ optional (cfg.desktop != null) "${hey.configDir}/${wmDir}/hooks"
      ++ map (n: "${config.home.dataDir}/hey/hooks.d/${n}.d") hookNames);

    home.dataFile = hookFiles // {
      "hey/info.json".text = toJSON cfg.info;
    };
  };
}
