# modules/games/emulators.nix
#
# I've got plenty on my retro backlog to keep me busy while modern AAA goes
# silly.

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.games.emulators;

    # ES-DE's definitions (resources/systems/linux/es_systems.xml, 3.5.0), cut
    # down to the command I want first.
    dolphin = "%INJECT%=%BASENAME%.esprefix %EMULATOR_DOLPHIN% -b -e %ROM%";
    table = {
      nes = {
        fullname = "Nintendo Entertainment System";
        extensions = ".3dsen .3DSEN .fds .FDS .nes .NES .unf .UNF .unif .UNIF .7z .7Z .zip .ZIP";
        core = "mesen";
      };
      snes = {
        fullname = "Nintendo SNES (Super Nintendo)";
        extensions = ".bin .BIN .bml .BML .bs .BS .bsx .BSX .dx2 .DX2 .fig .FIG .gd3 .GD3 .gd7 .GD7 .mgd .MGD .sfc .SFC .smc .SMC .st .ST .swc .SWC .7z .7Z .zip .ZIP";
        core = "snes9x";
      };
      genesis = {
        fullname = "Sega Genesis";
        extensions = ".32x .32X .68k .68K .bin .BIN .bms .BMS .chd .CHD .cue .CUE .gen .GEN .gg .GG .iso .ISO .m3u .M3U .md .MD .mdx .MDX .sg .SG .sgd .SGD .smd .SMD .sms .SMS .7z .7Z .zip .ZIP";
        core = "genesis-plus-gx";
      };
      mastersystem = {
        fullname = "Sega Master System";
        extensions = ".68k .68K .bin .BIN .bms .BMS .chd .CHD .col .COL .cue .CUE .gen .GEN .gg .GG .iso .ISO .m3u .M3U .md .MD .mdx .MDX .rom .ROM .sg .SG .sgd .SGD .smd .SMD .sms .SMS .7z .7Z .zip .ZIP";
        core = "genesis-plus-gx";
      };
      gamegear = {
        fullname = "Sega Game Gear";
        extensions = ".68k .68K .bin .BIN .bms .BMS .chd .CHD .col .COL .cue .CUE .gen .GEN .gg .GG .iso .ISO .m3u .M3U .md .MD .mdx .MDX .rom .ROM .sg .SG .sgd .SGD .smd .SMD .sms .SMS .7z .7Z .zip .ZIP";
        core = "genesis-plus-gx";
      };
      gba = {
        fullname = "Nintendo Game Boy Advance";
        extensions = ".agb .AGB .bin .BIN .cgb .CGB .dmg .DMG .gb .GB .gba .GBA .gbc .GBC .gbx .GBX .sgb .SGB .7z .7Z .zip .ZIP";
        core = "mgba";
      };
      nds = {
        fullname = "Nintendo DS";
        extensions = ".app .APP .bin .BIN .nds .NDS .7z .7Z .zip .ZIP";
        core = "melonds";
      };
      n3ds = {
        fullname = "Nintendo 3DS";
        extensions = ".3ds .3DS .3dsx .3DSX .app .APP .axf .AXF .cci .CCI .cxi .CXI .elf .ELF .7z .7Z .zip .ZIP";
        command = "%EMULATOR_AZAHAR% %ROM%";
      };
      n64 = {
        fullname = "Nintendo 64";
        extensions = ".AppImage .bin .BIN .d64 .D64 .desktop .n64 .N64 .ndd .NDD .sh .u1 .U1 .v64 .V64 .z64 .Z64 .7z .7Z .zip .ZIP";
        core = "mupen64plus";
      };
      saturn = {
        fullname = "Sega Saturn";
        extensions = ".bin .BIN .ccd .CCD .chd .CHD .cue .CUE .iso .ISO .m3u .M3U .mds .MDS .toc .TOC .7z .7Z .zip .ZIP";
        core = "beetle-saturn";
      };
      psx = {
        fullname = "Sony PlayStation";
        extensions = ".bin .BIN .cbn .CBN .ccd .CCD .chd .CHD .cue .CUE .ecm .ECM .exe .EXE .img .IMG .iso .ISO .m3u .M3U .mdf .MDF .mds .MDS .minipsf .MINIPSF .pbp .PBP .psexe .PSEXE .psf .PSF .toc .TOC .z .Z .znx .ZNX .7z .7Z .zip .ZIP";
        core = "beetle-psx-hw";
      };
      psp = {
        fullname = "Sony PlayStation Portable";
        extensions = ".chd .CHD .cso .CSO .elf .ELF .iso .ISO .pbp .PBP .prx .PRX .7z .7Z .zip .ZIP";
        core = "ppsspp";
      };
      dreamcast = {
        fullname = "Sega Dreamcast";
        extensions = ".cdi .CDI .chd .CHD .cue .CUE .dat .DAT .elf .ELF .gdi .GDI .iso .ISO .lst .LST .m3u .M3U .7z .7Z .zip .ZIP";
        core = "flycast";
      };
      ps2 = {
        fullname = "Sony PlayStation 2";
        extensions = ".bin .BIN .chd .CHD .ciso .CISO .cso .CSO .desktop .dump .DUMP .elf .ELF .gz .GZ .m3u .M3U .mdf .MDF .img .IMG .iso .ISO .isz .ISZ .ngr .NRG .zso .ZSO";
        command = "%EMULATOR_PCSX2% -batch %ROM%";
      };
      ps3 = {
        fullname = "Sony PlayStation 3";
        extensions = ".desktop .iso .ISO .ps3 .PS3 .ps3dir .PS3DIR";
        command = "%EMULATOR_RPCS3% --no-gui %ROM%";
      };
      gc = {
        fullname = "Nintendo GameCube";
        extensions = ".ciso .CISO .dff .DFF .dol .DOL .elf .ELF .gcm .GCM .gcz .GCZ .iso .ISO .json .JSON .m3u .M3U .rvz .RVZ .tgc .TGC .wad .WAD .wbfs .WBFS .wia .WIA .7z .7Z .zip .ZIP";
        command = dolphin;
      };
      wii = {
        fullname = "Nintendo Wii";
        extensions = ".ciso .CISO .dff .DFF .dol .DOL .elf .ELF .gcm .GCM .gcz .GCZ .iso .ISO .json .JSON .m3u .M3U .rvz .RVZ .tgc .TGC .wad .WAD .wbfs .WBFS .wia .WIA .7z .7Z .zip .ZIP";
        command = dolphin;
      };
      psvita = {
        fullname = "Sony PlayStation Vita";
        extensions = ".psvita";
        command = "%EMULATOR_VITA3K% -r %INJECT%=%BASENAME%.psvita";
      };
      switch = {
        fullname = "Nintendo Switch";
        extensions = ".nca .NCA .nro .NRO .nso .NSO .nsp .NSP .xci .XCI";
        command = "%EMULATOR_EDEN% -f -g %ROM%";
      };
      pico8 = {
        fullname = "PICO-8 Fantasy Console";
        extensions = ".p8 .P8 .png .PNG";
        command = "%EMULATOR_PICO-8% -root_path %GAMEDIR% -run %ROM%";
      };
    };

    # PICO-8 is paid and not in nixpkgs. Engine lives on my NAS instead, and
    # needs patching to work in nixos, so I create a local copy to patch on
    # first invocation.
    pico8 =
      let libs = makeLibraryPath (with pkgs; [ SDL2 libGL ]);
          bios = "${cfg.systems.pico8.bios}/amd64";
      in pkgs.writeShellScriptBin "pico8" ''
        dir=${config.home.cacheDir}/pico-8
        if [ ! "$dir/pico8_dyn" -nt "${bios}/pico8_dyn" ] || [ "$(cat "$dir/.libs" 2>/dev/null)" != "${libs}" ]; then
          mkdir -p "$dir"
          cp -f "${bios}/pico8_dyn" "${bios}/pico8.dat" "$dir/"
          chmod u+w "$dir/pico8_dyn" "$dir/pico8.dat"
          ${pkgs.patchelf}/bin/patchelf \
            --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 \
            --set-rpath ${libs} "$dir/pico8_dyn"
          echo "${libs}" > "$dir/.libs"
        fi
        export PATH=${pkgs.wget}/bin:$PATH
        exec "$dir/pico8_dyn" -home ${config.home.dataDir}/lexaloffle "$@"
      '';

    # %EMULATOR_X% -> the package whose binary ES-DE's find rules look for.
    emulators = {
      PCSX2 = pkgs.pcsx2;
      RPCS3 = pkgs.rpcs3;
      DOLPHIN = pkgs.dolphin-emu;
      VITA3K = pkgs.vita3k;
      EDEN = pkgs.eden;
      AZAHAR = pkgs.azahar;
    } // optionalAttrs (cfg.systems ? pico8) { "PICO-8" = pico8; };

    soOf = c: "${replaceStrings ["-"] ["_"] pkgs.libretro.${c}.core}_libretro.so";
    commandOf = s:
      if s.command != null then s.command
      else "%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/${soOf s.core} %ROM%";
    emulatorsOf = cmd:
      map head (filter isList (split "%EMULATOR_([A-Z0-9-]+)%" cmd));

    systems = mapAttrs (name: s: s // { command = commandOf s; }) cfg.systems;
    cores = unique (map (s: s.core) (filter (s: s.command == null) (attrValues cfg.systems)));
    used = unique (filter (e: e != "RETROARCH") (concatMap (s: emulatorsOf s.command) (attrValues systems)));
    # Known ones only, so an unknown one is the assertion's to report.
    standalones = map (e: emulators.${e}) (filter (e: emulators ? ${e}) used);

    systemXml = name: s: ''
      <system>
        <name>${name}</name>
        <fullname>${escapeXML table.${name}.fullname}</fullname>
        <path>${escapeXML s.path}</path>
        <extension>${table.${name}.extensions}</extension>
        <command>${escapeXML s.command}</command>
        <platform>${name}</platform>
        <theme>${name}</theme>
      </system>
    '';

    esde = mkWrapper self.packages.es-de ''
      wrapProgram $out/bin/es-de \
        --set ESDE_APPDATA_DIR "${cfg.dataDir}" \
        --run 'ls "${cfg.romsDir}" >/dev/null 2>&1 || true'
    '';

    retroarch =
      let rCfg = cfg.retroarch;
          toCfg = v: if isBool v then boolToString v else toString v;
      in pkgs.wrapRetroArch {
        cores = map (c: pkgs.libretro.${c}) (unique rCfg.cores);
        settings = mapAttrs (_: toCfg) (
          {
            video_shader_dir = "${pkgs.libretro-shaders-slang}/share/libretro/shaders";
          }
          // optionalAttrs (cfg.biosDir != "") { system_directory = cfg.biosDir; }
          // optionalAttrs (cfg.romsDir != "") { rgui_browser_directory = cfg.romsDir; }
          // rCfg.settings
        );
      };
in {
  options.modules.games.emulators = with types; {
    enable = mkBoolOpt false;
    dataDir = mkOpt str "${config.home.dataDir}/es-de";
    romsDir = mkOpt str "";
    biosDir = mkOpt str "";
    # From ES-DE's system names; an empty attrset takes the defaults
    systems = mkOpt (attrsOf (submodule ({ name, config, ... }: {
      options = {
        path = mkOpt str (
          if cfg.romsDir != "" then "${cfg.romsDir}/${name}/roms"
          else throw "modules.games.emulators: set romsDir, or systems.${name}.path");
        bios = mkOpt str "${dirOf config.path}/bios";
        # A raw ES-DE command or pkgs.libretro attribute
        core = mkOpt (nullOr str) (table.${name}.core or null);
        command = mkOpt (nullOr str) (table.${name}.command or null);
      };
    }))) {};
    retroarch = {
      enable = mkBoolOpt true;
      # Names from pkgs.libretro. Use `nix eval
      # .#inputs.nixpkgs.legacyPackages...  .libretro --apply
      # builtins.attrNames` to list them.
      cores = mkOpt (listOf str) [
        "beetle-psx-hw"
        "fbneo"
        "gambatte"
        "genesis-plus-gx"
        "mgba"
        "mupen64plus"
        "nestopia"
        "snes9x"
      ];
      settings = mkOpt (attrsOf (oneOf [ str bool int float ])) {};
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        { assertion = all (n: table ? ${n}) (attrNames cfg.systems);
          message = "modules.games.emulators.systems: unknown system(s): ${toString (filter (n: !(table ? ${n})) (attrNames cfg.systems))}"; }
        { assertion = all (e: emulators ? ${e}) used;
          message = "modules.games.emulators: no package for emulator(s): ${toString (filter (e: !(emulators ? ${e})) used)}"; }
      ];

      user.packages = [ esde ] ++ standalones;
      services.udev.packages = standalones;

      home.file."${cfg.dataDir}/custom_systems/es_systems.xml".text = ''
        <?xml version="1.0"?>
        <systemList>
          <loadExclusive/>
        ${concatStrings (mapAttrsToList systemXml systems)}</systemList>
      '';

      # Each standalones has its own opinions on where BIOSes live. Only link
      # plain read-only files; otherwise, it needs to be installed through a GUI
      # (rpcs3, vita3k, eden, wii NAND, etc).
      home.configLink = optionalAttrs (cfg.systems ? ps2) {
        "PCSX2/bios" = cfg.systems.ps2.bios;
      };
      # Per file, not the dir: Dolphin writes SRAM and memcards next to them.
      home.dataLink = optionalAttrs (cfg.systems ? gc) (listToAttrs (map
        (f: nameValuePair "dolphin-emu/GC/${f}" "${cfg.systems.gc.bios}/${f}")
        [ "dsp_rom.bin" "dsp_coef.bin" "USA/IPL.bin" "EUR/IPL.bin" "JAP/IPL.bin" ]));
    }

    (mkIf cfg.retroarch.enable {
      user.packages = [ retroarch ];
      modules.games.emulators.retroarch.cores = cores;

      home.file."${cfg.dataDir}/custom_systems/es_find_rules.xml".text = ''
        <?xml version="1.0"?>
        <ruleList>
          <core name="RETROARCH">
            <rule type="corepath">
              <entry>${retroarch}/lib/retroarch/cores</entry>
            </rule>
          </core>
        </ruleList>
      '';
    })
  ]);
}
