{ hey, lib, options, config, ... }:

with lib;
with hey.lib;
mkIf (elem "wacom/cintiq" config.modules.profiles.hardware) (mkMerge [
  (mkIf (config.modules.desktop.type == "x11") {
    # For my intuos4 pro. Doesn't work for cintiqs.
    services.xserver.wacom.enable = true;

    # system.userActivationScripts.wacom = ''
    #   # lock tablet to main display
    #   if xinput list --id-only "Wacom Intuos Pro S Pen stylus" 2>&1 >/dev/null; then
    #     xinput map-to-output $(xinput list --id-only "Wacom Intuos Pro S Pen stylus") DVI-I-1
    #     xinput map-to-output $(xinput list --id-only "Wacom Intuos Pro S Pen eraser") DVI-I-1
    #     xinput map-to-output $(xinput list --id-only "Wacom Intuos Pro S Pen cursor") DVI-I-1
    #   fi
    # '';
  })

  (mkIf (config.modules.desktop.type == "wayland") {
    # hardware.opentablet.driver.enable = true;
  })

  # REVIEW: Maybe cyber-sushi/makima?
])
