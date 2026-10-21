# test/nixos/modules/games/emulators.nix --- tests for modules/games/emulators.nix
#
# ES-DE launches whatever .so the XML names and RetroArch ships whatever `cores`
# built, and nothing between them checks that they agree: the first sign of a
# mismatch is a game that won't start. The suite pins the two to each other, and
# the expectation comes from pkgs.libretro, not a list here.

{ evalConfig, lib, pkgs, ... }:

with lib;
let
  systems = {
    nes = {}; psx = {}; ps2 = {}; gc = {}; nds = {};
    dreamcast.path = "/roms/dc/roms";
    n3ds.path = "/roms/3ds/roms";
    pico8.path = "/roms/pico/roms";
  };
  on = evalConfig [{ modules.games.emulators = { enable = true; romsDir = "/roms"; inherit systems; }; }];
  esde = on.modules.games.emulators;
  xml = on.home.file."${esde.dataDir}/custom_systems/es_systems.xml".text;

  cores = map (s: s.core) (filter (s: s.command == null) (attrValues esde.systems));
  soOf = c: "${replaceStrings ["-"] ["_"] pkgs.libretro.${c}.core}_libretro.so";
in {
  testEveryCoreIsBuiltAndNamed = {
    expr = {
      notBuilt = subtractLists esde.retroarch.cores cores;
      notNamed = filter (c: !(hasInfix "%CORE_RETROARCH%/${soOf c} %ROM%" xml)) cores;
    };
    expected = { notBuilt = []; notNamed = []; };
  };

  # PICO-8 isn't a package but a wrapper over the NAS copy; ES-DE finds it as
  # `pico8` on PATH, so the name and the directory it points at both matter.
  # What flags it's launched with don't.
  testPico8WrapsTheFirmwareCopy = {
    expr =
      let wrapper = findFirst (p: p.name == "pico8") null on.user.packages;
      in {
        installed = wrapper != null;
        runsFromBios = wrapper != null && hasInfix esde.systems.pico8.bios wrapper.text;
        launched = hasInfix "%EMULATOR_PICO-8%" xml;
      };
    expected = { installed = true; runsFromBios = true; launched = true; };
  };

  # A typo in a command's %EMULATOR_X% is otherwise a launch-time error.
  # Asserted by count against the good case, never by message.
  testUnknownEmulatorFailsAnAssertion = {
    expr =
      let c = evalConfig [{ modules.games.emulators = {
            enable = true; romsDir = "/roms";
            systems.ps2.command = "%EMULATOR_PCSX3% %ROM%";
          }; }];
          failing = c: length (filter (a: !a.assertion) c.assertions);
      in failing c > failing on;
    expected = true;
  };
}
