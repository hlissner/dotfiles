# modules/desktop/term/st.nix
#
# I like (x)st. This appears to be a controversial opinion; don't tell anyone,
# mkay?

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.term.st;
in {
  options.modules.desktop.term.st = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      xst  # st + nice-to-have extensions
      (mkLauncherEntry "Suckless Terminal" {
        description = "Open default terminal application";
        icon = "utilities-terminal";
        exec = "${xst}/bin/xst";
        categories = [ "Development" "System" "Utility" ];
      })
    ];

    # xst-256color isn't supported over ssh, so revert to a known one
    modules.shell.tmux.term = mkForce "xterm-256color";
  };
}
