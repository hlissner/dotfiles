# modules.hardware.nvidia --- lipstick on a pig
#
# I use NVIDIA cards on all my machines, largely because I'm locked into CUDA
# for work. Fortunately, my NVIDIA GPUs are recent/latest gen (680gtx, 960gtx,
# 1080, 1660S, 3080ti) so no cludge is needed to get them to work on NixOS.

{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.hardware.nvidia;
in {
  options.modules.hardware.nvidia = {
    enable = mkBoolOpt false;
    cuda.enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      hardware.opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
      };

      services.xserver.videoDrivers = [ "nvidia" ];

      environment.systemPackages = with pkgs; [
        # Respect XDG conventions, damn it!
        (writeScriptBin "nvidia-settings" ''
          #!${stdenv.shell}
          mkdir -p "$XDG_CONFIG_HOME/nvidia"
          exec ${config.boot.kernelPackages.nvidia_x11.settings}/bin/nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings"
        '')
      ];
    }

    (mkIf cfg.cuda.enable {
      environment = {
        variables.CUDA_PATH="${pkgs.cudatoolkit}";
        systemPackages = [ pkgs.cudatoolkit ];
      };

      # $EXTRA_LDFLAGS and $EXTRA_CCFLAGS are sometimes necessary too, but I set
      # those in nix-shells instead.
    })
  ]);
}
