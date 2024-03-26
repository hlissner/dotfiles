# profiles/hardware/common/gpu/nvidia/default.nix --- lipstick on a pig
#
# I use NVIDIA cards on all my machines, largely because I'm locked into CUDA
# for work reasons. Fortunately, mine aren't too old and are relatively beefy
# (680gtx, 960gtx, 1080, 1660S, 3080ti) so only a little cludge is needed to get
# them to work well on NixOS.

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
let hardware = config.modules.profiles.hardware;
in mkIf (any (s: hasPrefix "gpu/nvidia" s) hardware) (mkMerge [
  {
    services.xserver.videoDrivers = mkDefault [ "nvidia" ];

    hardware = {
      opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
        extraPackages = [ pkgs.vaapiVdpau ];
      };
      nvidia = {
        # Save some idle watts.
        powerManagement.enable = true;  # see NixOS/nixos-hardware#348
      };
    };

    environment = {
      systemPackages = with pkgs; [
        # Respect XDG conventions, damn it!
        (mkWrapper config.boot.kernelPackages.nvidia_x11.settings ''
          wrapProgram "$out/bin/nvidia-settings" \
            --run 'mkdir -p "$XDG_CONFIG_HOME/nvidia"' \
            --append-flags '--config="$XDG_CONFIG_HOME/nvidia/rc.conf"'
        '')

        # Required for CUDA support
        cudatoolkit
      ];
      variables = {
        CUDA_PATH = "${pkgs.cudatoolkit}";
        CUDA_CACHE_PATH = "$XDG_CACHE_HOME/nv";

        # $EXTRA_LDFLAGS and $EXTRA_CCFLAGS are sometimes necessary too, but I
        # set those in nix-shells instead.
      };
    };

    # Cajole Firefox into video-acceleration (or try).
    modules.desktop.browsers.firefox.sharedSettings = {
      "media.ffmpeg.vaapi.enabled" = true;
      "gfx.webrender.enabled" = true;
    };
  }

  (mkIf (elem "gpu/nvidia/kepler" hardware) {
    # Last one supporting Kepler architecture
    hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
  })

  (mkIf (elem "gpu/nvidia/turing" hardware) {
    # see NixOS/nixos-hardware#348
    hardware.nvidia = {
      powerManagement.finegrained = true;
      nvidiaPersistenced = true;
    };
  })
])
