# modules/apps/media/cad.nix --- for 3D modeling & design
#
# For game art assets, interior design, and product demos for clients.

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.apps.media.cad;
    version = "5.2";
in {
  options.modules.apps.media.cad = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      blender
    ];

    home.configFile = {
      "blender/${version}/config" = {
        source = "${hey.configDir}/blender/config";
        recursive = true;
      };
      # "blender/${version}/scripts" = {
      #   source = "${hey.configDir}/blender/scripts";
      #   recursive = true;
      # };
    };

    # I copy these files manually because they should be mutable, as Blender is
    # very stateful. Having a consistent starting point for new systems is good
    # enough for me.
    system.userActivationScripts.setupBlenderConfig = ''
      destdir="$XDG_CONFIG_HOME/blender/${version}/config"
      mkdir -p "$destdir"
      for cfile in ${hey.configDir}/blender/config/*; do
        basename="$(basename $cfile)"
        dest="$destdir/$basename"
        if [ ! -e "$dest" ]; then
          cp "$cfile" "$dest"
        fi
      done
      for bfile in startup userpref; do
        src="${hey.configDir}/blender/$bfile.blend.tar.gz"
        if [ ! -e "$destdir/$bfile.blend" ]; then
          ${pkgs.gnutar}/bin/tar -I ${pkgs.gzip}/bin/gzip -xvf "$src" -C "$destdir"
        fi
      done
    '';
  };
}
