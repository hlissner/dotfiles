# modules/virt/wine.nix
#
# For one-off use of window programs, like firmware updaters and installers.

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.virt.wine;
in {
  options.modules.virt.wine = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      wineWow64Packages.stable
      winetricks
    ];

    environment.variables = {
      WINEPREFIX = "$XDG_DATA_HOME/wine";
      # Otherwise wine litters ~/.local/share/applications with launchers and
      # claims every mimetype it can for notepad.exe et co.
      WINEDLLOVERRIDES = "winemenubuilder.exe=d";
    };
  };
}
