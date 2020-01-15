{ config, pkgs, ... }:

{
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = config.my.username;
    configDir = "/home/${config.my.username}/.config/syncthing";
    dataDir = "/home/${config.my.username}/.local/share/syncthing";
    declarative = {
      devices = {
        kuro.id  = "4UJSUBN-V7LCISG-6ZE7SBN-YPXM5FQ-CE7CD2U-W4KZC7O-4HUZZSW-6DXAGQQ";
        shiro.id = "G4DUO25-AMQQIWS-SRZE5TJ-43CCQZJ-5ULEZBS-P2LMZZU-V5JA5CS-6X7RLQK";
        aka.id   = "4UJSUBN-V7LCISG-6ZE7SBN-YPXM5FQ-CE7CD2U-W4KZC7O-4HUZZSW-6DXAGQQ";
        ao.id    = "PXKRUR4-EVTXROW-NHSEXBZ-H2NTNL7-EWOUDXF-P3AATC7-KATI37N-3YNQAQD";
        # Windows machine; set up the other end yourself!
        niji.id  = "BOFH5JP-A3MPTJA-EGIZVWV-URHUTSJ-2ZXCAA2-XMZPPSR-GLMOQFL-ZX7DGQP";
      };
      folders =
        let ifEnabledDevice = devices: lib.elem config.networking.hostName devices;
        in {
          archive = rec {
            devices = [ "kuro"         "ao"       "niji" ];
            path = "/home/${config.my.username}/archive";
            watch = false;
            rescanInterval = 7200;
            enable = ifEnabledDevice devices;
          };
          projects = rec {
            devices = [ "kuro" "shiro" "ao"       "niji" ];
            path = "/home/${config.my.username}/projects";
            watch = false;
            rescanInterval = 7200;
            enable = ifEnabledDevice devices;
          };
          secrets = rec {
            devices = [ "kuro" "shiro" "ao" "aka"        ];
            path = "/home/${config.my.username}/.secrets";
            enable = ifEnabledDevice devices;
          };
        };
    };
  };
}
