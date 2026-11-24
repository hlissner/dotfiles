# modules/browser/chrome.nix --- https://www.google.com/chrome
#
# Chrome, set it up plainly as a last-resort browser. I use LibreWolf, but
# sometimes a tool or website requires chrome for whatever (bad) reason, so...

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.apps.browsers.chrome;
    ubol = "ddkjiahejlhfcafbddmgiahcphecmpfh";
in {
  options.modules.apps.browsers.chrome = with types; {
    enable = mkBoolOpt false;
    policies = mkOpt' attrs {} ''
      Enterprise policies, written to
      <filename>/etc/opt/chrome/policies/managed</filename>.
      https://chromeenterprise.google/policies/
    '';
  };

  config = mkIf cfg.enable {
    user.packages = [
      (pkgs.google-chrome.override {
        # The first-run dialog predates policy loading, so no policy can stop it.
        commandLineArgs = "--no-first-run --no-default-browser-check";
      })
    ];

    modules.apps.browsers.chrome.policies = {
      # Nags
      DefaultBrowserSettingEnabled = false;
      PromotionsEnabled = false;
      PrivacySandboxPromptEnabled = false;
      PrivacySandboxAdTopicsEnabled = false;
      PrivacySandboxSiteEnabledAdsEnabled = false;
      PrivacySandboxAdMeasurementEnabled = false;
      ProfilePickerOnStartupAvailability = 1;  # 1=never
      BrowserAddPersonEnabled = false;
      TranslateEnabled = false;
      ShoppingListEnabled = false;
      FeedbackSurveysEnabled = false;
      UserFeedbackAllowed = false;
      GenAiDefaultSettings = 2;   # 2=off, for every "Help me ..." they ship next
      HideWebStoreIcon = true;

      # It's a guest in my house; it doesn't get to remember anything.
      BrowserSignin = 0;          # 0=disabled
      SyncDisabled = true;
      PasswordManagerEnabled = false;
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;
      PaymentMethodQueryEnabled = false;

      # Or phone home
      MetricsReportingEnabled = false;
      UrlKeyedAnonymizedDataCollectionEnabled = false;
      SearchSuggestEnabled = false;
      SpellCheckServiceEnabled = false;
      AlternateErrorPagesEnabled = false;
      NetworkPredictionOptions = 2;  # 2=never preload

      # Or linger after I close the last window
      BackgroundModeEnabled = false;

      # Blank slate
      NewTabPageLocation = "about:blank";
      RestoreOnStartup = 4;       # 4=open the URLs below
      RestoreOnStartupURLs = [ "about:blank" ];
      BookmarkBarEnabled = false;
      NTPCardsVisible = false;
      NTPMiddleSlotAnnouncementVisible = false;

      ExtensionInstallForcelist = [ ubol ];
      "3rdparty".extensions.${ubol}.disableFirstRunPage = true;
    };

    # Not programs.chromium: that'd write these for Chromium and Brave too, and
    # all it is underneath is this one file.
    environment.etc."opt/chrome/policies/managed/hey.json".text =
      builtins.toJSON cfg.policies;
  };
}
