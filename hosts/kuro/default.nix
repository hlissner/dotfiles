# Kuro -- my desktop

{ pkgs, options, config, ... }:
{
  imports = [
    ../personal.nix   # common settings
    ./hardware-configuration.nix
  ];

  modules = {
    desktop = {
      bspwm.enable = true;

      apps.rofi.enable = true;
      apps.discord.enable = true;
      # apps.skype.enable = true;
      apps.daw.enable = true;        # making music
      apps.graphics.enable = true;   # raster/vector/sprites
      apps.recording.enable = true;  # recording screen/audio
      apps.vm.enable = true;         # virtualbox for testing

      term.default = "xst";
      term.st.enable = true;

      browsers.default = "firefox";
      browsers.firefox.enable = true;
      # browsers.qutebrowser.enable = true;
      # browsers.vimb.enable = true;

      # gaming.emulators.psx.enable = true;
      # gaming.steam.enable = true;
      # gaming.factorio.enable = true;
    };

    editors = {
      default = "nvim";
      emacs.enable = true;
      vim.enable = true;
    };

    dev = {
      cc.enable = true;
      common-lisp.enable = true;
      rust.enable = true;
    };

    media = {
      mpv.enable = true;
      spotify.enable = true;
    };

    shell = {
      direnv.enable = true;
      git.enable = true;
      gnupg.enable = true;
      # weechat.enable = true;
      pass.enable = true;
      tmux.enable = true;
      ranger.enable = true;
      zsh.enable = true;
    };

    services = {
      syncthing.enable = true;
    };

    # themes.aquanaut.enable = true;
    themes.fluorescence.enable = true;
  };

  networking.networkmanager.enable = true;
  time.timeZone = "America/Toronto";
}
