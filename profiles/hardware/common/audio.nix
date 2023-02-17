{ self, lib, options, config, pkgs, ... }:

with lib;
with self.lib;
{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true;
  };

  security.rtkit.enable = true;
  user.extraGroups = [ "audio" ];
  # for CLI volume control and volume persistence across reboots
  sound.enable = true;

  ## easyEffects
  programs.dconf.enable = true;
  user.packages = with pkgs; [
    easyeffects
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

  # HACK Prevents ~/.esd_auth files by disabling the esound protocol module for
  #      pulseaudio, which I likely don't need. Is there a better way?
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
}
