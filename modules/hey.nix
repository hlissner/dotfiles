# modules/hey.nix -- powering my binscripts
#
# ZSH and Janet are the powerhouses of my dotfiles. This module configures both
# for my scripting needs. Builds bin/hey (and bin/heyops on workstations).

{ hey, lib, options, config, pkgs, ... }:

with builtins;
with lib;
with hey.lib;
let cfg = config.hey;
    janet = pkgs.janet;

    heyPkg = hey.packages.hey;
    heyopsPkg = hey.packages.heyops;

    # My own janet tree, deliberately outside the store, so `jpm install` has
    # somewhere to put things.
    janetTreeDir = "${config.home.dataDir}/janet";

    hookName = name:
      if match "[0-9]{2}-.+" name == null then "50-${name}" else name;

    # { onFoo = { bar = "..."; }; } -> { "hey/hooks.d/onFoo.d/50-bar" = {...}; }
    hookFiles =
      concatMapAttrs
        (hook: scripts:
          mapAttrs'
            (name: script:
              nameValuePair "hey/hooks.d/${hook}.d/${hookName name}" {
                text = ''
                  #!/usr/bin/env zsh
                  ${script}
                '';
                # `hey hook` ignores non-executable scripts
                executable = true;
              })
            scripts)
        cfg.hooks;
in {
  options.hey = with types; {
    info = mkOpt' (attrsOf attrs) {}
      "Facts about this system, for scripts to sniff at runtime.";
    hooks = mkOpt' (attrsOf (attrsOf lines)) {}
      "Zsh script fragments, as { HOOK = { NAME = script; } }, run by `hey hook`.";
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
    ]
    # Workstations are the control centers
    ++ optional (config.modules.profiles.role == "workstation") heyopsPkg;

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

    environment.shellAliases = {
      reboot = "hey hook onShutdown; systemctl reboot";
      poweroff = "hey hook onShutdown; systemctl poweroff";
    };

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

    systemd.user.tmpfiles.rules = [
      "d ${janetTreeDir} 755 - - - -"
    ];

    home.dataFile = hookFiles // {
      "hey/info.json".text = toJSON cfg.info;
    };
  };
}
