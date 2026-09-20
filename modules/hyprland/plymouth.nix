# modules/hyprland/plymouth.nix
#
# Make booting up pretty.

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.hyprland.plymouth;
    nvidia = config.hardware.nvidia;
in {
  options.modules.hyprland.plymouth = with types; {
    enable = mkBoolOpt false;

    theme = mkOpt' str "nixos-bgrt"
      "Splash theme to boot with. Must be shipped by one of `themePackages`.";

    themePackages = mkOpt' (listOf package) [ pkgs.nixos-bgrt-plymouth ]
      "Packages searched for `theme`. The default ships the spinning NixOS logo.";

    logo = mkOpt' path
      "${pkgs.nixos-icons}/share/icons/hicolor/256x256/apps/nix-snowflake-white.png"
      ''
        Logo for themes that take one (bgrt, spinner, spinfinity, breeze). The
        nixos-bgrt default ships its own logo as the throbber and ignores this.
      '';

    quiet = mkOpt' bool true
      "Silence kernel, initrd and udev, so they don't trample the boot screen.";

    seamless = mkOpt' bool false ''
      Hold the last splash frame on screen until the compositor paints over it,
      instead of dropping back to a bare console for the second or two greetd
      needs to bring the session up.
    '';

    nvidia = mkOpt' bool (any (s: hasPrefix "gpu/nvidia" s) config.modules.profiles.hardware)
      "Load the nvidia DRM driver in the initrd, so the splash starts at native resolution.";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      boot.plymouth = {
        enable = true;
        inherit (cfg) theme themePackages logo;
        # Password prompts and status messages render in this; match the sans
        # the desktop uses so the handoff to greetd isn't jarring.
        font = "${pkgs.fira}/share/fonts/truetype/FiraSans-Regular.ttf";
      };

      # Have plymouth handle passphrase prompts for encrypted volumes.
      boot.initrd.systemd = {
        services.systemd-ask-password-plymouth.wantedBy = [ "sysinit.target" ];
        paths.systemd-ask-password-plymouth.wantedBy = [ "sysinit.target" ];
      };

      # Make sure plymouth doesn't kick in on shut-down before the user session
      # is over. Giving us time to create a nice "fade out" transition (see
      # hey-shutdown-hook in ./default.nix).
      systemd.services = genAttrs
        [ "plymouth-poweroff" "plymouth-reboot" "plymouth-halt" "plymouth-kexec" ]
        (_: { after = [ "user.slice" ]; });
    }

    # On Nvidia cards, the transitions between initrd, plymouth, the greeter,
    # and hyprland are *much* more visible (monitors flicker off then on). This
    # addresses the flicker between initrd and plymouth.
    (mkIf cfg.nvidia {
      boot.initrd.systemd.contents."/etc/plymouth/plymouthd.conf".source =
        mkForce
          # Can't use boot.plymouth.extraConfig because nixpkgs writes its
          # DeviceTimeout above it.
          (let original = config.environment.etc."plymouth/plymouthd.conf".source;
           in pkgs.runCommand "plymouthd.conf" { } ''
             grep -q '^DeviceTimeout=' ${original} || {
               echo "no DeviceTimeout= in nixpkgs' plymouthd.conf; this override is stale" >&2
               exit 1
             }
             sed 's|^DeviceTimeout=.*|DeviceTimeout=20|' ${original} >$out
          '');

      warnings = optional (!config.boot.initrd.systemd.enable) ''
        modules.hyprland.plymouth.nvidia can't override the DeviceTimeout
        without config.boot.initrd.systemd.enable, which is off.
      '';
    })

    (mkIf cfg.quiet {
      boot = {
        # boot.plymouth already contributes "splash".
        kernelParams = [
          "quiet"
          "loglevel=3"
          "systemd.show_status=false"
          "rd.systemd.show_status=false"
          "rd.udev.log_level=3"
          "udev.log_priority=3"
        ];
        consoleLogLevel = 0;
        initrd.verbose = false;
      };

      environment.sessionVariables.UWSM_SILENT_START = "1";

      systemd.services.greetd.preStart = mkBefore ''
        # Clear any TTY output from before this point for a clean boot.
        printf '\033[2J\033[3J\033[H' > /dev/tty1 || true
      '';
    })

    (mkIf cfg.seamless {
      # --retain-splash leaves the last frame on the framebuffer until something
      # --modesets over it.
      systemd.services.plymouth-quit.serviceConfig.ExecStart = [
        ""  # Clear ExecStart before it can be replaced
        "${getExe' config.boot.plymouth.package "plymouth"} quit --retain-splash"
      ];

      # Hide the console's blinking cursor from the retained frame.
      boot.kernelParams = [ "vt.global_cursor_default=0" ];
    })

    (mkIf cfg.nvidia {
      # nvidia_uvm isn't required here, but stage-2 modules are loaded together
      # and loading it early keeps CUDA from re-probing later.
      boot.initrd.kernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];

      boot.kernelParams =
        optionals nvidia.modesetting.enable
          ([ "nvidia_drm.modeset=1" ]
           ++ optional (versionAtLeast nvidia.package.version "545") "nvidia_drm.fbdev=1");

      warnings = optional (!nvidia.modesetting.enable) ''
        modules.hyprland.plymouth.nvidia is on, but hardware.nvidia.modesetting.enable
        is off. The nvidia driver publishes no KMS device without it, so Plymouth will
        fall back to the firmware framebuffer and the splash will change resolution
        mid-boot.
      '';
    })
  ]);
}
