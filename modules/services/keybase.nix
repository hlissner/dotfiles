{ config, lib, pkgs, ... }:

{
  services.kbfs = {
    enable = true;
    mountPoint = "%t/kbfs";
    extraFlags = [ "-label %u" ];
  };

  systemd.user.services.kbfs = {
    environment = { KEYBASE_RUN_MODE = "prod"; };
    serviceConfig.Slice = "keybase.slice";
  };
}
