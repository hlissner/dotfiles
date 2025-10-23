{ hey, lib, options, config, ... }:

with lib;
with hey.lib;
mkIf (elem "wacom/cintiq" config.modules.profiles.hardware) {
  # REVIEW: Maybe cyber-sushi/makima?
  hardware.opentablet.driver.enable = true;
}
