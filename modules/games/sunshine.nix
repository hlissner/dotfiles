# modules/games/sunshine.nix --- Moonlight's host half
#
# Steam Remote Play can be slow and stuttery at larger resolutions due to
# Wayland forcing encoding on the CPU. Sunshine reads the primary output
# straight off KMS, encodes with NVENC, and lets each Moonlight client ask for
# its own resolution, framerate and bitrate.

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.games.sunshine;
    wm = config.modules.wm;
    nvidia = any (hasPrefix "gpu/nvidia") config.modules.profiles.hardware;
    switching = filterAttrs (_: c: c.mode != null) cfg.clients;
in {
  options.modules.games.sunshine = with types; {
    enable = mkBoolOpt false;
    output = mkOpt' (nullOr str) wm.primaryMonitor
      "The connector to stream (Sunshine's output_name). null lets it guess.";
    clients = mkOpt' (attrsOf (submodule {
      options.mode = mkOpt' (nullOr str) null ''
        "WxH@Hz" to switch `output` to while this client streams, Hz to three
        decimals as `niri msg outputs` prints it. null leaves it alone.
      '';
    })) {} "Paired Moonlight clients, keyed by the name given at pairing.";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = switching == {} || (wm.desktop == "niri" && cfg.output != null);
      message = "modules.games.sunshine.clients.*.mode: needs niri and an `output` to switch.";
    }];

    # nixpkgs' sunshine module still speaks pre-RFC42 services.avahi.publish.*,
    # so avahi warns on every eval. Same workaround as the printer profile.
    services.avahi = {
      publish = { enable = mkForce null; userServices = mkForce null; };
      settings.publish = {
        disable-publishing = false;
        disable-user-service-publishing = false;
        publish-addresses = true;
      };
    };

    services.sunshine = {
      enable = true;
      package = mkIf nvidia (pkgs.sunshine.override { cudaSupport = true; });
      openFirewall = true;
      autoStart = false;  # I'll management it myself
      capSysAdmin = true;

      settings = {
        sunshine_name = config.networking.hostName;
        capture = "kms";
        output_name = mkIf (cfg.output != null) cfg.output;
        # The handhelds stream over wifi at 20-40 Mbps; AQ spends those bits
        # where the eye looks. Costs the encoder next to nothing.
        nvenc_spatial_aq = mkIf nvidia "enabled";
        # Sunshine runs this around every session, do then undo, with the
        # client's pairing name in the environment.
        global_prep_cmd = mkIf (switching != {}) (
          let restore = (findFirst (m: m.output == cfg.output) {} wm.niri.monitors).mode or "auto";
              fit = pkgs.writeShellScript "sunshine-fit-output" ''
                case "$1:''${SUNSHINE_CLIENT_NAME-}" in
                ${concatStringsSep "\n" (mapAttrsToList
                    (name: c: "  do:${escapeShellArg name}) mode=${escapeShellArg c.mode} ;;")
                    switching)}
                  ${concatMapStringsSep "|" (n: "undo:${escapeShellArg n}") (attrNames switching)}) mode=${escapeShellArg restore} ;;
                  *) exit 0 ;;
                esac
                exec ${getExe config.programs.niri.package} msg output ${escapeShellArg cfg.output} mode "$mode"
              '';
          in toJSON [{ do = "${fit} do"; undo = "${fit} undo"; }]);
      };

      applications.apps = [
        { name = "Desktop"; }
      ] ++ optional config.modules.games.steam.enable (
        let steam = "${config.programs.steam.package}/bin/steam";
        in {
          name = "Steam";
          # Detached, because a second `steam` only pokes the running one and
          # returns; as the app's `cmd` that would end the session on the spot.
          detached = [ "${steam} steam://open/bigpicture" ];
          prep-cmd = [{ undo = "${steam} steam://close/bigpicture"; }];
        });
    };
  };
}
