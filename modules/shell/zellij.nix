{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.shell.zellij;
in {
  options.modules.shell.zellij = with types; {
    enable = mkBoolOpt false;
    zmate.enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable
  {
    user.packages = with pkgs; [ zellij zmate ];

    # Respect XDG, damn it!
    environment.variables.ZELLIJ_CONFIG_DIR = "${hey.configDir}/zellij";

    modules.hyprland.matugen.templates.zellij = {
      input_path = "${hey.configDir}/zellij/colors.template.kdl";
      output_path = "${hey.configDir}/zellij/themes/colors.kdl";
    };
  };
}
