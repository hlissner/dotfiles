# Theme modules are a special beast. They're the only modules that are deeply
# intertwined with others, and are solely responsible for aesthetics. Disabling
# a theme module should never leave a system non-functional.

{ config, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.themes;
in {
  assertions = [{
    assertion = countAttrs (_: x: x.enable) cfg < 2;
    message = "Can't have more than one theme enabled at a time";
  }];
}
