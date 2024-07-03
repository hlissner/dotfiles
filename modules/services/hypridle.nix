# TODO

{ hey, lib, config, options, ... }:

with lib;
with hey.lib;
let cfg = config.modules.services.swayidle;
in {
  options.modules.services.hypridle = with types; {
    enable = mkBoolOpt false;
    settings = mkOpt (attrs) {};
    listeners = mkOpt (listOf (submodule {
      options = {
        timeout = mkOpt int 0;
        on-timeout = mkOpt str "";
        on-resume = mkOpt str "";
      };
    })) {};
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.modules.desktop.hyprland.enable;
        message = "hypridle requires the Hyprland desktop";
      }
    ];

    nixpkgs.overlays = [
      self.inputs.hypridle.overlays.default
    ];

    systemd.user.services.swayidle = {
      unitConfig = {
        Description = "Idle manager for Hyprland";
        PartOf = [ "graphical-session.target" ];
      };
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        ExecStart = "${pkgs.hypridle}/bin/hypridle";
        RestartSec = "5";
      };
      wantedBy = [ "graphical-session.target" ];
    };

    home.configFile."hypr/hypridle.conf".text = ''
      general {
        ${concatStringsSep "\n"
          (mapAttrsToList (n: v: "${n} = ${toString v}") cfg.settings)}
      }

      ${concatMapStringSep "\n" (t: ''
        listener {
          ${optionalString (t.timeout > 0)      "timeout = ${toString t.timeout}"}
          ${optionalString (t.on-timeout != "") "on-timeout = ${t.on-timeout}"}
          ${optionalString (t.on-resume != "")  "on-resume = ${t.on-resume}"}
        }
      '') cfg.timeouts}
    '';
  };
}
