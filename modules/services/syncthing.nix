{ config, options, pkgs, lib, ... }:
with lib;
{
  options.modules.services.syncthing = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.services.syncthing.enable {
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
          aka.id   = "IZQ2GAC-I3QBTRT-TXBIG7Z-NT6S66Y-H64WOCO-T3AMKYZ-VGWTNCY-CTQOLQN";
          ao.id    = "NBMLUKD-PJRXCTM-GQ2WFLE-NN4IGSN-6WSC6JL-M6XN7PE-HCBTOKV-7VER2QE";
          # Windows machine; set up the other end yourself!
          midori.id = "BOFH5JP-A3MPTJA-EGIZVWV-URHUTSJ-2ZXCAA2-XMZPPSR-GLMOQFL-ZX7DGQP";
        };
        folders =
          let deviceEnabled = devices: lib.elem config.networking.hostName devices;
              deviceType = devices:
                if deviceEnabled devices
                then "sendreceive"
                else "receiveonly";
          in {
            archive = rec {
              devices = [ "kuro"         "ao"       "midori" ];
              path = "/home/${config.my.username}/archive";
              watch = false;
              rescanInterval = 3600 * 6;
              type = deviceType ["kuro"];
              enable = deviceEnabled devices;
            };
            share = rec {
              devices = [ "kuro" "shiro" "ao" "aka" "midori" ];
              path = "/home/${config.my.username}/share";
              watch = true;
              rescanInterval = 3600 * 6;
              enable = deviceEnabled devices;
            };
            projects = rec {
              devices = [ "kuro" "shiro" "ao"       "midori" ];
              path = "/home/${config.my.username}/projects";
              watch = false;
              rescanInterval = 3600 * 2;
              type = deviceType ["kuro" "shiro"];
              enable = deviceEnabled devices;
            };
            secrets = rec {
              devices = [ "kuro" "shiro" "ao" "aka"        ];
              path = "/home/${config.my.username}/.secrets";
              watch = true;
              rescanInterval = 3600;
              type = deviceType ["kuro" "shiro"];
              enable = deviceEnabled devices;
            };
          };
      };
    };
  };
}
