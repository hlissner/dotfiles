{ config, lib, pkgs, ... }:

{
  imports = [ ./. ];

  environment = {
    variables = {
      NPM_CONFIG_USERCONFIG = "$XDG_CONFIG_HOME/npm/config";
      NPM_CONFIG_CACHE = "$XDG_CACHE_HOME/npm";
      NPM_CONFIG_TMP = "$XDG_RUNTIME_DIR/npm";
      NPM_CONFIG_PREFIX = "$XDG_CACHE_HOME/npm";
    };

    systemPackages = with pkgs; [
      nodejs
    ];
  };
}
