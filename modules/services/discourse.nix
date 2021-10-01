{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.discourse;
in {
  options.modules.services.discourse = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.discourse = {
      enable = true;
      enableACME = true;
      sidekiqProcesses = config.nix.maxJobs / 2;
      # plugins = with config.services.discourse.package.plugins; [
      #   discourse-akismet
      #   discourse-chat-integration
      #   discourse-checklist
      #   discourse-canned-replies
      #   discourse-github
      #   discourse-assign
      # ];
    };
  };
}
