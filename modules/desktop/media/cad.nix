# modules/desktop/media/cad.nix --- for 3D modeling & design
#
# For game art assets, interior design, and product demos for clients.

{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.media.cad;
in {
  options.modules.desktop.media.cad = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    # Hardware accelerated rendering
    modules.hardware.nvidia.cuda.enable = mkDefault true;

    # Includes newer versions of Blender baked in with CUDA support.
    nixpkgs.overlays = [ inputs.blender-bin.overlay ];
    user.packages = [ pkgs.blender_3_4 ];

    # TODO File is too big. Deploy to server/use annex/gitlfs later.
    # home.configFile = {
    #   "blender/3.40/config/userpref.blend".source = "${config.dotfiles.configDir}/blender/userpref.blend";
    # };
  };
}
