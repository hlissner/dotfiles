# profiles/hardware/common/gpu/nvidia/default.nix --- lipstick on a pig
#
# I use NVIDIA cards on all my machines, largely because I'm locked into CUDA
# for work reasons. Fortunately, mine aren't too old and are relatively beefy
# (680gtx, 960gtx, 1080, 1660S, 3080ti) so only a little cludge is needed to get
# them to work well on NixOS.

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let hardware = config.modules.profiles.hardware;
in mkIf (any (s: hasPrefix "gpu/nvidia" s) hardware) (mkMerge [
  {
    services.xserver.videoDrivers = mkDefault [ "nvidia" ];

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = [ pkgs.vaapiVdpau ];
      };
      nvidia = {
        # Use the NVidia open source kernel module (not to be confused with the
        # independent third-party "nouveau" open source driver). Support is
        # limited to the Turing and later architectures. Full list of supported
        # GPUs is at:
        # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
        # Only available from driver 515.43.04+. Currently alpha-quality/buggy,
        # so false is currently the recommended setting.
        open = mkDefault true;
        # Save some idle watts.
        powerManagement.enable = true;  # see NixOS/nixos-hardware#348
        modesetting.enable = true;
        package = config.boot.kernelPackages.nvidiaPackages.beta;
      };
    };

    # REVIEW: Remove when NixOS/nixpkgs#324921 is backported to stable
    boot.kernelParams = [ "nvidia-drm.fbdev=1" ];

    environment = {
      systemPackages = with pkgs; [
        # Respect XDG conventions, damn it!
        (mkWrapper config.hardware.nvidia.package.settings ''
          wrapProgram "$out/bin/nvidia-settings" \
            --run 'mkdir -p "$XDG_CONFIG_HOME/nvidia"' \
            --append-flags '--config="$XDG_CONFIG_HOME/nvidia/rc.conf"'
        '')

        cudaPackages.cudatoolkit  # required for CUDA support
      ];
      variables = {
        CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
        CUDA_CACHE_PATH = "$XDG_CACHE_HOME/nv";

        # $EXTRA_LDFLAGS and $EXTRA_CCFLAGS are sometimes necessary too, but I
        # set those in nix-shells instead.
      };
    };

    # Cajole Firefox into video-acceleration (or try).
    modules.desktop.browsers.librewolf.settings = {
      "media.ffmpeg.vaapi.enabled" = true;
      "gfx.webrender.enabled" = true;
    };
  }

  (mkIf (elem "gpu/nvidia/kepler" hardware) {
    # Last one supporting Kepler architecture
    hardware.nvidia = {
      open = mkForce false;
      package = mkForce config.boot.kernelPackages.nvidiaPackages.legacy_470;
    };
  })

  (mkIf (elem "gpu/nvidia/turing" hardware) {
    # see NixOS/nixos-hardware#348
    hardware.nvidia = {
      powerManagement.finegrained = true;
      nvidiaPersistenced = true;
    };
  })

  (mkIf (config.modules.desktop.type == "wayland") {
    # see NixOS/nixos-hardware#348
    # TODO: Try these!
    environment.systemPackages = with pkgs; [
      libva
      # Fixes crashes in Electron-based apps?
      # libsForQt5.qt5ct
      # libsForQt5.qt5-wayland
    ];

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";

      # May cause Firefox crashes
      GBM_BACKEND = "nvidia-drm";

      # If you face problems with Discord windows not displaying or screen
      # sharing not working in Zoom, remove or comment this:
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };
  })
])
