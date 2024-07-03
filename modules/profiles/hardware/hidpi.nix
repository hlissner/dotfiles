# modules.hardware.hidpi --- special support for hidpi displays
#
# TODO

{ hey, lib, config, ... }:

with lib;
with hey.lib;
mkIf (elem "hidpi" config.modules.profiles.hardware) {
  environment.sessionVariables = {
    QT_DEVICE_PIXEL_RATIO = "2";
    QT_AUTO_SCREEN_SCALE_FACTOR = "true";
  };
}
