# modules/browser/qutebrowser.nix --- https://github.com/qutebrowser/qutebrowser
#
# Qutebrowser is cute because it's not enough of a browser to be handsome.
# Still, we can all tell he'll grow up to be one hell of a lady-killer.

{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.browsers.qutebrowser;
    pkg = pkgs.unstable.qutebrowser;
    configDir = config.dotfiles.configDir;
in {
  options.modules.desktop.browsers.qutebrowser = with types; {
    enable = mkBoolOpt false;
    userStyles = mkOpt lines "";
    extraConfig = mkOpt lines "";
    dicts = mkOpt (listOf str) [ "en-US" ];
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      pkg
      (makeDesktopItem {
        name = "qutebrowser-private";
        desktopName = "Qutebrowser (Private)";
        genericName = "Open a private Qutebrowser window";
        icon = "qutebrowser";
        exec = ''${pkg}/bin/qutebrowser -T -s content.private_browsing true'';
        categories = [ "Network" ];
      })
      # For Brave adblock in qutebrowser, which is significantly better than the
      # built-in host blocking. Works on youtube and crunchyroll ads!
      python39Packages.adblock
    ];

    home = {
      configFile = {
        "qutebrowser" = {
          source = "${configDir}/qutebrowser";
          recursive = true;
        };
        "qutebrowser/extra/00-extraConfig.py".text = cfg.extraConfig;
      };
      dataFile."qutebrowser/userstyles.css".text = cfg.userStyles;
    };

    # Install language dictionaries for spellcheck backends
    system.userActivationScripts.qutebrowserInstallDicts =
      concatStringsSep "\\\n" (map (lang: ''
        if ! find "$XDG_DATA_HOME/qutebrowser/qtwebengine_dictionaries" -type d -maxdepth 1 -name "${lang}*" 2>/dev/null | grep -q .; then
          ${pkgs.python3}/bin/python ${pkg}/share/qutebrowser/scripts/dictcli.py install ${lang}
        fi
      '') cfg.dicts);
  };
}
