{ config, options, pkgs, lib, ... }:
with lib;
{
  options.modules.shell.tmux = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.shell.tmux.enable {
    my = {
      packages = with pkgs; [
        # The developer of tmux chooses not to add XDG support for religious
        # reasons (see tmux/tmux#142). Fortunately, nix makes this easy:
        (writeScriptBin "tmux" ''
          #!${stdenv.shell}
          exec ${tmux}/bin/tmux -f "$TMUX_HOME/config" "$@"
          '')
      ];

      env.TMUX_HOME = "$XDG_CONFIG_HOME/tmux";
      env.TMUXIFIER = "$XDG_DATA_HOME/tmuxifier";
      env.TMUXIFIER_LAYOUT_PATH = "$XDG_DATA_HOME/tmuxifier";
      env.PATH = [ "$TMUXIFIER/bin" ];

      zsh.rc = ''
        _cache tmuxifier init -
        ${lib.readFile <config/tmux/aliases.zsh>}
      '';
      home.xdg.configFile = {
        "tmux" = { source = <config/tmux>; recursive = true; };
        "tmux/plugins".text = ''
          run-shell ${pkgs.tmuxPlugins.copycat}/share/tmux-plugins/copycat/copycat.tmux
          run-shell ${pkgs.tmuxPlugins.prefix-highlight}/share/tmux-plugins/prefix-highlight/prefix_highlight.tmux
          run-shell ${pkgs.tmuxPlugins.yank}/share/tmux-plugins/yank/yank.tmux
        '';
      };
    };
  };
}
