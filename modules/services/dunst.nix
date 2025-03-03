{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.services.dunst;
    eitherStrBoolIntList = with types;
      either str (either bool (either int (listOf str)));
    toDunstIni = generators.toINI {
      mkKeyValue = key: value:
        let value' =
              if isBool value then
                (if value then "yes" else "no")
              else if isString value then
                ''"${value}"''
              else
                toString value;
        in "${key}=${value'}";
    };
in {
  options.modules.services.dunst = with types; {
    enable = mkBoolOpt false;
    settings = mkOpt (attrsOf (attrsOf eitherStrBoolIntList)) {};
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.dunst ];

    systemd.user.services.dunst = {
      enable = true;
      unitConfig = {
        Description = "Dunst notification daemon";
        After  = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      serviceConfig = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";
        ExecStart = "${pkgs.dunst}/bin/dunst";
      };
    };

    home.dataFile."dbus-1/services/org.knopwob.dunst.service".source =
      "${pkgs.dunst}/share/dbus-1/services/org.knopwob.dunst.service";

    home.configFile."dunst/dunstrc" = {
      text = toDunstIni (mergeAttrs' [
        {
          global = {
            title = "Dunst";
            class = "Dunst";
            browser = "librewolf -new-tab";
            dmenu = "rofi -dmenu -p dunst";
            history_length = 20;
            idle_threshold = 120;
            markup = "full";
            sort = true;
            sticky_history = true;
            progress_bar = true;
            indicate_hidden = true;
            notification_limit = 0;
            monitor = 0;
          };
          experimental = {
            enable_recursive_icon_lookup = true;
          };
        }
        cfg.settings
      ]);
      onChange = ''
        ${pkgs.procps}/bin/pkill -u "$USER" ''${VERBOSE+-e} dunst || true
      '';
    };
  };
}
