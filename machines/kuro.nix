# Kuro -- my desktop

{ config, lib, utils, pkgs, ... }:
{
  imports = [
    ./.  # import common settings

    <my/modules/hardware/nvidia.nix>
    <my/modules/hardware/ergodox.nix>

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

  # Mouse settings
  services.xserver.libinput = {
    enable = true;
    middleEmulation = true;
    scrollButton = 3;
  };
}
