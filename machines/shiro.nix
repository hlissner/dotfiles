# Shiro -- my laptop

{ config, lib, pkgs, ... }:

let nixos-hardware = builtins.fetchTarball https://github.com/NixOS/nixos-hardware/archive/master.tar.gz;
in {
  imports = [
    ./.  # import common settings

    # Hardware specific
    "${nixos-hardware}/dell/xps/13-9370"

    <my/modules/desktop/bspwm.nix>

    <my/modules/chat.nix>       # discord, mainly
    <my/modules/recording.nix>  # recording video & audio
    <my/modules/daw.nix>        # making music
    <my/modules/music.nix>      # playing music
    <my/modules/graphics.nix>   # art & design
    # <my/modules/vm.nix>         # virtualbox for testing

    <my/modules/browser/firefox.nix>
    <my/modules/dev>
    <my/modules/editors/emacs.nix>
    <my/modules/editors/vim.nix>
    <my/modules/shell/direnv.nix>
    <my/modules/shell/git.nix>
    <my/modules/shell/gnupg.nix>
    <my/modules/shell/pass.nix>
    <my/modules/shell/zsh.nix>

    # Services
    <my/modules/services/syncthing.nix>

    # Themes
    <modules/themes/aquanaut>
  ];

  theme.wallpaper = <my/assets/wallpapers/aquanaut.2560x1440.jpg>;
  networking.wireless.enable = true;
  hardware.opengl.enable = true;

  time.timeZone = "America/Toronto";
  # time.timeZone = "Europe/Copenhagen";

  # Optimize power use
  environment.systemPackages = [ pkgs.acpi ];
  powerManagement.powertop.enable = true;
  # Monitor backlight control
  programs.light.enable = true;
  # Encrypted /home
  boot.initrd.luks.devices = [
    {
      name = "home";
      device = "/dev/nvme0n1p8";
      preLVM = true;
      allowDiscards = true;
    }
  ];
}
