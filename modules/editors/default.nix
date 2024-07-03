{ hey, lib, config, ... }:

with lib;
with hey.lib;
let cfg = config.modules.editors;
in {
  options.modules.editors = {
    default = mkOpt types.str "vim";
  };

  config = mkIf (cfg.default != null) {
    environment.variables.EDITOR = cfg.default;
  };
}
