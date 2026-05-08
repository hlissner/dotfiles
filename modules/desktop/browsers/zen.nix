{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.desktop.browsers.zen;
  system = pkgs.stdenv.hostPlatform.system;
  zenPkg =
    if pkgs.unstable ? zen-browser then pkgs.unstable.zen-browser
    else if hey.inputs ? zen-browser && hasAttr system hey.inputs.zen-browser.packages
      then hey.inputs.zen-browser.packages.${system}.default
    else null;
in {
  options.modules.desktop.browsers.zen = with types; {
    enable = mkBoolOpt false;
    package = mkOpt (nullOr package) zenPkg;
    executable = mkOpt str "zen-beta";
    desktopFile = mkOpt str "zen-beta.desktop";
    wmClass = mkOpt str "zen-beta";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = cfg.package != null;
      message = "Zen browser package is unavailable from nixpkgs and the zen-browser flake input.";
    }];

    modules.desktop.browsers.default = mkDefault cfg.executable;
    environment.sessionVariables = {
      BROWSER = mkDefault cfg.executable;
      MOZ_ENABLE_WAYLAND = "1";
    };

    user.packages = [ cfg.package ];

    xdg.mime.defaultApplications =
      let desktop = cfg.desktopFile;
      in {
        "text/html" = desktop;
        "x-scheme-handler/http" = desktop;
        "x-scheme-handler/https" = desktop;
        "x-scheme-handler/about" = desktop;
        "x-scheme-handler/unknown" = desktop;
      };
  };
}
