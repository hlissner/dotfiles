{ config, lib, pkgs, ... }:

{
  my = {
    packages = with pkgs; [
      calibre   # managing my ebooks
      evince    # pdf reader
      feh       # image viewer
      mpv       # video player
      xclip
      xdotool
    ];
  };

  ## Sound
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  ## Fonts
  fonts = {
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      ubuntu_font_family
      dejavu_fonts
      fira-code
      fira-code-symbols
      symbola
      noto-fonts
      noto-fonts-cjk
      font-awesome-ttf
      siji
    ];
    fontconfig.defaultFonts = {
      sansSerif = ["Ubuntu"];
      monospace = ["Fira Code"];
    };
  };

  services.compton = {
    backend = "glx";
    vSync = true;
    opacityRules = [
      "100:class_g = 'Firefox'"
      "100:class_g = 'Vivaldi-stable'"
      "100:class_g = 'VirtualBox Machine'"
      # Art/image programs where we need fidelity
      "100:class_g = 'Gimp'"
      "100:class_g = 'Inkscape'"
      "100:class_g = 'aseprite'"
      "100:class_g = 'krita'"
      "100:class_g = 'feh'"
      "100:class_g = 'mpv'"
    ];
    settings.blur-background-exclude = [
      "window_type = 'dock'"
      "window_type = 'desktop'"
      "_GTK_FRAME_EXTENTS@:c"
    ];
  };
}
