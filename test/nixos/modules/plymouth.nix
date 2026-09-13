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
  off = evalConfig [];

  on = evalConfig [{ modules.hyprland.plymouth.enable = true; }];

  # Driven through the hardware profile, the way a real host turns this on.
  nvidia = evalConfig [{
    modules.hyprland.plymouth.enable = true;
    modules.profiles.hardware = [ "gpu/nvidia" ];
  }];

  nvidiaModules = config:
    filter (hasPrefix "nvidia") config.boot.initrd.kernelModules;

  nvidiaParams = config:
    filter (hasPrefix "nvidia") config.boot.kernelParams;

  # Same, on a scripted stage 1, which ignores boot.initrd.systemd.contents.
  nvidiaScripted = evalConfig [{
    modules.hyprland.plymouth.enable = true;
    modules.profiles.hardware = [ "gpu/nvidia" ];
    boot.initrd.systemd.enable = false;
  }];

  # Store paths, so these compare without anything being built.
  initrdConf = config:
    "${config.boot.initrd.systemd.contents."/etc/plymouth/plymouthd.conf".source}";

  etcConf = config: "${config.environment.etc."plymouth/plymouthd.conf".source}";

  warnsAboutTheTimeout = config:
    any (hasInfix "can't override the DeviceTimeout") config.warnings;

  # The handoff tests need the full desktop, since greetd is what the splash is
  # handing the screen to.
  seamlessOff = evalConfig [{
    modules.hyprland.enable = true;
    modules.hyprland.plymouth.enable = true;
  }];

  seamless = evalConfig [{
    modules.hyprland.enable = true;
    modules.hyprland.plymouth.enable = true;
    modules.hyprland.plymouth.seamless = true;
  }];

  seamlessExecStart = seamless.systemd.services.plymouth-quit.serviceConfig.ExecStart;
in {
  # The module sits under modules.hyprland, but it is not wired to
  # modules.hyprland.enable; a desktop host has to ask for the splash.
  testEnableTurnsOnPlymouth = {
    expr = on.boot.plymouth.enable;
    expected = true;
  };

  ## The theme.

  # plymouth's own build-time guard only checks that cfg.theme exists in
  # cfg.themePackages, so a theme renamed upstream fails at switch time rather
  # than here. Pin both halves.
  testDefaultThemeIsTheNixosLogo = {
    expr = on.boot.plymouth.theme;
    expected = "nixos-bgrt";
  };

  testDefaultThemePackageShipsThatTheme = {
    expr = map (p: p.pname or p.name) on.boot.plymouth.themePackages;
    expected = [ "nixos-bgrt-plymouth" ];
  };

  ## Silent boot.

  # Without 'quiet' the kernel scrolls its log straight over the splash, which
  # defeats the whole point of drawing one.
  testQuietSilencesTheKernel = {
    expr = elem "quiet" on.boot.kernelParams && on.boot.consoleLogLevel == 0;
    expected = true;
  };

  testQuietIsOptOut = {
    expr = elem "quiet" (evalConfig [{
      modules.hyprland.plymouth.enable = true;
      modules.hyprland.plymouth.quiet = false;
    }]).boot.kernelParams;
    expected = false;
  };

  # boot.plymouth contributes this itself, so the module must not add a second.
  testSplashIsNotDuplicated = {
    expr = length (filter (p: p == "splash") on.boot.kernelParams);
    expected = 1;
  };

  ## The nvidia branch.

  testNvidiaOffWithoutTheHardwareProfile = {
    expr = on.modules.hyprland.plymouth.nvidia;
    expected = false;
  };

  testNvidiaFollowsTheHardwareProfile = {
    expr = nvidia.modules.hyprland.plymouth.nvidia;
    expected = true;
  };

  testNoNvidiaModulesInInitrdWithoutNvidia = {
    expr = nvidiaModules on;
    expected = [];
  };

  # This is the whole point of the branch: without nvidia_drm in stage 1 there
  # is no KMS device for Plymouth to draw on, so it falls back to the firmware
  # framebuffer and the splash resizes mid-boot.
  testNvidiaLoadsDrmInTheInitrd = {
    expr = sort lessThan (nvidiaModules nvidia);
    expected = [ "nvidia" "nvidia_drm" "nvidia_modeset" "nvidia_uvm" ];
  };

  # The scripted initrd carries no modprobe.d, so hardware.nvidia's modeset
  # option would not reach stage 1 on the command line alone.
  testNvidiaSetsModesetOnTheKernelCmdline = {
    expr = elem "nvidia_drm.modeset=1" (nvidiaParams nvidia);
    expected = true;
  };

  # Stating modeset=1 with the driver's own KMS turned off would be a lie, so
  # the params drop out and a warning takes their place.
  testNvidiaStaysQuietWithoutModesetting = {
    expr = nvidiaParams (evalConfig [{
      modules.hyprland.plymouth.enable = true;
      modules.hyprland.plymouth.nvidia = true;
      hardware.nvidia.modesetting.enable = false;
    }]);
    expected = [];
  };

  testNvidiaWarnsWithoutModesetting = {
    expr = length (evalConfig [{
      modules.hyprland.plymouth.enable = true;
      modules.hyprland.plymouth.nvidia = true;
      hardware.nvidia.modesetting.enable = false;
    }]).warnings;
    expected = 1;
  };

  ## plymouthd.conf.
  #
  # nixpkgs writes DeviceTimeout above boot.plymouth.extraConfig, so the module
  # replaces the line in the generated file. I don't want to trigger a build
  # just to test it so I only check for
  # `config.environment.etc."plymouth/plymouthd.conf".source`s presence given
  # certain configurations. There's a grep check at build time too.

  testNvidiaRewritesTheInitrdConf = {
    expr = initrdConf nvidia != etcConf nvidia;
    expected = true;
  };
  testNoNvidiaLeavesTheInitrdConfAlone = {
    expr = initrdConf on == etcConf on;
    expected = true;
  };
  testTheEtcConfIsLeftToNixpkgs = {
    expr = etcConf nvidia == etcConf on;
    expected = true;
  };
  testScriptedInitrdWarnsTheTimeoutWontApply = {
    expr = warnsAboutTheTimeout nvidiaScripted;
    expected = true;
  };
  testSystemdInitrdSaysNothing = {
    expr = warnsAboutTheTimeout nvidia;
    expected = false;
  };

  ## The handoff to greetd.

  testSeamlessIsOptIn = {
    expr = on.modules.hyprland.plymouth.seamless;
    expected = false;
  };

  # Off, the packaged unit stands: a bare `plymouth quit` that releases the VT
  # to the text console while greetd is still starting the compositor.
  testDefaultLeavesTheQuitUnitAlone = {
    expr = seamlessOff.systemd.services.plymouth-quit.serviceConfig ? ExecStart;
    expected = false;
  };

  # systemd ignores a drop-in that sets ExecStart without clearing it first, so
  # the empty string is load-bearing, not a formatting quirk.
  testSeamlessClearsExecStartBeforeReplacingIt = {
    expr = head seamlessExecStart;
    expected = "";
  };

  testSeamlessRetainsTheSplash = {
    expr = any (hasSuffix "plymouth quit --retain-splash") seamlessExecStart;
    expected = true;
  };

  # A blinking console cursor would otherwise sit on top of the retained frame
  # for the whole handoff.
  testSeamlessHidesTheConsoleCursor = {
    expr = elem "vt.global_cursor_default=0" seamless.boot.kernelParams;
    expected = true;
  };

  testCursorStaysDefaultWithoutSeamless = {
    expr = filter (hasPrefix "vt.") seamlessOff.boot.kernelParams;
    expected = [];
  };

  ## The stage-1 password agent

  testInitrdAsksForPasswordsThroughPlymouth = {
    expr = on.boot.initrd.systemd.services.systemd-ask-password-plymouth.wantedBy;
    expected = [ "sysinit.target" ];
  };

  testInitrdWatchesForPasswordRequests = {
    expr = on.boot.initrd.systemd.paths.systemd-ask-password-plymouth.wantedBy;
    expected = [ "sysinit.target" ];
  };

  # Ensure upstream doesn't change this.
  testPasswordAgentIsOnlyADropin = {
    expr = on.boot.initrd.systemd.units."systemd-ask-password-plymouth.service".overrideStrategy;
    expected = "asDropinIfExists";
  };

  testPasswordAgentHasNoExecStartOfItsOwn = {
    expr = hasInfix "ExecStart"
      on.boot.initrd.systemd.units."systemd-ask-password-plymouth.service".text;
    expected = false;
  };

  testNoPasswordAgentWithoutPlymouth = {
    expr = off.boot.initrd.systemd.units ? "systemd-ask-password-plymouth.service";
    expected = false;
  };
}
