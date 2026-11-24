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
      arcade = {
        fullname = "Arcade";
        extensions = ".acgame .arcadedef .cmd .CMD .desktop .gam .GAM .lindbergh .neo .NEO .sh .7z .7Z .zip .ZIP";
        core = "fbneo";
      };
      neogeo = {
        fullname = "SNK Neo Geo";
        extensions = ".neo .NEO .7z .7Z .zip .ZIP";
        core = "fbneo";
      };
      dos = {
        fullname = "DOS (PC)";
        extensions = ".bat .BAT .com .COM .conf .CONF .cue .CUE .dosz .DOSZ .exe .EXE .img .IMG .iso .ISO .7z .7Z .zip .ZIP";
        core = "dosbox-pure";
      };
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
        extensions = ".3ds .3DS .3dsx .3DSX .app .APP .axf .AXF .cci .CCI .cxi .CXI .zcci .ZCCI .zcxi .ZCXI .z3dsx .Z3DSX .elf .ELF";
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
      xbox = {
        fullname = "Microsoft Xbox";
        extensions = ".iso .ISO .xiso .XISO";
        command = "%INJECT%=%BASENAME%.esprefix %EMULATOR_XEMU% -dvd_path %ROM%";
      };
      psvita = {
        fullname = "Sony PlayStation Vita";
        extensions = ".zip .ZIP";
        command = "%EMULATOR_VITA3K% %ROM%";
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

    # PICO-8 is paid and not in nixpkgs. Engine lives on my NAS instead (zipped,
    # because RomM's firmware dirs are flat), and needs patching to work in
    # nixos, so I unpack a local copy to patch on first invocation.
    pico8 =
      let libs = makeLibraryPath (with pkgs; [ SDL2 libGL ]);
          zip = "${cfg.systems.pico8.bios}/amd64.zip";
      in pkgs.writeShellScriptBin "pico8" ''
        dir=${config.home.cacheDir}/pico-8
        if [ ! "$dir/pico8_dyn" -nt "${zip}" ] || [ "$(cat "$dir/.libs" 2>/dev/null)" != "${libs}" ]; then
          mkdir -p "$dir"
          ${pkgs.unzip}/bin/unzip -ojq "${zip}" amd64/pico8_dyn amd64/pico8.dat -d "$dir"
          chmod u+w "$dir/pico8_dyn" "$dir/pico8.dat"
          ${pkgs.patchelf}/bin/patchelf \
            --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 \
            --set-rpath ${libs} "$dir/pico8_dyn"
          echo "${libs}" > "$dir/.libs"
        fi
        export PATH=${pkgs.wget}/bin:$PATH
        exec "$dir/pico8_dyn" -home ${config.home.dataDir}/lexaloffle "$@"
      '';

    # xemu has no flags for its BIOS, only a config it rewrites on exit, and
    # saves go *into* the HDD image and EEPROM. So those two get a local copy
    # and the config is seeded once; after that it's xemu's (and mine) to edit.
    xemu =
      let bios = cfg.systems.xbox.bios;
      in pkgs.writeShellScriptBin "xemu" ''
        dir=${config.home.dataDir}/xemu/xemu
        if [ ! -e "$dir/xemu.toml" ]; then
          mkdir -p "$dir"
          cp -n "${bios}/xbox_hdd.qcow2" "${bios}/xbox_eeprom.bin" "$dir/"
          chmod u+w "$dir/xbox_hdd.qcow2" "$dir/xbox_eeprom.bin"
          cat > "$dir/xemu.toml" <<EOF
        [sys.files]
        bootrom_path = '${bios}/mcpx_1.0.bin'
        flashrom_path = '${bios}/Complex_4627.bin'
        eeprom_path = '$dir/xbox_eeprom.bin'
        hdd_path = '$dir/xbox_hdd.qcow2'
        EOF
        fi
        exec ${pkgs.xemu}/bin/xemu "$@"
      '';

    # nixpkgs' AppImage wrap forgets libgpg-error, so it dies in ld.so.
    vita3kPkg = pkgs.vita3k.override (o: {
      appimageTools = o.appimageTools // {
        wrapType2 = a: o.appimageTools.wrapType2 (a // {
          extraPkgs = p: a.extraPkgs p ++ [ p.libgpg-error ];
        });
      };
    });

    # Vita3K only runs what's installed in its ux0, by title ID, and ES-DE's
    # answer is a .psvita stub per game. My dumps are NoNpDrm zips whose first
    # dir *is* the title ID, so read it from there: run it if it's installed,
    # otherwise hand over the zip, which installs it and then runs it.
    vita3k =
      let bios = cfg.systems.psvita.bios;
      in pkgs.writeShellScriptBin "vita3k" ''
        v3k=${vita3kPkg}/bin/vita3k
        pref=${config.home.dataDir}/Vita3K/Vita3K
        # The update check has no flag and no GUI toggle, only this key, in a
        # file Vita3K rewrites on every launch. Because of course it does.
        conf=${config.home.configDir}/Vita3K/config.yml
        [ -e "$conf" ] || { mkdir -p "''${conf%/*}"; echo --- > "$conf"; }
        sed -i -e '/^check-for-updates-mode:/d' -e '/^---$/a check-for-updates-mode: 0' "$conf"
        case "$1" in *.zip|*.ZIP)
          [ -d "$pref/vs0/vsh" ] || "$v3k" --firmware "${bios}/PSVUPDAT.PUP"
          [ -d "$pref/sa0/data/font" ] || "$v3k" --firmware "${bios}/PSP2UPDAT.PUP"
          id=$(${pkgs.unzip}/bin/unzip -Z1 "$1" | sed -n 's|^app/\([A-Z0-9]\{9\}\)/.*|\1|p' | head -n1)
          [ -n "$id" ] && [ -d "$pref/ux0/app/$id" ] && exec "$v3k" -r "$id"
          # Its CLI splits a path on spaces and takes a leading / for a
          # Windows-style flag, then drops it. Every path I have is both, so
          # it gets a relative alias.
          ln -sf "$1" "$pref/install.zip"
          cd "$pref" && exec "$v3k" install.zip
        esac
        exec "$v3k" "$@"
      '';

    # %EMULATOR_X% -> the package whose binary ES-DE's find rules look for.
    emulators = {
      PCSX2 = pkgs.pcsx2;
      RPCS3 = pkgs.rpcs3;
      DOLPHIN = pkgs.dolphin-emu;
      EDEN = pkgs.eden;
      AZAHAR = pkgs.azahar;
    } // optionalAttrs (cfg.systems ? pico8) { "PICO-8" = pico8; }
      // optionalAttrs (cfg.systems ? xbox) { XEMU = xemu; }
      // optionalAttrs (cfg.systems ? psvita) { VITA3K = vita3k; };

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

    # ES-DE is an XWayland window, so it gets steam input, but emulators open in
    # native Wayland windows, so Steam doesn't propagate steam input
    # (controllers) to them.
    esde = mkWrapper self.packages.es-de ''
      wrapProgram $out/bin/es-de \
        --set ESDE_APPDATA_DIR "${cfg.dataDir}" \
        --run '[ -n "$SteamGameId" ] && unset WAYLAND_DISPLAY'
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
          if cfg.romsDir != "" then "${cfg.romsDir}/${name}"
          else throw "modules.games.emulators: set romsDir, or systems.${name}.path");
        # roms/SYS -> bios/SYS, so a system whose path is under RomM's slug
        # (ngc, not gc) finds its BIOS under that slug too.
        bios = mkOpt str "${dirOf (dirOf config.path)}/bios/${baseNameOf config.path}";
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

      user.packages = [ esde ] ++ standalones
        ++ optional (cfg.systems ? psvita) (mkLauncherEntry "Vita3K" {
          description = "PlayStation Vita emulator";
          icon = "${vita3kPkg}/share/icons/hicolor/128x128/apps/vita3k.png";
          exec = "${vita3k}/bin/vita3k";
          categories = [ "Game" "Emulator" ];
        });
      services.udev.packages = standalones;

      home.file."${cfg.dataDir}/custom_systems/es_systems.xml".text = ''
        <?xml version="1.0"?>
        <systemList>
          <loadExclusive/>
        ${concatStrings (mapAttrsToList systemXml systems)}</systemList>
      '';

      # Each standalones has its own opinions on where BIOSes live. Only link
      # plain read-only files; otherwise, it needs to be installed through a GUI
      # (rpcs3, eden, wii NAND, etc).
      home.configLink = optionalAttrs (cfg.systems ? ps2) {
        "PCSX2/bios" = cfg.systems.ps2.bios;
      };
      # Per file, not the dir: Dolphin writes SRAM and memcards next to them,
      # and Azahar wants nand/ and sdmc/ beside sysdata/.
      home.dataLink =
        let files = sys: dir: src: fs: optionalAttrs (cfg.systems ? ${sys}) (listToAttrs (map
              (f: nameValuePair "${dir}/${f}" "${src}/${f}") fs));
            bios = sys: cfg.systems.${sys}.bios;
        in files "gc" "dolphin-emu/GC" (bios "gc") [ "dsp_rom.bin" "dsp_coef.bin" ]
        # bios/ngc only has the IPLs zipped; the per-region dirs Dolphin wants
        # exist in the EmuDeck tree alone.
        // files "gc" "dolphin-emu/GC" "${cfg.biosDir}/dolphin-emu/Sys/GC" [ "USA/IPL.bin" "EUR/IPL.bin" "JAP/IPL.bin" ]
        // files "n3ds" "azahar-emu/sysdata" (bios "n3ds") [ "aes_keys.txt" "seeddb.bin" ];
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
