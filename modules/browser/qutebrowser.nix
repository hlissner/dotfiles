# modules/browser/qutebrowser.nix --- https://github.com/qutebrowser/qutebrowser
#
# Qutebrowser is cute because it's not enough of a browser to be handsome.
# Still, we can all tell he'll grow up to be one hell of a lady-killer.

{ config, lib, pkgs, ... }:
{
  my.packages = with pkgs; [
    qutebrowser
    (pkgs.writeScriptBin "qutebrowser-private" ''
      #!${stdenv.shell}
      ${qutebrowser}/bin/qutebrowser ":open -p $@"
    '')
    (makeDesktopItem {
      name = "qutebrowser-private";
      desktopName = "Qutebrowser (Private)";
      genericName = "Open a private Qutebrowser window";
      icon = "qutebrowser";
      exec = "${qutebrowser}/bin/qutebrowser ':open -p'";
      categories = "Network";
    })

  ];
  my.env.BROWSER = "qutebrowser";
  my.home.xdg = {
    configFile."qutebrowser" = {
      source = <config/qutebrowser>;
      recursive = true;
    };
    dataFile = {
      "qutebrowser/greasemonkey" = {
        source = <config/qutebrowser/greasemonkey>;
        recursive = true;
      };
      "qutebrowser/userstyles.css".source =
        let compiledStyles =
              with pkgs; runCommand "compileUserStyles"
                { buildInputs = [ sass ]; } ''
                  mkdir "$out"
                  for file in ${<config/qutebrowser/styles>}/*.scss; do
                    scss --sourcemap=none \
                         --no-cache \
                         --style compressed \
                         --default-encoding utf-8 \
                         "$file" \
                         >>"$out/userstyles.css"
                  done
                '';
        in "${compiledStyles}/userstyles.css";
    };
  };
}
