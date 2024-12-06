{ hey, lib, options, config, pkgs, ... }:

with lib;
with hey.lib;
mkMerge [
  (mkIf (any (s: hasPrefix "audio" s) config.modules.profiles.hardware) {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # sound.enable = false;
    security.rtkit.enable = true;
    user.extraGroups = [ "audio" ];

    ## easyEffects
    programs.dconf.enable = true;
    user.packages = with pkgs; [
      alsa-utils  # for CLI utilities
      pavucontrol
      easyeffects
      pulseaudio  # for pactl
      # Not strictly needed, but it silences DBus error noise in journalctl. The
      # error can be ignored, in any case, as easyeffects attachs to the
      # gapplication service.
      at-spi2-core
    ];
    systemd.user.services.easyeffects = {
      wantedBy = [ "graphical-session.target" ];
      unitConfig = {
        Description = "Easyeffects daemon";
        Requires = [ "dbus.service" ];
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" "pipewire.service" ];
      };
      serviceConfig = {
        ExecStart = "${pkgs.easyeffects}/bin/easyeffects --gapplication-service";
        ExecStop = "${pkgs.easyeffects}/bin/easyeffects --quit";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    # Disable Pulseaudio because Pipewire is used.
    hardware.pulseaudio.enable = lib.mkForce false;

    # HACK: Prevent ~/.esd_auth files by disabling the esound protocol module
    #   for pulseaudio, which I likely don't need. Is there a better way?
    hardware.pulseaudio.configFile =
      let inherit (pkgs) runCommand pulseaudio;
          paConfigFile =
            runCommand "disablePulseaudioEsoundModule"
              { buildInputs = [ pulseaudio ]; } ''
                mkdir "$out"
                cp ${pulseaudio}/etc/pulse/default.pa "$out/default.pa"
                sed -i -e 's|load-module module-esound-protocol-unix|# ...|' "$out/default.pa"
              '';
      in mkIf config.hardware.pulseaudio.enable
        "${paConfigFile}/default.pa";
  })

  (mkIf (elem "audio/realtime" config.modules.profiles.hardware) {
    services.pipewire.wireplumber.enable = true;

    # boot = {
    #   kernel.sysctl."vm.swappiness" = 10;
    #   kernelModules = [ "snd-seq" "snd-rawmidi" ];
    #   kernelParams = [ "threadirqs" ];
    #   postBootCommands = ''
    #     echo 2048 > /sys/class/rtc/rtc0/max_user_freq
    #     echo 2048 > /proc/sys/dev/hpet/max-user-freq
    #     setpci -v -d *:* latency_timer=b0
    #   '';
    # };

    # security.pam.loginLimits = [
    #   { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    #   { domain = "@audio"; item = "rtprio"; type = "-"; value = "99"; }
    #   { domain = "@audio"; item = "nofile"; type = "soft"; value = "99999"; }
    #   { domain = "@audio"; item = "nofile"; type = "hard"; value = "99999"; }
    # ];

    # services.udev.extraRules = ''
    #   KERNEL=="rtc0", GROUP="audio"
    #   KERNEL=="hpet", GROUP="audio"
    # '';
  })
]
