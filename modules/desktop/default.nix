{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    redshift
    xclip
    xdotool
    ffmpeg
    mpv       # video player
    feh       # image viewer

    # Useful apps
    evince    # pdf reader
    discord
    spotify
  ];

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services = {
    xserver.enable = true;
    redshift.enable = true;
  };

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
    ];

    fontconfig.defaultFonts = {
      sansSerif = ["Ubuntu"];
      monospace = ["Fira Code"];
    };
  };
}
