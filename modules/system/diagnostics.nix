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
        glances
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
