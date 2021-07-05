{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.hardware.audio;
in {
  options.modules.hardware.audio = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    # HACK Due to alsa-project/alsa-lib#143, ALSA/pulseaudio can't find sound
    #      devices. The 1.2.5.1 hotfix addresses this, but isn't in nixpkgs yet.
    nixpkgs.overlays = [
      (self: super: with super; {
        alsa-lib = super.alsa-lib.overrideAttrs (old: rec {
          pname = "alsa-lib";
          version = "1.2.5.1";
          src = pkgs.fetchurl {
            url = "mirror://alsa/lib/${pname}-${version}.tar.bz2";
            sha256 = "sha256-YoQh2VDOyvI03j+JnVIMCmkjMTyWStdR/6wIHfMxQ44=";
          };
        });
      })
    ];

    sound.enable = true;
    hardware.pulseaudio.enable = true;

    # HACK Prevents ~/.esd_auth files by disabling the esound protocol module
    #      for pulseaudio, which I likely don't need. Is there a better way?
    hardware.pulseaudio.configFile =
      let inherit (pkgs) runCommand pulseaudio;
          paConfigFile =
            runCommand "disablePulseaudioEsoundModule"
              { buildInputs = [ pulseaudio ]; } ''
                mkdir "$out"
                cp ${pulseaudio}/etc/pulse/default.pa "$out/default.pa"
                sed -i -e 's|load-module module-esound-protocol-unix|# ...|' "$out/default.pa"
              '';
      in mkIf config.hardware.pulseaudio.enable
        "${paConfigFile}/default.pa";

    user.extraGroups = [ "audio" ];
  };
}
