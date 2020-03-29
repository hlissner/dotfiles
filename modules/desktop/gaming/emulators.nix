{ config, options, lib, pkgs, ... }:

with lib;
{
  options.modules.desktop.gaming.emulators =
    let mkBoolDefault = bool: mkOption {
          type = types.bool;
          default = bool;
        };
    in {
      psx.enable  = mkBoolDefault false;  # Playstation
      ds.enable   = mkBoolDefault false;  # Nintendo DS
      gb.enable   = mkBoolDefault false;  # GameBoy + GameBoy Color
      gba.enable  = mkBoolDefault false;  # GameBoy Advance
      snes.enable = mkBoolDefault false;  # Super Nintendo
    };

  config = let emu = config.modules.desktop.gaming.emulators; in {
    my.packages = with pkgs;
      (if emu.psx.enable then [ epsxe ] else []) ++
      (if emu.ds.enable then [ desume ] else []) ++
      (if (emu.gba.enable ||
           emu.gb.enable ||
           emu.snes.enable)
       then [ higan ] else []);
  };
}
