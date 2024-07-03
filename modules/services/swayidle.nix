{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.services.swayidle;
in {
  options.modules.services.swayidle = with types; {
    enable = mkBoolOpt false;
    package = mkOpt package pkgs.swayidle;
    events = mkOpt (attrsOf str) {};
    timeouts = mkOpt (listOf (submodule {
      options = {
        timeout = mkOpt int 0;
        command = mkOpt str "";
        resume = mkOpt str "";
      };
    })) [];
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.modules.desktop.type == "wayland";
        message = "swayidle requires a wayland desktop";
      }
    ];

    systemd.user.services.swayidle = {
      unitConfig = {
        Description = "Idle manager for Wayland";
        PartOf = [ "graphical-session.target" ];
      };
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        ExecStart = "${cfg.package}/bin/swayidle -w";
      };
      wantedBy = [ "graphical-session.target" ];
    };

    home.configFile."swayidle/config".text =
      let mkTimeout = t:
            concatStringsSep " "
              ([ "timeout" (toString t.timeout) (escapeShellArg t.command) ]
               ++ (optionals (t.resume != "") [ "resume" (escapeShellArg t.resume) ]));
          mkEvent = evt: cmd: "${evt} ${escapeShellArg cmd}";
      in ''
        ${concatStringsSep "\n" (mapAttrsToList mkEvent cfg.events)}
        ${concatMapStringsSep "\n" mkTimeout cfg.timeouts}
      '';

    hey.hooks.reload."98-swayidle" = ''
      hey.do systemctl --user restart swayidle.service
    '';
  };
}
