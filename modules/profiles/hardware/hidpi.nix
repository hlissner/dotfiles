# modules.hardware.hidpi --- special support for hidpi displays
#
# TODO

{ self, lib, config, ... }:

with lib;
with self.lib;
mkIf (elem "hidpi" config.modules.profiles.hardware) {
  env.QT_DEVICE_PIXEL_RATIO = "2";
  env.QT_AUTO_SCREEN_SCALE_FACTOR = "true";
}
