# modules/desktop/apps/steam.nix

{ hey, heyBin, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.apps.steam;
in {
  options.modules.desktop.apps.steam = with types; {
    enable = mkBoolOpt false;
    mangohud.enable = mkBoolOpt true;
    libraryDir = mkOpt str "";
  };

  config = mkIf cfg.enable {
    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true;
      };
      gamescope.enable = true;
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
            start = "${heyBin} hook gamemode --on";
            end = "${heyBin} hook gamemode --off";
          };
        };
      };
    };

    user.extraGroups = [ "gamemode" ];

    environment.systemPackages = with pkgs; [
      # Stop Steam from polluting $HOME, and fix symlink/filename issues for a
      # Steam library that lives on an NTFS drive.
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
       in mkWrapper [
         pkg
         pkg.run   # for GOG and humble bundle games
       ] ''
         wrapProgram "$out/bin/steam" \
           --run 'export HOME="$XDG_FAKE_HOME"' \
           --run '${libFix}/bin/libfix'
         wrapProgram "$out/bin/steam-run" --run 'export HOME="$XDG_FAKE_HOME"'
       '')
    ] ++ (if cfg.mangohud.enable then [ pkgs.mangohud ] else []);

    # Better for steam proton games
    systemd.extraConfig = "DefaultLimitNOFILE=1048576";
  };
}
