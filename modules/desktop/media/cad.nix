# modules/desktop/media/cad.nix --- for 3D modeling & design
#
# For game art assets, interior design, and product demos for clients.

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
let inherit (self) configDir;
    cfg = config.modules.desktop.media.cad;
in {
  options.modules.desktop.media.cad = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    # Supplies newer versions of Blender with CUDA support baked in.
    nixpkgs.overlays = [ self.inputs.blender-bin.overlays.default ];

    # Includes newer versions of Blender baked in with CUDA support.
    user.packages = with pkgs; [
      (writeShellScriptBin "blender" ''
        export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${libxcrypt}/lib"
        exec ${blender_3_4}/bin/blender "$@"
      '')
    ];

    environment.systemPackages = [ pkgs.blender_3_4 ];

    home.configFile = {
      # "blender/3.4/config" = {
      #   source = "${configDir}/blender/config";
      #   recursive = true;
      # };
      "blender/3.4/scripts" = {
        source = "${configDir}/blender/scripts";
        recursive = true;
      };
    };

    # I copy these files manually because they should be mutable, as Blender is
    # very stateful. Having a consistent starting point for new systems is good
    # enough for me.
    system.userActivationScripts.setupBlenderConfig = ''
      destdir="$XDG_CONFIG_HOME/blender/3.4/config"
      mkdir -p "$destdir"
      for cfile in ${configDir}/blender/config/*; do
        basename="$(basename $cfile)"
        dest="$destdir/$basename"
        if [ ! -e "$dest" ]; then
          cp "$cfile" "$dest"
        fi
      done
      for bfile in startup userpref; do
        src="${configDir}/blender/$bfile.blend.tar.gz"
        if [ ! -e "$destdir/$bfile.blend" ]; then
          ${pkgs.gnutar}/bin/tar xzvf "$src" -C "$destdir"
        fi
      done
    '';
  };
}
