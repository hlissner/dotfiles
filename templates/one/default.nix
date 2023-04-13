# Workstation -- a desktop system

{ self, lib, profiles, ... }:

with lib;
with builtins;
{
  system = "x86_64-linux";

  ## Flake profiles
  profiles = with profiles; [
    role.workstation
    user.hlissner
    network.ca
    # hardware.common.cpu.intel
    # hardware.common.cpu.amd.pstate
    # hardware.common.gpu.nvidia
    # hardware.common.gpu.nvidia.kepler
    # hardware.common.gpu.nvidia.turing
    hardware.common.audio
    # hardware.common.ssd
    # hardware.common.printer
    # hardware.common.printer.wireless
    # hardware.ergodox
    # hardware.razer
    # hardware.wacom.cintiq
  ];

  ## Flake modules
  modules = {
    theme.active = "alucard";

    # This enforcing XDG conventions on SSH executable. A little dangerous;
    # disable if you use many ssh-dependent third-party tools.
    xdg.ssh.enable = true;

    desktop = {
      # awesomewm.enable = true;
      bspwm.enable = true;
      # cosmic.enable = true;
      # stumpwm.enable = true;

      apps = {
        # godot.enable = true;
        rofi.enable = true;
        # skype.enable = true;
        # spotify.enable = true;
        # steam.enable = true;
        # steam.mangohud.enable = true;
        # teamviewer.enable = true;
        # ue.enable = true;
        # unity3d.enable = true;
        # virtualbox.enable = true;
      };
      browsers = {
        # brave.enable = true;
        default = "firefox";
        firefox.enable = true;
        # qutebrowser.enable = true;
      };
      media = {
        # cad.enable = true;
        # daw.enable = true;
        # graphics.design.enable = true;
        # graphics.enable = false;
        # graphics.print.enable = false;
        # graphics.raster.enable = true;
        # graphics.sprites.enable = true;
        # graphics.tools.enable = true;
        # graphics.vector.enable = true;
        # ncmpcpp.enable = true;
        # video.capture.enable = true;
        # video.editor.enable = true;
        video.enable = true;
        # video.player.enable = false;
        # video.tools.enable = false;
      };
      term = {
        default = "xst";
        st.enable = true;
      };
    };
    dev = {
      # cc.enable = true;
      # clojure.enable = true;
      # common-lisp.enable = true;
      # default.enable = true;
      # java.enable = true;
      # julia.enable = true;
      # lua.enable = true;
      # node.enable = true;
      # python.enable = true;
      # ruby.enable = true;
      # rust.enable = true;
      # scala.enable = true;
      # shell.enable = true;
    };
    editors = {
      default = "nvim";
      emacs.enable = true;
      vim.enable = true;
    };
    shell = {
      # adl.enable = true;
      direnv.enable = true;
      git.enable = true;
      gnupg.enable = true;
      # pass.enable = true;
      tmux.enable = true;
      # vaultwarden.enable = true;
      zsh.enable = true;
    };
    services = {
      # calibre.enable = true;
      # cgit.enable = true;
      # discourse.enable = true;
      # docker.enable = true;
      # dunst.enable = true;
      # fail2ban.enable = true;
      # gitea.enable = true;
      # jellyfin.enable = true;
      # nginx.enable = true;
      # printing.enable = true;
      # prometheus.enable = true;
      ssh.enable = true;
      # syncthing.enable = true;
      # transmission.enable = true;
      # vaultwarden.enable = true;
      # wireguard.enable = true;
    };
    system = {
      diagnostics.enable = true;
      # diagnostics.benchmarks.enable = true;
      fs.enable = true;
      # fs.zfs.enable = true;
      # fs.nfs.enable = true;
    };
    virt = {
      # lxd.enable = true;
      # qemu.enable = true;
      # vagrant.enable = true;
    };
  };

  ## Local config
  config = { ... }: {
    # ...
  };

  hardware = { ... }: {
    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
        options = [ "noatime" ];
      };
      "/boot" = {
        device = "/dev/disk/by-label/BOOT";
        fsType = "vfat";
      };
      "/home" = {
        device = "/dev/disk/by-label/home";
        fsType = "ext4";
        options = [ "noatime" ];
      };
    };
    swapDevices = [];
  };
}
