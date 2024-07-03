# modules/services/ydotool.nix
#
# Used as a more portable alternative to xdotool. Not a big fan of anything that
# needs a daemon though; more so since ydotool will soon be rewritten in
# javascript (for its history of supply chain vulnerabiltiies), so I'll likely
# drop it once wtype adds mouse support (see atx/wtype#24).

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.services.ydotool;
    ydotool = pkgs.ydotool;
    socket = "/run/ydotoold/socket";
in {
  options.modules.services.ydotool = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    environment.variables.YDOTOOL_SOCKET = socket;

    users.groups.ydotool = {};
    user.extraGroups = [ "ydotool" ];

    environment.systemPackages = [ ydotool ];
    systemd.services.ydotoold = {
      wantedBy = [ "multi-user.target" ];
      partOf = [ "multi-user.target" ];
      serviceConfig = {
        Group = "ydotool";
        RuntimeDirectory = "ydotoold";
        RuntimeDirectoryMode = "0750";
        ExecStart = "${getExe' ydotool "ydotoold"} --socket-path=${socket} --socket-perm=0660";
        # hardening
        ## allow access to uinput
        DeviceAllow = [ "/dev/uinput" ];
        DevicePolicy = "closed";
        ## allow creation of unix sockets
        RestrictAddressFamilies = [ "AF_UNIX" ];
        CapabilityBoundingSet = "";
        IPAddressDeny = "any";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateNetwork = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
          "~@resources"
        ];
        UMask = "0077";
        # -> systemd-analyze security score 0.7 SAFE
      };
    };
  };
}
