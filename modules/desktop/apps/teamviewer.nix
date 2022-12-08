# modules/desktop/app/teamviewer.nix --- for my parental SOSes
#
# You know the feeling. It's 4am, you get a phone call. It's your parents in
# another timezone and their printer/email/something has stopped working, and
# you're the family computer guy (my condolences). Cue teamviewer.

{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.app.teamviewer;
in {
  options.modules.desktop.app.teamviewer = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    # I replicate services.teamviewer here instead of using it because I don't
    # want teamviewerd auto-started or running all the time just for the once or
    # twice a month I use teamviewer.
    environment.systemPackages = [
      (writeShellScriptBin "teamviewer" ''
        servicectl start teamviewerd
        trap 'servicectl stop teamviewerd' EXIT
        exec ${pkgs.teamviewer}/bin/teamviewer "$@"
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
