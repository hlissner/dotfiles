# modules/desktop/apps/virtualbox.nix
#
# For testing or building software on other OSes. If I find out how to get macOS
# on qemu/libvirt I'd be happy to leave virtualbox behind.

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.apps.virtualbox;
in {
  options.modules.desktop.apps.virtualbox = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    virtualisation.virtualbox.host = {
      enable = true;
      # urg, takes so long to build, but needed for macOS guest
      # enableExtensionPack = true;
    };

    user.extraGroups = [ "vboxusers" ];

    # I will always update the microcode for my CPUs, so this is safe heuristic
    # for what CPU to cater to.
    boot.kernelModules =
      if config.hardware.cpu.amd.updateMicrocode
      then [ "kvm-amd" ]
      else [ "kvm-intel" ];
  };
}
