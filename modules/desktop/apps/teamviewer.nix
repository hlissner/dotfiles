# modules/desktop/apps/teamviewer.nix --- for my parental SOSes
#
# You know the feeling. It's 4am, you get a phone call. It's your parents in
# another timezone and their printer/email/something has stopped working, and
# you're the family computer guy (my condolences). Cue teamviewer.

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.apps.teamviewer;
in {
  options.modules.desktop.apps.teamviewer = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      # I am aware of services.teamviewer, and choose to avoid it so I can
      # lazily start (and shut down) the teamviewer daemon. I rarely use
      # teamviewr, and don't want the daemon running when it's unused.
      (mkWrapper pkgs.teamviewer ''
        wrapProgram "$out/bin/teamviewer"
          --run 'systemctl start teamviewerd' \
          --run 'trap "systemctl stop teamviewerd" EXIT'
      '')
    ];

    services.dbus.packages = [ pkgs.teamviewer ];

    systemd.services.teamviewerd = {
      description = "TeamViewer remote control daemon";
      requires = [ "dbus.service" ];
      preStart = "mkdir -pv /var/lib/teamviewer /var/log/teamviewer";
      startLimitIntervalSec = 60;
      startLimitBurst = 10;
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.teamviewer}/bin/teamviewerd -f";
        PIDFile = "/run/teamviewerd.pid";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "on-abort";
      };
    };
  };
}
