# Shiro -- my laptop

{ pkgs, ... }:
{
  imports = [
    ../personal.nix   # common settings
    ./hardware-configuration.nix
    (let nixos-hardware =
           builtins.fetchTarball
             https://github.com/NixOS/nixos-hardware/archive/master.tar.gz;
     in "${nixos-hardware}/dell/xps/13-9370")
    ## Dekstop environment
    <modules/desktop/bspwm.nix>
    ## Apps
    <modules/browser/firefox.nix>
    <modules/dev>
    <modules/editors/emacs.nix>
    <modules/editors/vim.nix>
    <modules/shell/direnv.nix>
    <modules/shell/git.nix>
    <modules/shell/gnupg.nix>
    <modules/shell/pass.nix>
    <modules/shell/zsh.nix>
    ## Project-based
    <modules/chat.nix>       # discord, mainly
    <modules/recording.nix>  # recording video & audio
    <modules/daw.nix>        # making music
    <modules/music.nix>      # playing music
    <modules/graphics.nix>   # art & design
    # <modules/vm.nix>         # virtualbox for testing
    ## Services
    <modules/services/syncthing.nix>
    ## Theme
    <modules/themes/aquanaut>
  ];

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
