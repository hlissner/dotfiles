# modules/wm/default.nix
#
# Common settings shared across all supported window managers.

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.wm;
in {
  options.modules.wm = with types; {
    desktop = mkOpt' (nullOr (enum [
      "niri"
    ])) null
      "The window manager to install. Enables modules.wm.<desktop>.";

    # The WM fills these from its own `monitors` option, whose schema is its
    # own; the WM translates, not this.
    primaryMonitor = mkOpt' (nullOr str) null
      "The output marked primary in modules.wm.<desktop>.monitors, or null.";
    outputs = mkOpt' (listOf str) []
      "Every named output in modules.wm.<desktop>.monitors, disabled ones included.";

    session = {
      name = mkOpt' (nullOr str) null
        "services.displayManager session id, e.g. niri.";
      desktopName = mkOpt' (nullOr str) null
        "The desktop entry's Name=, which noctalia-greeter selects sessions by.";
      unit = mkOpt' (nullOr str) null
        "The user unit the compositor runs as; hey-shutdown-hook orders itself after it.";
      command = mkOpt' (nullOr str) null
        "A greetd-ready command that starts the session, for autologin hosts.";
    };
  };

  config = mkMerge [
    {
      hey.desktop = cfg.desktop;

      # Every modules.wm.* is downstream of the desktop
      assertions =
        let enabled = attrNames (filterAttrs (_: m: isAttrs m && m.enable or false) cfg);
        in [{
          assertion = cfg.desktop != null || enabled == [];
          message = ''
            modules.wm.{${concatStringsSep "," enabled}} can't be enabled without a
            desktop; set modules.wm.desktop.
          '';
        }];
    }

    (mkIf (cfg.desktop != null) (mkMerge [
      {
        assertions = [{
          assertion = cfg.primaryMonitor != "";
          message = "modules.wm.${cfg.desktop}.monitors: the primary monitor needs an `output`.";
        }];

        hey.info.wm = { inherit (cfg) primaryMonitor outputs; };

        # nixpkgs' greetd doesn't respect services.displayManager.autoLogin
        # without this.
        services.greetd.settings.initial_session =
          let auto = config.services.displayManager.autoLogin;
          in mkIf (config.services.greetd.enable && auto.enable) {
            inherit (auto) user;
            command = cfg.session.command;
          };

        environment.sessionVariables = {
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
          NIXOS_OZONE_WL = "1";
          MOZ_ENABLE_WAYLAND = "1";
        };
      }

      ## For CLIs
      {
        environment.systemPackages = with pkgs; [
          wlr-randr      # for monitors the compositor's own tooling can't handle
          wf-recorder    # for screencasting
          quickshell     # for screencast's region indicator
          slurp          # slop
          grim           # screenshot
          ripdrag        # Replaces xdragon
          wev            # Replaces xev
          wl-clipboard   # Replaces xclip
          wtype          # Replaces xdotool (sorta)
          swayimg        # Replaces feh (as an image previewer)
          libnotify      # notify-send
          xdg-utils
          sox            # for `play` utility
        ];

        user.packages = map (fmt:
          mkLauncherEntry "Color picker: grab ${fmt} at point" {
            icon = "com.github.finefindus.eyedropper";
            exec = "${getExe pkgs.hyprpicker} -a -f ${toLower fmt}";
          }) [ "RGB" "HSL" "hex" ];

        home.configLink."swayimg" = "${config.hey.configDir}/swayimg";
      }

      ## The session's edges.
      {
        # Implement a nice "fade out" transition when shutting down/rebooting
        # the system that responds to all entry points (`systemctl poweroff`,
        # critical battery, ssh reboot, etc).
        systemd.user.services.hey-shutdown-hook = {
          description = "Run hey's shutdown hooks before the session dies";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          restartIfChanged = false;   # don't trigger on `hey sync`
          after = [
            "graphical-session.target"
            "noctalia.service"                     # the toast
            "pipewire.service"                     # the sound; sox goes out
            "pipewire-pulse.service"               # through the pulse shim
          ] ++ optional (cfg.session.unit != null)
            cfg.session.unit;                      # the compositor, for the fade
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${getExe' pkgs.coreutils "true"}";
            ExecStop = "${config.hey.bin} hook -f on-shutting-down";
            TimeoutStopSec = 15;  # careful not to delay shutdown indefinitely
          };
        };

        # Trigger `hey hook on-{suspend,wakeup}` hooks as user.
        systemd.services.hey-sleep-hook =
          let run = hook: ''
                ${pkgs.systemd}/bin/systemd-run --machine=${config.user.name}@.host \
                  --user --pipe --wait --collect --quiet \
                  ${config.hey.bin} hook -f ${hook} || true
              '';
          in {
            description = "Run hey's sleep hooks around suspend";
            wantedBy = [ "sleep.target" ];
            before = [ "sleep.target" ];
            # So resuming stops the unit, and stopping it is what runs on-wakeup.
            unitConfig.StopWhenUnneeded = true;
            script = run "on-suspend";
            preStop = run "on-wakeup";
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              # systemd-run --wait blocks; a wedged hook must not hold the lid.
              TimeoutStartSec = 15;
              TimeoutStopSec = 15;
            };
          };
      }
    ]))
  ];
}
