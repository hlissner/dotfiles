# test/nixos/modules/plymouth.nix --- tests for modules/hyprland/plymouth.nix
#
# Almost everything here is a boot-time setting, which means a regression shows
# up as a black screen or a wall of kernel log on the next reboot rather than as
# a failed build. The nvidia branch is the fragile part: it reaches into
# hardware.nvidia, which a host sets from its own profile, so the two can drift
# apart silently.

{ evalConfig, lib, ... }:

with lib;
let
  on = evalConfig [{ modules.hyprland.plymouth.enable = true; }];

  # Driven through the hardware profile, the way a real host turns this on.
  nvidia = evalConfig [{
    modules.hyprland.plymouth.enable = true;
    modules.profiles.hardware = [ "gpu/nvidia" ];
  }];

  nvidiaModules = config:
    filter (hasPrefix "nvidia") config.boot.initrd.kernelModules;

  # Store paths, so these compare without anything being built.
  initrdConf = config:
    "${config.boot.initrd.systemd.contents."/etc/plymouth/plymouthd.conf".source}";
  etcConf = config: "${config.environment.etc."plymouth/plymouthd.conf".source}";

  # Warnings are asserted by count against the plain case, never by message.
  warns = config: length config.warnings > length on.warnings;

  seamless = evalConfig [{
    modules.hyprland.enable = true;
    modules.hyprland.plymouth.enable = true;
    modules.hyprland.plymouth.seamless = true;
  }];
in {
  ## The nvidia branch.

  # The whole point of the branch: without nvidia_drm in stage 1 there is no
  # KMS device for Plymouth to draw on, so it falls back to the firmware
  # framebuffer and the splash resizes mid-boot. The scripted initrd carries
  # no modprobe.d, so modeset has to ride the command line too.
  testNvidiaProfileLoadsDrmInStage1 = {
    expr = {
      without = nvidiaModules on;
      drm     = elem "nvidia_drm" (nvidiaModules nvidia);
      modeset = elem "nvidia_drm.modeset=1" nvidia.boot.kernelParams;
    };
    expected = { without = []; drm = true; modeset = true; };
  };

  # Stating modeset=1 with the driver's own KMS turned off would be a lie, so
  # the params drop out and a warning takes their place.
  testNvidiaWithoutModesettingWarnsInsteadOfLying =
    let c = evalConfig [{
          modules.hyprland.plymouth.enable = true;
          modules.hyprland.plymouth.nvidia = true;
          hardware.nvidia.modesetting.enable = false;
        }];
    in {
      expr = {
        params = filter (hasPrefix "nvidia") c.boot.kernelParams;
        warns = warns c;
      };
      expected = { params = []; warns = true; };
    };

  # nixpkgs writes DeviceTimeout above boot.plymouth.extraConfig, so the
  # module rewrites the initrd's copy of the file (there's a grep at build
  # time too). A scripted stage 1 ignores boot.initrd.systemd.contents, so
  # there it can only warn.
  testNvidiaRewritesTheInitrdConf =
    let scripted = evalConfig [{
          modules.hyprland.plymouth.enable = true;
          modules.profiles.hardware = [ "gpu/nvidia" ];
          boot.initrd.systemd.enable = false;
        }];
    in {
      expr = {
        rewritten = initrdConf nvidia != etcConf nvidia;
        untouched = initrdConf on == etcConf on;
        quiet = warns nvidia;
        loud = warns scripted;
      };
      expected = { rewritten = true; untouched = true; quiet = false; loud = true; };
    };

  ## The handoff to greetd.

  # systemd ignores a drop-in that sets ExecStart without clearing it first, so
  # the empty string is load-bearing, not a formatting quirk.
  testSeamlessClearsExecStartBeforeRetainingTheSplash =
    let exec = seamless.systemd.services.plymouth-quit.serviceConfig.ExecStart; in {
      expr = {
        cleared = head exec;
        retains = any (hasSuffix "plymouth quit --retain-splash") exec;
      };
      expected = { cleared = ""; retains = true; };
    };

  ## The stage-1 password agent, without which a LUKS prompt lands under the
  ## splash instead of in it.

  testInitrdAsksForPasswordsThroughPlymouth = {
    expr = {
      service = on.boot.initrd.systemd.services.systemd-ask-password-plymouth.wantedBy;
      path    = on.boot.initrd.systemd.paths.systemd-ask-password-plymouth.wantedBy;
    };
    expected = { service = [ "sysinit.target" ]; path = [ "sysinit.target" ]; };
  };
}
