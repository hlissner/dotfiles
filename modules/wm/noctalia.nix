# modules/wm/noctalia.nix
#
# Noctalia: the shell itself, its plugins, and the login screen it puts in front
# of them.

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.wm;
    # Published by whichever modules/wm/<desktop>/ is on (see ../default.nix).
    primaryMonitor = cfg.primaryMonitor;
    hasPrimary = primaryMonitor != null;
    otherOutputs = optionals hasPrimary (filter (o: o != primaryMonitor) cfg.outputs);

    package = self.inputs.noctalia.packages.default;
    format = pkgs.formats.toml {};
    # Disabled plugins are still installed, or Settings can't list them.
    installedPlugins = filterAttrs (_: p: p.src != null) cfg.noctalia.plugins;
    enabledPlugins = filterAttrs (_: p: p.enable) installedPlugins;

    # Two python3 derivations in systemPackages collide on bin/python3.
    python = pkgs.python3.withPackages (ps: [ ps.tomlkit ]);

    # Every leaf mkDefault'd, so a host can override one without dropping its
    # siblings (a mkDefault over the whole tree would).
    defaults = mapAttrsRecursive (_: mkDefault);
in {
  options.modules.wm.noctalia = with types; {
    settings = mkOpt' format.type {} ''
      Defaults for Noctalia. Higher precedence than config/noctalia/, but lower
      than $XDG_STATE_HOME/noctalia/.
    '';

    plugins = mkOpt' (attrsOf (submodule {
      options = {
        enable = mkBoolOpt true;
        src = mkOpt' (nullOr path) null "The plugin directory, holding plugin.toml";
      };
    })) {} ''Plugins, by id ("author/plugin").'';
  };

  config = mkIf (cfg.desktop != null) (mkMerge [
    ## Noctalia itself
    {
      programs.noctalia = {
        enable = true;
        systemd.enable = true;
        inherit package;
        # Avoid `recommendedServices` b/c I don't want NetworkManager
      };

      # HACK: uwsm (hyprland's session) scrubs XDG_SESSION_ID out of the user
      #   manager, so Noctalia can't see the logind session (breaking its
      #   brightness controls and loginctl/polkit interop). Harmless under a
      #   session that keeps it (niri-session does): same answer, twice.
      # REVIEW: Report upstream
      systemd.user.services.noctalia.serviceConfig.ExecStart = mkForce
        (pkgs.writeShellScript "noctalia-in-session" ''
          export XDG_SESSION_ID="$(${config.systemd.package}/bin/loginctl show-user "$UID" -p Display --value)"
          exec ${getExe package}
        '');

      # Used by noctalia's battery widgets
      services.upower.enable = true;
      services.power-profiles-daemon.enable = true;

      environment.systemPackages = with pkgs; [
        adw-gtk3  # the gtk templates point gtk-theme at it, if present
        python    # for hey @noctalia reset & some Noc plugins
      ];

      # For `hey @rofi iconmenu`
      home.dataFile."hey/tabler-icons".source =
        let src = pkgs.fetchFromGitHub {
              owner = "tabler"; repo = "tabler-icons";
              rev = "v3.34.0";
              sparseCheckout = [ "icons" ];   # 3.5M of a 50M repo
              hash = "sha256-oP6nfTHlMVT6nO+ntSQFewBT2hMCkm2rq4+pTlAtYs8=";
            };
        in pkgs.runCommand "tabler-icons" {} ''
          mkdir -p $out
          cp -t $out ${src}/icons/outline/*.svg
          for f in ${src}/icons/filled/*.svg; do
            cp "$f" "$out/$(basename "$f" .svg)-filled.svg"
          done
        '';

      modules.shell.zsh.rcFiles = [ "${config.hey.configDir}/noctalia/aliases.zsh" ];
      hey.hookPaths = [ "${config.hey.configDir}/noctalia/hooks" ];
    }

    ## Declarative noctalia config.toml
    {
      # A malformed config should fail `hey sync` immediately, not at next login
      home.configFile."noctalia/config.toml".source =
        let toml = format.generate "config.toml" cfg.noctalia.settings;
        in pkgs.runCommand "noctalia-config.toml" {} ''
          ${getExe package} config validate ${toml}
          cp ${toml} $out
        '';

      modules.wm.noctalia.settings = defaults {
        include.files = [ "${config.hey.configDir}/noctalia/" ];
        shell.font_family = config.hey.info.theme.fonts.sans;
      };
    }

    ## For location services, like weather reports
    (mkIf (config.time.timeZone != null) {
      modules.wm.noctalia.settings = defaults {
        location.address = config.time.timeZone;
      };
    })

    ## Plugins
    (let
      # One rev per repo, so nix-pull moves every plugin from it together.
      communityPlugins = pkgs.fetchFromGitHub {
        owner = "noctalia-dev"; repo = "community-plugins";
        rev = "a93979eaae71ce67715efefcb3835e53fb2b7264";
        hash = "sha256-h3AYoop84qzrmeFTstrWnkrbP0OFHKQu6SyPK84gTo8=";
      };
      hardware = config.modules.profiles.hardware;

      pluginDir = pkgs.linkFarm "noctalia-plugins"
        (mapAttrsToList (id: p: { name = baseNameOf id; path = p.src; })
          installedPlugins);
    in {
      modules.wm.noctalia.plugins = {
        ## My plugins (see config/noctalia/plugins/*/plugin.toml for why)
        "hey/peripheral-battery".src =
          "${config.hey.configDir}/noctalia/plugins/peripheral-battery";
        "hey/timer".src = "${config.hey.configDir}/noctalia/plugins/timer";
        "hey/screencast".src = "${config.hey.configDir}/noctalia/plugins/screencast";
        "hey/compass".src = "${config.hey.configDir}/noctalia/plugins/compass";

        ## 3rd-party plugins
        "h-jangra/keyviz" = {
          enable = mkDefault false;
          src = "${communityPlugins}/keyviz";
        };
        "davemhammer/tailscale" = {
          enable = mkDefault (elem "ts0" config.modules.profiles.networks);
          src = "${communityPlugins}/tailscale";
        };
        "icefish/phone-connect" = {
          enable = mkDefault config.programs.kdeconnect.enable;
          # HACK: Patching the phone-connect plugin to hide the widget if there
          #   are no active connections. Otherwise the widget shows an unhidable
          #   "offline" label in the bar. Half the community plugins already use
          #   `barWidget.setVisible` for this purpose, so...
          src = pkgs.runCommand "phone-connect" {} ''
            cp -r --no-preserve=mode ${communityPlugins}/phone-connect $out
            substituteInPlace $out/widget.luau --replace-fail \
              'local container = barWidget.isVertical()' \
              'barWidget.setVisible(d ~= nil and d.isPaired == true and d.isReachable == true) local container = barWidget.isVertical()'
          '';
        };
        "aristides/udiskie" = {
          enable = mkDefault config.services.udisks2.enable;
          src = "${communityPlugins}/udiskie";
        };

        "andrewdems/printers" = mkIf (any (s: hasPrefix "printer" s) hardware) {
          src = "${communityPlugins}/printers";
        };
        "8bury/lid-guard" = mkIf (any (s: hasPrefix "pc/laptop" s) hardware) {
          src = "${communityPlugins}/lid-guard";
        };
      };

      assertions = mapAttrsToList (id: p: {
        assertion = p.src != null;
        message = ''
          modules.wm.noctalia.plugins."${id}" is enabled but has no src.
          It's declared behind an `mkIf` this host doesn't satisfy, so turning
          it on means giving it a src too.
        '';
      }) (filterAttrs (_: p: p.enable) cfg.noctalia.plugins);

      modules.wm.noctalia.settings = defaults {
        plugins = {
          enabled = attrNames enabledPlugins;
          auto_update = "none";
          source = [{
            name = "nixos"; kind = "path"; enabled = true;
            location = "${pluginDir}";
          }];
        };
      };

      environment.systemPackages = with pkgs; [
        python   # for keyviz
      ] ++ optionals config.programs.kdeconnect.enable [
        glib     # gdbus
        sshfs    # its file browser
      ];

      user.extraGroups = [ "input" ];   # for keyviz
    })

    ## The bar
    (let baseline = fromTOML (readFile "${self.configDir}/noctalia/bar.toml");
         typeOf = w: baseline.widget.${w}.type or w;
         pluginOf = w:
           let type = typeOf w;
           in if hasInfix "/" type then head (splitString ":" type) else null;
           installed = w: let p = pluginOf w; in p == null || enabledPlugins ? ${p};
         # The built-in network widget doesn't hide if there's no wifi
         # interface, so I gotta disable it myself.
         applicable = w:
           # REVIEW: PR "hide when unused" setting for network widget
           typeOf w != "network" || elem "wifi" config.modules.profiles.hardware;
         keep = w: installed w && applicable w;
         # Take capsule groups into account!
         groups = filter (g: g.members != [])
           (map (g: g // { members = filter keep g.members; })
             (baseline.bar.main.capsule_group or []));
         groupIds = map (g: "group:${g.id}") groups;
         lanes = mapAttrs
           (_: filter (w: if hasPrefix "group:" w then elem w groupIds else keep w))
           (filterAttrs (k: _: elem k [ "start" "center" "end" ]) baseline.bar.main);
         otherMonitors = genAttrs otherOutputs (o: { match = o; enabled = false; });
    in {
      modules.wm.noctalia.settings = defaults {
        bar.main = lanes
          // optionalAttrs (baseline.bar.main ? capsule_group) { capsule_group = groups; }
          // optionalAttrs (otherMonitors != {}) { monitor = otherMonitors; };
      };
    })

    ## Hooks.
    (let
      # I build the hook list direcly from noctalia's source, so its list and
      # mine never drift. Probably too brittle.
      header = "${self.inputs.noctalia}/src/config/config_types.h";
      names = map head
        (filter isList
          (split ''HookKind::[A-Za-z]+, "([a-z_]+)"'' (readFile header)));
    in {
      modules.wm.noctalia.settings = defaults {
        hooks =
          if names == []
          then throw "No hooks found in ${header}; Noctalia moved them."
          else genAttrs names (name: escapeShellArgs
            [ config.hey.bin "hook" "-f" "on-${replaceStrings [ "_" ] [ "-" ] name}" ]);
      };
    })

    ## The lock screen.
    (mkIf hasPrimary {
      modules.wm.noctalia.settings = defaults {
        notification.monitors = [ primaryMonitor ];
        osd.monitors = [ primaryMonitor ];

        # Only show the lockscreen widgets on the primary window. Hide all other
        # widgets.
        lockscreen_widgets.widget = {
          "lockscreen-login-box@${primaryMonitor}" = {
            type = "login_box";
            output = primaryMonitor;
            # Only what I've moved off the default; the GUI restates the rest.
            settings = {
              show_weather = false;
              show_unlock_hint = false;
              show_media = false;
              show_session_buttons = false;
              show_keyboard_layout = false;
            };
          };
        } // genAttrs [ "lockscreen-date" "lockscreen-clock" ]
          (_: { type = "clock"; output = primaryMonitor; })
          // genAttrs' otherOutputs (o: nameValuePair "lockscreen-login-box@${o}"
            { type = "login_box"; output = o; enabled = false; });
      };
    })

    ## The login screen.
    {
      services.greetd.enable = true;

      # greetd stops the greeter before uwsm has brought Hyprland up, causing a
      # brief flicker of the monitor (more so on nvidia cards). This keeps it
      # open until the latest possible moment to prevent it.
      services.udev.extraRules = ''
        SUBSYSTEM=="drm", KERNEL=="card[0-9]*", TAG+="systemd", ENV{SYSTEMD_WANTS}+="hey-drm-hold@%k.service"
      '';
      systemd.services."hey-drm-hold@" = {
        description = "Hold /dev/dri/%i open between compositors";
        restartIfChanged = false;   # a restart drops the hold; nothing to gain on `hey sync`
        serviceConfig = {
          StandardInput = "file:/dev/dri/%i";
          ExecStart = "${getExe' pkgs.coreutils "sleep"} infinity";
        };
      };

      services.displayManager = {
        defaultSession = cfg.session.name;
        noctalia-greeter = {
          enable = true;
          cursorTheme = { inherit (cfg.theme.cursor) package name; };
          settings = {
            session.default = cfg.session.desktopName;
            appearance = {
              hide_logo = true;
              scheme_selector_position = "hidden";
              power_buttons_position = "hidden";
            };
            cursor.size = cfg.theme.cursor.size;
          } // optionalAttrs hasPrimary {
            output.name = primaryMonitor;
          };
          # passwordlessSyncUsers = [ config.user.name ];
        };
      };

      # REVIEW: Use `passwordlessSyncUsers` when nixpkgs is bumped.
      security.polkit.enablePkexecWrapper = true;
      security.polkit.extraConfig = mkAfter ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.noctalia.greeter.sync-appearance" &&
              action.lookup("program") == "${getExe' config.services.displayManager.noctalia-greeter.package "noctalia-greeter-apply-appearance"}" &&
              action.lookup("user") == "root" &&
              subject.local && subject.active &&
              subject.user == "${config.user.name}") {
            return polkit.Result.YES;
          }
        });
      '';
    }

    # Rofi application targets
    {
      # The control center is one panel wearing twelve hats. For quick keyboard
      # access, I give them App entries for Rofi to see.
      user.packages = map
        ({ tab, label, icon }: mkLauncherEntry "Noctalia: open ${label} panel" {
          inherit icon;
          exec = "noctalia msg panel-toggle control-center ${tab}";
        })
        [ { tab = "home";          label = "control center"; icon = "preferences-system-symbolic"; }
          { tab = "media";         label = "media";          icon = "multimedia-player-symbolic"; }
          { tab = "audio";         label = "audio";          icon = "audio-volume-high-symbolic"; }
          { tab = "monitor";       label = "brightness";     icon = "display-brightness-symbolic"; }
          { tab = "system";        label = "system";         icon = "utilities-system-monitor-symbolic"; }
          { tab = "network";       label = "network";        icon = "network-wireless-symbolic"; }
          { tab = "bluetooth";     label = "bluetooth";      icon = "bluetooth-symbolic"; }
          { tab = "weather";       label = "weather";        icon = "weather-clear-symbolic"; }
          { tab = "calendar";      label = "calendar";       icon = "office-calendar-symbolic"; }
          { tab = "notifications"; label = "notifications";  icon = "preferences-system-notifications-symbolic"; }
          { tab = "screen-time";   label = "screen time";    icon = "preferences-system-time-symbolic"; }
          { tab = "power";         label = "power";          icon = "battery-good-symbolic"; }
        ] ++ [
          (mkLauncherEntry "Noctalia: change wallpaper" {
            icon = "preferences-desktop-wallpaper";
            exec = "noctalia msg panel-open wallpaper";
          })
          (mkLauncherEntry "System Settings" {
            icon = "preferences-system";
            exec = "noctalia msg settings-open";
          })
          (mkLauncherEntry "Set timer ->" {
            icon = "alarm-symbolic";
            exec = "hey @noctalia timer -p";
          })
          (mkLauncherEntry "Reset timer" {
            icon = "chronometer-reset";
            exec = "hey @noctalia timer 0";
          })
        ];
    }
  ]);
}
