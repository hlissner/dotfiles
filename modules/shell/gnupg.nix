{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.shell.gnupg;
in {
  options.modules.shell.gnupg = with types; {
    enable   = mkBoolOpt false;
    cacheTTL = mkOpt int 3600;  # 1hr
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment = mkMerge [
        (optionalAttrs pkgs.stdenv.isDarwin {
          variables.GNUPGHOME = "$HOME/.config/gnupg";
        })
        (optionalAttrs (!pkgs.stdenv.isDarwin) {
          sessionVariables.GNUPGHOME = "$HOME/.config/gnupg";
        })
      ];

      user.packages = [ pkgs.gnupg ];

      # systemd.user.services.gpg-agent.serviceConfig.Environment = [
      #   "GNUPGHOME=${config.home.configDir}/gnupg"
      # ];

      programs = optionalAttrs (!pkgs.stdenv.isDarwin) {
        gnupg = {
          agent = {
            enable = true;
            pinentryPackage = pkgs.pinentry-rofi.override {
              rofi = if config.modules.desktop.type == "wayland"
                     then pkgs.rofi-unwrapped
                     else pkgs.rofi;
            };
          };
        };
      };

      home.configFile."gnupg/gpg-agent.conf".text = ''
        default-cache-ttl ${toString cfg.cacheTTL}
        allow-emacs-pinentry
        allow-loopback-pinentry
      '';
    }
    (mkIf pkgs.stdenv.isDarwin {
      home.packages = [ pkgs.gnupg ];
    })
  ]);
}
