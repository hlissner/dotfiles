# profiles/hardware/common/pc/laptop/battery.nix ---
#
# TODO

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
{
  # regularly check battery status
  systemd.user.services.battery_monitor = {
    wants = [ "display-manager.service" ];
    wantedBy = [ "graphical-session.target" ];
    script = ''
      prev_val=100
      _check () {
        [[ $1 -ge $val ]] && [[ $1 -lt $prev_val ]];
      }
      _notify () {
        ${pkgs.libnotify}/bin/notify-send \
          --app-name battery \
          --hint string:x-dunst-stack-tag:battery \
          --hint "int:value:$val" \
          "$@" "$val%, $remaining"
      }
      while true; do
        ifs=: read _ bat0 < <(${pkgs.acpi}/bin/acpi -b)
        ifs=\ , read status val remaining <<<"$bat0"
        val=''${val%\%}
        if [[ $status = discharging ]]; then
          echo "$val%, $remaining"
          if _check 30 || _check 15; then
            _notify "Battery low"
          elif _check 10; then
            _notify -u critical "Battery critical"
          fi
        fi
        prev_val=$val
        # sleep longer when battery is high to save cpu
        if [[ $val -gt 30 ]]; then
          sleep 10m
        elif [[ $val -ge 20 ]]; then
          sleep 5m
        else
          sleep 1m
        fi
      done
    '';
  };
}
