# modules/wm/default.nix
#
# Common settings shared across all supported window managers (just Hyprland for
# now, but Niri will be next).

{ self, lib, config, ... }:

with lib;
with self.lib;
let cfg = config.modules.wm;
in {
  options.modules.wm = with types; {
    desktop = mkOpt' (nullOr (enum [
      "hyprland"
      # "niri"
    ])) null
      "The window manager to install. Enables modules.wm.<desktop>.";
  };

  config = {
    hey.desktop = cfg.desktop;

    # wm modules shouldn't be enabled if no desktop is enabled!
    assertions =
      let enabled = attrNames (filterAttrs (_: m: isAttrs m && m.enable or false) cfg);
      in [{
        assertion = cfg.desktop != null || enabled == [];
        message = ''
          modules.wm.{${concatStringsSep "," enabled}} can't be enabled without a
          desktop; set modules.wm.desktop.
        '';
      }];
  };
}
