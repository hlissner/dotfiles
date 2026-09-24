## modules/shell/yazi.nix
#
# yazi, my file manager of choice (besides dirvish in Emacs).

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.shell.yazi;
in {
  options.modules.shell.yazi = with types; {
    enable = mkBoolOpt false;
    extraPackages = mkOpt' (listOf package) []
      "Extra binaries to put on yazi's PATH, for previewers and openers.";
  };

  config = mkIf cfg.enable {
    user.packages = [
      (pkgs.yazi.override { extraPackages = cfg.extraPackages; })
    ];

    # Leave to Noctalia template, but it requires things be in the right place!
    # See https://github.com/noctalia-dev/noctalia/blob/main/assets/templates/foot/apply.sh
    modules.hyprland.theme.communityTemplates = [ "yazi" ];
    home.configLink."yazi" = "${hey.configDir}/yazi";
    modules.shell.zsh.rcFiles = [ "${hey.configDir}/yazi/aliases.zsh" ];
  };
}
