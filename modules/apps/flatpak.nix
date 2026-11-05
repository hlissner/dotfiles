# modules/apps/flatpak.nix
#
# For the software that won't be packaged for nix, and the software I'd rather
# keep at arm's length from the rest of the system.

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.apps.flatpak;
    state = "/var/lib/hey/flatpak";
    ensure = pkgs.writeText "flatpak-ensure" (concatLines cfg.ensure);
in {
  options.modules.apps.flatpak = with types; {
    enable = mkBoolOpt false;
    ensure = mkOpt (listOf str) [];
  };

  config = mkIf cfg.enable {
    services.flatpak = {
      enable = true;
      package = mkIf config.modules.xdg.enable
        # Respect XDG, damn it!
        (mkWrapper pkgs.flatpak ''
          wrapProgram "$out/bin/flatpak" \
            --run 'export HOME="''${XDG_FAKE_HOME:-$HOME}"'
        '');
    };

    systemd.services.hey-flatpak-ensure-packages = {
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = [ config.services.flatpak.package ];
      script = ''
        system="$(readlink /run/current-system)"
        [ "$(cat ${state}/system 2>/dev/null)" = "$system" ] && exit 0
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      '' + optionalString (cfg.ensure != []) ''
        flatpak install -y --noninteractive --or-update flathub ${escapeShellArgs cfg.ensure}
      '' + ''
        flatpak update -y --noninteractive
        mkdir -p ${state}
        # Keep track of what flatpaks are managed from nix
        cat ${ensure} ${state}/ensure 2>/dev/null | sort -u >${state}/ensure.new
        mv ${state}/ensure.new ${state}/ensure
        printf '%s\n' "$system" >${state}/system
      '';
    };

    # Uninstall unusued/unneeded packages
    hey.hooks."on-gc".flatpak =
      let prune = pkgs.writeShellScript "hey-flatpak-prune" ''
        set -e
        export PATH="${config.services.flatpak.package}/bin:$PATH"
        dropped="$(comm -23 <(sort ${state}/ensure 2>/dev/null) <(sort ${ensure}) \
                   | grep -Fxf <(flatpak list --app --columns=application) || true)"
        [ -z "$dropped" ] || flatpak uninstall -y --noninteractive $dropped
        flatpak uninstall -y --noninteractive --unused
        # Settled; forget them, or they'd be "dropped" at every gc after a reinstall.
        mkdir -p ${state} && cat ${ensure} >${state}/ensure
      '';
      in ''
        [[ " $* " == *" system "* ]] || exit 0
        [ -n "$(${config.services.flatpak.package}/bin/flatpak list --columns=application)" ] || exit 0
        sudo ${prune}
      '';
  };
}
