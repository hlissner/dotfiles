{ config, lib, pkgs, ... }:

{
  systemd = {
    services.dyndns = {
      description = "Update IP in DNS records";
      path = with pkgs; [ curl dig ];
      script = ''
        IP="$(dig +short myip.opendns.com @resolver1.opendns.com)"
        [[ -f /tmp/dyndns-lastip ]] && LASTIP=$(</tmp/dyndns-lastip)
        if [[ "$IP" != "$LASTIP" ]]; then
          echo "$IP">/tmp/dyndns-lastip
          curl -H "Authorization: Bearer $APIKEY" \
               -H "Accept: application/json" \
               -H "Content-Type: application/json" \
               -X PUT \
               -d "{\"target\":\"$IP\"}" \
               "https://api.linode.com/v4/domains/$DOMAIN/records/$RECORD"
          echo "Updated DNS: $LASTIP -> $IP"
        else
          echo "No change ($IP)"
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = config.age.secrets.dns-env.path;
      };
    };
    timers.dyndns = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        Unit = "dyndns.service";
        OnCalendar = "*:0/5";
      };
    };
  };
}
