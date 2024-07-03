# profiles/hardware/pc/laptop.nix ---
#
# TODO

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let hardware = config.modules.profiles.hardware;
in mkMerge [
  (mkIf (any (s: hasPrefix "pc/laptop" s) hardware) {
    user.packages = with pkgs; [
      brightnessctl  # instead of programs.light
      acpi
    ];

    # So the system can respond to power events
    # services.udev.extraRules = ''
    #   SUBSYSTEM=="power_supply",ENV{POWER_SUPPLY_ONLINE}=="0",RUN+="${hey.binDir}/hey hook battery --discharging"
    #   SUBSYSTEM=="power_supply",ENV{POWER_SUPPLY_ONLINE}=="1",RUN+="${hey.binDir}/hey hook battery --charging"
    # '';

    # # And so I can monitor the charge level
    # systemd.user.services.battery_monitor = {
    #   wants = [ "display-manager.service" ];
    #   wantedBy = [ "graphical-session.target" ];
    #   script = ''
    #     export PATH="${pkgs.acpi}/bin:${hey.binDir}:$PATH"
    #     while true; do
    #       IFS=: read _ bat0 < <(acpi -b)
    #       IFS=\ , read status val remaining <<<"$bat0"
    #       local wait=$(hey hook battery --poll "$status" "$${val%\%}" "$remaining")
    #       sleep $${wait:-1m}
    #     done
    #   '';
    # };

    # systemd.user.services.battery_monitor = {
    #   wants = [ "display-manager.service" ];
    #   wantedBy = [ "graphical-session.target" ];
    #   script = ''
    #     prev_val=100
    #     _check () {
    #       [[ $1 -ge $val ]] && [[ $1 -lt $prev_val ]];
    #     }
    #     _notify () {
    #       ${pkgs.libnotify}/bin/notify-send \
    #         --app-name battery \
    #         --hint string:x-dunst-stack-tag:battery \
    #         --hint "int:value:$val" \
    #         "$@" "$val%, $remaining"
    #     }
    #     while true; do
    #       ifs=: read _ bat0 < <(${pkgs.acpi}/bin/acpi -b)
    #       ifs=\ , read status val remaining <<<"$bat0"
    #       val=''${val%\%}
    #       if [[ "x$status" = xdischarging ]]; then
    #         echo "$val%, $remaining"
    #         if _check 30 || _check 15; then
    #           _notify "Battery low"
    #         elif _check 10; then
    #           _notify -u critical "Battery critical"
    #         fi
    #       fi
    #       prev_val=$val
    #       # sleep longer when battery is high to save cpu
    #       if [[ $val -gt 30 ]]; then
    #         sleep 10m
    #       elif [[ $val -ge 20 ]]; then
    #         sleep 5m
    #       else
    #         sleep 1m
    #       fi
    #     done
    #   '';
    # };
  })
]
