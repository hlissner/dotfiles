# Idea is my main driver.

{ config, lib, pkgs, inputs, ... }:

with lib;
with lib.my;
let cfg = config.modules.editors.idea;
    configDir = config.dotfiles.configDir;
in {
  options.modules.editors.idea = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {

    user.packages = with pkgs; [
      ## Idea itself
      jetbrains.idea-ultimate
    ];

  };
}
