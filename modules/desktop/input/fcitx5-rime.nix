{ hey, config, lib, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.input.fcitx5-rime;
in {
  options.modules.desktop.input.fcitx5-rime = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    modules.desktop.input.fcitx5 = {
      enable = true;
      rime.enable = true;
    };
  };
}
