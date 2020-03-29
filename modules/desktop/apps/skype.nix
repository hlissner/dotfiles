{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.desktop.apps.skype = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.apps.skype.enable {
    my.packages = with pkgs; [
      skypeforlinux
      skype_call_recorder
    ];
  };
}
