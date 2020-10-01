{ config, options, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.tmux;
in {
  options.modules.shell.tmux = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      # Despite tmux/tmux#142, tmux will support XDG in 3.2. Sadly, only 3.0 is
      # available on nixpkgs, and 3.1b on master (tmux/tmux@15d7e56), so I
      # implement it myself:
      (writeScriptBin "tmux" ''
        #!${stdenv.shell}
        exec ${tmux}/bin/tmux -f "$TMUX_HOME/config" "$@"
      '')
    ];

    modules.shell.zsh = {
      rcInit = "_cache tmuxifier init -";
      rcFiles = [ "${configDir}/tmux/aliases.zsh" ];
    };

    home.configFile = {
      "tmux" = { source = "${configDir}/tmux"; recursive = true; };
      "tmux/plugins".text = ''
        run-shell ${pkgs.tmuxPlugins.copycat}/share/tmux-plugins/copycat/copycat.tmux
        run-shell ${pkgs.tmuxPlugins.prefix-highlight}/share/tmux-plugins/prefix-highlight/prefix_highlight.tmux
        run-shell ${pkgs.tmuxPlugins.yank}/share/tmux-plugins/yank/yank.tmux
      '';
    };

    env = {
      PATH = [ "$TMUXIFIER/bin" ];
      TMUX_HOME = "$XDG_CONFIG_HOME/tmux";
      TMUXIFIER = "$XDG_DATA_HOME/tmuxifier";
      TMUXIFIER_LAYOUT_PATH = "$XDG_DATA_HOME/tmuxifier";
    };
  };
}
