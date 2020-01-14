{ config, lib, pkgs, ... }:

{
  my.packages = with pkgs; [
    libqalculate
    xclip
    xdotool
    mpv       # video player
    feh       # image viewer

    # Useful apps
    calibre   # managing my ebooks
    evince    # pdf reader
  ];

  sound.enable = true;
  hardware.pulseaudio.enable = true;
  # Prevents ~/.esd_auth files by disabling the esound protocol module for
  # pulseaudio, which I likely don't need. Is there a better way?
  hardware.pulseaudio.configFile =
    let paConfigFile =
          with pkgs; runCommand "disablePulseaudioEsoundModule"
            { buildInputs = [ pulseaudio ]; } ''
              mkdir "$out"
              cp ${pulseaudio}/etc/pulse/default.pa "$out/default.pa"
              sed -i -e 's|load-module module-esound-protocol-unix|# ...|' "$out/default.pa"
            '';
      in lib.mkIf config.hardware.pulseaudio.enable
        "${paConfigFile}/default.pa";

  services = {
    xserver.enable = true;
    redshift.enable = true;
  };

  # For redshift
  location = (if config.time.timeZone == "America/Toronto" then {
    latitude = 43.70011;
    longitude = -79.4163;
  } else if config.time.timeZone == "Europe/Copenhagen" then {
    latitude = 55.88;
    longitude = 12.5;
  } else {});

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
