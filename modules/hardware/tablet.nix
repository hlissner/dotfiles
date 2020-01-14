{ config, lib, pkgs, ... }:

{
  # For my intuos4 pro. Doesn't work for cintiqs.
  services.xserver.wacom.enable = true;

  # TODO Move this to udev
  # my.init = ''
  #   # lock tablet to main display
  #   if xinput list --id-only "Wacom Intuos Pro S Pen stylus" 2>&1 >/dev/null; then
  #     xinput map-to-output $(xinput list --id-only "Wacom Intuos Pro S Pen stylus") DVI-I-1
  #     xinput map-to-output $(xinput list --id-only "Wacom Intuos Pro S Pen eraser") DVI-I-1
  #     xinput map-to-output $(xinput list --id-only "Wacom Intuos Pro S Pen cursor") DVI-I-1
  #   fi
  # '';
}
