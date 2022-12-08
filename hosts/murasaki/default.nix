{ pkgs, config, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];


  ## Framework configuration
  profiles = {
    users.hlissner.enable = true;
    workstation.enable = true;
  };

  modules = {
    desktop = {
      bspwm.enable = true;
      apps = {
        rofi.enable = true;
        # godot.enable = true;
        spotify.enable = true;
        teamviewer.enable = true;
      };
      browsers = {
        default = "firefox";
        firefox.enable = true;
      };
      gaming = {
        steam.enable = true;
      };
      media = {
        daw.enable = true;
        graphics.enable = true;
        video.enable = true;
        cad.enable = true;
      };
      term = {
        default = "xst";
        st.enable = true;
      };
      vm = {
        qemu.enable = true;
      };
    };
    dev = {
      cc.enable = true;
    };
    editors = {
      default = "nvim";
      emacs.enable = true;
      vim.enable = true;
    };
    shell = {
      vaultwarden.enable = true;
      direnv.enable = true;
      git.enable    = true;
      gnupg.enable  = true;
      tmux.enable   = true;
      zsh.enable    = true;
    };
    services = {
      ssh.enable = true;
      docker.enable = true;
      # Needed occasionally to help the parental units with PC problems
      # teamviewer.enable = true;
    };
    theme.active = "alucard";
  };


  ## Local config
  user.packages = with pkgs; [
    my.starsector
  ];

  time.timeZone = "Europe/Copenhagen";
}
