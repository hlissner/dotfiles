# modules/system/diagnostics.nix --- TODO
#
# TODO

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.system.diagnostics;
in {
  options.modules.system.diagnostics = {
    enable = mkBoolOpt false;
    benchmarks.enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = with pkgs; [
        lm_sensors
        powertop
        unixtools.netstat
        pciutils  # lspci
        glances
        hwinfo
        lsof
        usbutils  # lsusb
        sysstat   # sar, iostat, pidstat
        ioping
        iftop
        smartmontools
      ];
    }

    (mkIf cfg.benchmarks.enable {
      environment.systemPackages = [
        sysbench
        unigine-valley
        speedtest-cli
      ];
    })
  ]);
}
