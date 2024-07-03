# modules/dev/node.nix --- https://nodejs.org/en/
#
# JS is one of those "when it's good, it's alright, when it's bad, it's a
# disaster" languages.

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let devCfg = config.modules.dev;
    cfg = devCfg.node;
    nodePkg = pkgs.nodejs_latest;
in {
  options.modules.dev.node = {
    enable = mkBoolOpt false;
    xdg.enable = mkBoolOpt devCfg.xdg.enable;
  };

  config = mkMerge [
    (mkIf cfg.enable {
      user.packages = [
        nodePkg
        pkgs.yarn
      ];

      # Run locally installed bin-script, e.g. n coffee file.coffee
      environment.shellAliases = {
        n  = "PATH=\"$(${nodePkg}/bin/npm bin):$PATH\"";
        ya = "yarn";
      };

      environment.variables.PATH = [ "$(${pkgs.yarn}/bin/yarn global bin)" ];
    })

    (mkIf cfg.xdg.enable {
      # NPM refuses to adopt XDG conventions upstream, so I enforce it myself.
      environment.variables = {
        NPM_CONFIG_USERCONFIG = "$XDG_CONFIG_HOME/npm/config";
        NPM_CONFIG_CACHE      = "$XDG_CACHE_HOME/npm";
        NPM_CONFIG_PREFIX     = "$XDG_CACHE_HOME/npm";
        NPM_CONFIG_TMP        = "$XDG_RUNTIME_DIR/npm";
        NODE_REPL_HISTORY     = "$XDG_CACHE_HOME/node/repl_history";
      };

      home.configFile."npm/config".text = ''
        cache=''${XDG_CACHE_HOME}/npm
        prefix=''${XDG_DATA_HOME}/npm
        tmp=''${XDG_RUNTIME_DIR}/npm
      '';
    })
  ];
}
