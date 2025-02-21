# modules/desktop/media/cad.nix --- for 3D modeling & design
#
# For game art assets, interior design, and product demos for clients.

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.media.cad;
    version = "4.1";
in {
  options.modules.desktop.media.cad = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    # Supplies newer versions of Blender with CUDA support baked in.
    # @see https://github.com/edolstra/nix-warez/tree/master/blender
    nixpkgs.overlays = [ hey.inputs.blender-bin.overlays.default ];

    user.packages = [
      (if config.modules.desktop.type == "wayland"
       then pkgs.freecad-wayland
       else pkgs.freecad)

      # Blender itself doesn't need libxcrypt-legacy, but I use blenderkit,
      # which needs libcrypt.so.1, which libxcrypt no longer provides.
      (mkWrapper pkgs."blender_${builtins.replaceStrings ["."] ["_"] version}" ''
        wrapProgram "$out/bin/blender" \
          --run 'export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${pkgs.libxcrypt-legacy}/lib"'
      '')
    ];

    home.configFile = {
      # "blender/${version}/config" = {
      #   source = "${hey.configDir}/blender/config";
      #   recursive = true;
      # };
      "blender/${version}/scripts" = {
        source = "${hey.configDir}/blender/scripts";
        recursive = true;
      };
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
          ${pkgs.gnutar}/bin/tar xzvf "$src" -C "$destdir"
        fi
      done
    '';
  };
}
