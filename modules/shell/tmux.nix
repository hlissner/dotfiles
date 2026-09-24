{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.shell.tmux;
in {
  options.modules.shell.tmux = with types; {
    enable = mkBoolOpt false;
    term = mkOpt str "xterm-256color";
    rcFiles = mkOpt (listOf (either str path)) [];
  };

  config = mkIf cfg.enable {
    environment.variables = {
      TMUX_HOME = "${hey.configDir}/tmux";
      TMUXINATOR_CONFIG = "${hey.configDir}/tmux/tmuxinator/";
    };

    # I avoid programs.tmux because it comes with extra magic I don't need.
    user.packages = with pkgs; [ tmux tmuxinator ];

    environment.etc."tmux.conf".text = with pkgs.tmuxPlugins; ''
      set -s default-terminal "${cfg.term}"

      source-file $TMUX_HOME/tmux.conf
      ${concatMapStrings (path: "source-file '${path}'\n") cfg.rcFiles}

      # Run plugins
      run-shell ${extrakto.rtp}
      run-shell ${fuzzback.rtp}
      run-shell ${prefix-highlight.rtp}
    '';

    modules.hyprland.theme.templates.tmux = let
      theme = "${config.home.configDir}/tmux/themes/noctalia.conf";
    in {
      input_path = "${hey.configDir}/tmux/colors.template.conf";
      output_path = theme;
      # noctalia-community-templates ships an apply.sh that does this, but is
      # hardcoded to look for ~/.config/tmux/tmux.conf and writes to it.
      post_hook = ''
        for sock in "''${TMUX_TMPDIR:-/tmp}"/tmux-$(id -u)/*; do
          [ -S "$sock" ] || continue
          ${getExe pkgs.tmux} -S "$sock" source-file ${theme} >/dev/null 2>&1 || true
        done
      '';
    };

    modules.shell.zsh.rcFiles = [ "${hey.configDir}/tmux/aliases.zsh" ];
  };
}
