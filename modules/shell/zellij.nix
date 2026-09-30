{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
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
    environment.variables.ZELLIJ_CONFIG_DIR = "${config.hey.configDir}/zellij";

    modules.wm.theme.files.zellij = {
      input_path = "${config.hey.configDir}/zellij/colors.template.kdl";
      output_path = "${config.hey.configDir}/zellij/themes/colors.kdl";
    };
  };
}
