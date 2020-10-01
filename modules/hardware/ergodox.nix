{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.hardware.ergodox;
in {
  options.modules.hardware.ergodox = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = [ pkgs.teensy-loader-cli ];
    # 'teensyload FILE' to load a new config into the ergodox
    environment.shellAliases.teensyload =
      "sudo teensy-loader-cli -w -v --mcu=atmega32u4";
    # Make right-alt the compose key, so ralt+a+a = å or ralt+o+/ = ø
    services.xserver.xkbOptions = "compose:ralt";
  };
}
