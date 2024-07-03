# modules/system/utils.nix --- TODO
#
# TODO

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.system.utils;
in {
  options.modules.system.utils = {
    enable = mkBoolOpt false;
    benchmarks.enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = with pkgs; [
        glances
        bandwhich # network utilization monitor
        hwinfo
        iftop
        ioping
        lm_sensors
        lsof
        pciutils  # lspci
        powertop
        smartmontools
        sysstat   # sar, iostat, pidstat
        unixtools.netstat
        usbutils  # lsusb
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
