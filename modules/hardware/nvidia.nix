{ config, lib, pkgs, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;

  # Respect XDG conventions, damn it!
  environment.systemPackages = with pkgs; [
    (pkgs.writeScriptBin "nvidia-settings" ''
        #!${pkgs.stdenv.shell}
        exec ${config.boot.kernelPackages.nvidia_x11}/bin/nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings"
      '')
  ];
}
