# modules/browser/librewolf.nix --- https://librewolf.net/
#
# Oh Librewolf, gateway to the interwebs, devourer of ram. Give onto me your
# infinite knowledge and shelter me from ads, but bless my $HOME with
# directories nobody needs and live long enough to turn into Chrome.

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.apps.browsers.librewolf;
in {
  options.modules.apps.browsers.librewolf = with types; {
    enable = mkBoolOpt false;
    profileName = mkOpt str config.user.name;

    settings = mkOpt' (attrsOf (oneOf [ bool int str ])) {} ''
      Librewolf preferences to set in <filename>user.js</filename>
    '';
    extraConfig = mkOpt' lines "" ''
      Extra lines to add to <filename>user.js</filename>
    '';

    userChrome  = mkOpt' lines "" "CSS Styles for Librewolf's interface";
    userContent = mkOpt' lines "" "Global CSS Styles for websites";
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      gabutdm
      (mkLauncherEntry "Librewolf (Private)" {
        description = "Open a private Librewolf window";
        icon = "librewolf";
        exec = "librewolf --private-window";
        categories = [ "Network" ];
      })
      (mkLauncherEntry "Librewolf (Alt)" {
        description = "Open the alt Librewolf profile";
        icon = "librewolf";
        exec = "librewolf -P alt";
        categories = [ "Network" ];
      })
    ];

    # Treat LibreWolf as our default PDF reader
    xdg.mime = {
      defaultApplications."application/pdf" = "librewolf.desktop";
      addedAssociations."application/pdf" = "librewolf.desktop";
    };

    programs.firefox = {
      enable = true;
      package = pkgs.librewolf;
      autoConfig =
        let prefs = {
          # The xdg-desktop-portal doesn't propagate the correct clipboard to
          # file/save dialg windows, so disable it and use the native file picker.
          "widget.use-xdg-desktop-portal.file-picker" = 0;
          # Allow svgs to take on theme colors
          "svg.context-properties.content.enabled" = true;
          # Pressing TAB from address bar shouldn't cycle through buttons before
          # switching focus back to the webppage. Most of those buttons have
          # dedicated shortcuts, so I don't need this level of tabstop granularity.
          "browser.toolbars.keyboard_navigation" = false;

          # Seriously. Stop popping up on every damn page. If I want it translated,
          # I know where to find gtranslate/deepl/whatever!
          "browser.translations.automaticallyPopup" = false;
          # Enable userContent.css and userChrome.css for our theme modules
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          # Do not check if Firefox is the default browser
          "browser.shell.checkDefaultBrowser" = false;
          # Disable the "new tab page" feature and show a blank tab instead
          # https://wiki.mozilla.org/Privacy/Reviews/New_Tab
          # https://support.mozilla.org/en-US/kb/new-tab-page-show-hide-and-customize-top-sites#w_how-do-i-turn-the-new-tab-page-off
          "browser.newtabpage.enabled" = false;
          "browser.newtab.preload" = false;
          # Reduce search engine noise in the urlbar's completion window. The
          # shortcuts and suggestions will still work, but Firefox won't clutter
          # its UI with reminders that they exist.
          "browser.urlbar.shortcuts.bookmarks" = false;
          "browser.urlbar.shortcuts.history" = false;
          "browser.urlbar.shortcuts.tabs" = false;
          "browser.urlbar.showSearchSuggestionsFirst" = false;
          # Since FF 113, you must press TAB twice to cycle through urlbar
          # suggestions. This disables that.
          "browser.urlbar.resultMenu.keyboardAccessible" = false;
          # Show whole URL in address bar
          "browser.urlbar.trimURLs" = false;
          # Disable some not so useful functionality.
          "browser.disableResetPrompt" = true;     # "Looks like you haven't started Firefox in a while."
          "reader.parse-on-load.enabled" = false;  # "reader view"

          # https://support.mozilla.org/en-US/kb/extension-recommendations
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
          # Reduce File IO / SSD abuse
          # Otherwise, Firefox bombards the HD with writes. Not so nice for SSDs.
          # This forces it to write every 30 minutes, rather than 15 seconds.
          # Must be an int; a string here is silently rejected as a type mismatch.
          "browser.sessionstore.interval" = 1800000;
          # Disable battery API
          # https://developer.mozilla.org/en-US/docs/Web/API/BatteryManager
          # https://bugzilla.mozilla.org/show_bug.cgi?id=1313580
          "dom.battery.enabled" = false;
          # Disable "beacon" asynchronous HTTP transfers (used for analytics)
          # https://developer.mozilla.org/en-US/docs/Web/API/navigator.sendBeacon
          "beacon.enabled" = false;
          # Disable gamepad API to prevent USB device enumeration
          # https://www.w3.org/TR/gamepad/
          # https://trac.torproject.org/projects/tor/ticket/13023
          "dom.gamepad.enabled" = false;
          # Don't try to guess domain names when entering an invalid domain name in URL bar
          # http://www-archive.mozilla.org/docs/end-user/domain-guessing.html
          "browser.fixup.alternate.enabled" = false;
          # Disable health reports (basically more telemetry). LibreWolf locks
          # the rest of the telemetry, normandy and crash reporter prefs.
          # https://support.mozilla.org/en-US/kb/firefox-health-report-understand-your-browser-perf
          "datareporting.healthreport.service.enabled" = false;
          # Disable Form autofill. LibreWolf covers formfill.enable, addresses
          # and creditCards.enabled.
          # https://wiki.mozilla.org/Firefox/Features/Form_Autofill
          "extensions.formautofill.available" = "off";
          "extensions.formautofill.creditCards.available" = false;
        };
        in concatStrings (mapAttrsToList (name: value: ''
          defaultPref("${name}", ${builtins.toJSON value});
        '') prefs);
    };

    # These are imported from userChrome.css & userContent.css (further below)
    modules.hyprland.theme.templates = listToAttrs (concatMap
      (profile: let chromeDir = "${config.home.configDir}/librewolf/librewolf/${cfg.profileName}.${profile}/chrome";
      in [
        (nameValuePair "librewolf-chrome-${profile}" {
          input_path = "${hey.configDir}/librewolf/userChrome.template.css";
          output_path = "${chromeDir}/userChrome.colors.css";
        })
        (nameValuePair "librewolf-content-${profile}" {
          input_path = "${hey.configDir}/librewolf/userContent.template.css";
          output_path = "${chromeDir}/userContent.colors.css";
        })
      ]) [ "default" "alt" ]);

    home.configFile =
      let localDir = "librewolf/librewolf";
          userjs = mkIf (cfg.settings != {} || cfg.extraConfig != "") {
            text = ''
              ${concatStrings (mapAttrsToList (name: value: ''
                user_pref("${name}", ${builtins.toJSON value});
              '') cfg.settings)}
              ${cfg.extraConfig}
            '';
          };
      in {
        # Use fixed profile names so it can be targeted in themes and scripts
        "${localDir}/profiles.ini".text = ''
          [General]
          StartWithLastProfile=1
          Version=2

          [Profile0]
          Name=default
          IsRelative=1
          Path=${cfg.profileName}.default
          Default=1

          [Profile1]
          Name=alt
          IsRelative=1
          Path=${cfg.profileName}.alt
        '';

        "${localDir}/${cfg.profileName}.default/user.js" = userjs;
        "${localDir}/${cfg.profileName}.default/chrome/userChrome.css".text = ''
          @import "userChrome.colors.css";
          ${optionalString (cfg.userChrome != "") cfg.userChrome}
        '';
        "${localDir}/${cfg.profileName}.default/chrome/userContent.css".text = ''
          @import "userContent.colors.css";
          ${optionalString (cfg.userContent != "") cfg.userContent}
        '';

        "${localDir}/${cfg.profileName}.alt/user.js" = userjs;
      };
  };
}
