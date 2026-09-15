# modules/apps/steam.nix

{ hey, heyBin, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.apps.steam;
in {
  options.modules.apps.steam = with types; {
    enable = mkBoolOpt false;
    libraryDir = mkOpt str "";
  };

  config = mkIf cfg.enable {
    # Moves Windows thread-sync primitives into the kernel, cutting wineserver
    # overhead, improving 1% lows in CPU-heavy games/apps. Needs kernel 6.14+
    # and a Proton that uses it: GE-Proton enables it automatically when the
    # module is present; upstream Proton may still want PROTON_USE_NTSYNC=1 in
    # the game's launch options depending on version.
    boot.kernelModules = [ "ntsync" ];

    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true;
        # gamescopeSession.enable = true;
        extraPackages = with pkgs; [ gamescope mangohud ];
        extraCompatPackages = with pkgs; [ proton-ge-bin ];
      };

      # Makes gamemoderun available, but it must be selectively enabled for
      # games by changing said game's launch options to 'gamemoderun %command%'.
      gamemode = {
        enable = true;
        settings = {
          general = {
            inhibit_screensaver = 0;
            renice = 10;
          };
          custom = {
            start = "${heyBin} hook onGamemode on";
            end = "${heyBin} hook onGamemode off";
          };
        };
      };

      # E.g. 'gamemoderun gamescope -f -W 2560 -H 1440 -r 144 -- %command%'
      # Helpful options:
      #   --adaptive-sync
      #   --force-grab-cursor
      #   --mangoapp
      #   --expose-wayland
      gamescope = {
        enable = true;
        capSysNice = false;
      };
    };

    user.extraGroups = [ "gamemode" ];

    environment.systemPackages = with pkgs; [
      # Simple way to manage non-Steam exe's
      faugus-launcher

      (let pkg = config.programs.steam.package;
           # If the steam library lives on a shared NTFS drive, then we must
           # symlink steamapps/compatdata to a local directory, because Proton
           # will fail to produce certain paths that are illegal on an NTFS
           # filesystem (e.g. contains ":"). WARNING: SOME GAMES WRITE SAVEFILES
           # TO THE COMPATDATA FOLDER. IF THOSE GAMES DON'T HAVE CLOUD-SAVING,
           # THIS WILL DESTROY DATA! (Most games do, though)
           libFix = writeShellScriptBin "libfix" ''
             if [[ "x${cfg.libraryDir}" != "x" ]]; then
               _libdir="${cfg.libraryDir}"
               if [[ -d "$_libdir" ]]; then
                 _steamdir="$_libdir/steamapps"
                 if [[ "$(stat -f -c %T "$_steamdir")" == "fuseblk" ]]; then
                   if [[ ! -L "$_steamdir/compatdata" ]]; then
                     rm -rf "$_steamdir/compatdata"
                   fi
                   if [[ ! -e "$_steamdir/compatdata" ]]; then
                     ln -s "$HOME/.steam/steam/steamapps/compatdata" "$_steamdir/compatdata"
                   fi
                 fi
               fi
             fi
           '';
           # Falls back rather than exporting an empty HOME, which programs tend
           # to handle worse than a real one (flatpak asserts and dies).
           fakeHome = ''--run 'export HOME="''${XDG_FAKE_HOME:-$HOME}"' '';
           xdg = config.modules.xdg.enable;
        # Stop Steam from polluting $HOME, and fix symlink/filename issues for a
        # Steam library that lives on an NTFS drive.
      in mkWrapper [ pkg pkg.run ] (''
        wrapProgram "$out/bin/steam" \
          ${optionalString xdg fakeHome} \
          --run '${libFix}/bin/libfix'
      '' + optionalString xdg ''
        wrapProgram "$out/bin/steam-run" ${fakeHome}
      ''))
    ];

    # Better for steam proton games
    systemd.user.settings.Manager.DefaultLimitNOFILE = mkDefault 1048576;
  };
}
