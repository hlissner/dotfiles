{ config, lib, pkgs, ... }:

{
  my = {
    packages = with pkgs; [
      # The developer of tmux chooses not to add XDG support for religious
      # reasons (see tmux/tmux#142). Fortunately, nix offers a simple
      # workaround:
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
    home.xdg.configFile."tmux" = { source = <config/tmux>; recursive = true; };
  };
}
