# Kuro -- my desktop

{ config, lib, utils, pkgs, ... }:
{
  imports = [
    ./.  # import common settings

    <my/modules/desktop/bspwm.nix>

    <my/modules/chat.nix>       # discord, mainly
    <my/modules/recording.nix>  # recording video & audio
    <my/modules/daw.nix>        # making music
    <my/modules/music.nix>      # playing music
    <my/modules/graphics.nix>   # art & design
    <my/modules/vm.nix>         # virtualbox for testing

    <my/modules/browser/firefox.nix>
    <my/modules/dev/cc.nix>
    <my/modules/dev/rust.nix>
    <my/modules/editors/emacs.nix>
    <my/modules/editors/vim.nix>
    <my/modules/gaming/steam.nix>
    <my/modules/shell/direnv.nix>
    <my/modules/shell/git.nix>
    <my/modules/shell/gnupg.nix>
    <my/modules/shell/pass.nix>
    <my/modules/shell/zsh.nix>

    # Services
    <my/modules/services/syncthing.nix>

    # Themes
    <my/modules/themes/aquanaut>
  ];

  networking.networkmanager.enable = true;
  time.timeZone = "America/Toronto";

  ## Hardware
  # GPU
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;
  # For ergodox ez
  my.packages = [ pkgs.teensy-loader-cli ];
  my.alias.teensyload = "sudo teensy-loader-cli -w -v --mcu=atmega32u4";
  # For my intuos4 pro. My cintiq doesn't work on Linux though :(
  services.xserver.wacom.enable = true;
  my.init = ''
    # lock tablet to main display
    xinput map-to-output $(xinput list --id-only "Wacom Intuos Pro S Pen eraser") DVI-I-1
    xinput map-to-output $(xinput list --id-only "Wacom Intuos Pro S Pen cursor") DVI-I-1
    xinput map-to-output $(xinput list --id-only "Wacom Intuos Pro S Pen stylus") DVI-I-1
  '';
}
