{ hey, lib, options, config, ... }:

with lib;
with hey.lib;
mkIf (elem "wacom" config.modules.profiles.hardware) {
  # REVIEW: Maybe cyber-sushi/makima?
  hardware.opentabletdriver.enable = true;
}
