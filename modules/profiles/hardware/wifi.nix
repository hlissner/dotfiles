# profiles/hardware/wifi.nix --- TODO

{ hey, lib, options, config, pkgs, ... }:

with builtins;
with lib;
with hey.lib;
let interfaces = config.networking.wireless.interfaces;
in mkIf (elem "wifi" config.modules.profiles.hardware) {
  environment.systemPackages = with pkgs; [
    wpa_supplicant  # for wpa_cli
  ];

  networking.supplicant = listToAttrs (map
    (int: nameValuePair int {
      # Allow wpa_(cli|gui) to modify networks list
      userControlled = {
        enable = true;
        group = "users";
      };
      configFile = {
        path = "/etc/wpa_supplicant.d/${int}.conf";
        writable = true;
      };
      extraConf = ''
        ap_scan=1
        p2p_disabled=1
        okc=1
      '';
    })
    interfaces);

  systemd.tmpfiles.rules =
    [ "d /etc/wpa_supplicant.d 700 root root - -" ] ++
    (map (int: "f /etc/wpa_supplicant.d/${int}.conf 700 root root - -") interfaces);

  systemd.network.wait-online.ignoredInterfaces = interfaces;
  boot.initrd.systemd.network.wait-online.ignoredInterfaces = interfaces;
}
