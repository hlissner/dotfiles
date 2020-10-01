# Shiro -- my laptop

{ ... }:
{
  imports = [ ./hardware-configuration.nix ];

  ## Modules
  modules = {
    desktop = {
      bspwm.enable = true;
      apps = {
        discord.enable = true;
        rofi.enable = true;
        # skype.enable = true;
      };
      browsers = {
        default = "firefox";
        firefox.enable = true;
      };
      media = {
        # daw.enable = true;
        documents.enable = true;
        graphics.enable = true;
        mpv.enable = true;
        recording.enable = true;
        spotify.enable = true;
      };
      term = {
        default = "xst";
        st.enable = true;
      };
      vm = {
        # virtualbox.enable = true;
      };
    };
    editors = {
      default = "emacs -nw";
      emacs.enable = true;
      vim.enable = true;
    };
    dev = {
      # cc.enable = true;
      # common-lisp.enable = true;
      # rust.enable = true;
      # lua.enable = true;
      # lua.love2d.enable = true;
    };
    hardware = {
      audio.enable = true;
      fs = {
        enable = true;
        ssd.enable = true;
      };
    };
    shell = {
      direnv.enable = true;
      git.enable = true;
      gnupg.enable = true;
      # weechat.enable = true;
      pass.enable = true;
      tmux.enable = true;
      # ranger.enable = true;
      zsh.enable = true;
    };
    hardware = {

    };
    services = {
      # syncthing.enable = true;
      ssh.enable = true;
    };
    themes.fluorescence.enable = true;
  };


  ## Local config
  programs.ssh.startAgent = true;

  boot.loader.systemd-boot.enable = true;
  networking.wireless.enable = true;
  hardware.opengl.enable = true;

  # time.timeZone = "Europe/Copenhagen";
}
