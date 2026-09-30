{ self, lib, options, config, ... }:

with lib;
with self.lib;
mkIf (elem "wacom" config.modules.profiles.hardware) {
  # REVIEW: Maybe cyber-sushi/makima?
  hardware.opentabletdriver.enable = true;
}
