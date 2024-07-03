{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.services.wlsunset;
in {
  options.modules.services.wlsunset = with types; {
    enable = mkBoolOpt false;
    package = mkOpt package (pkgs.wlsunset.overrideAttrs (final: prev: rec {
      version = "0.4.0";
      src = pkgs.fetchFromSourcehut {
        owner = "~kennylevinsen";
        repo = prev.pname;
        rev = version;
        sha256 = "sha256-U/yROKkU9pOBLIIIsmkltF64tt5ZR97EAxxGgrFYwNg=";
      };
    }));
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.modules.desktop.type == "wayland";
        message = "wlsunset requires a wayland desktop";
      }
      {
        assertion = config.location.latitude != null && config.location.longitude != null;
        message = "Coordinations not set";
      }
    ];

    systemd.user.services.wlsunset = {
      unitConfig = {
        PartOf = [ "graphical-session.target" ];
      };
      serviceConfig = {
        ExecStart =
          let lat = toString config.location.latitude;
              lng = toString config.location.longitude;
          in "${cfg.package}/bin/wlsunset -l ${lat} -L ${lng}";
        Restart = "on-failure";
        KillMode = "mixed";
      };
      wantedBy = [ "graphical-session.target" ];
    };

    # Restarting wlsunset can crash hyprland.
    # hey.hooks.reload."98-wlsunset" = ''
    #   hey.do systemctl --user restart wlsunset.service
    # '';
  };
}
