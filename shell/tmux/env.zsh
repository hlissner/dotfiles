export TMUX_HOME="$XDG_CONFIG_HOME/tmux"
export TMUX_PLUGINS_HOME="$XDG_DATA_HOME/tmux/plugins"

export TMUXIFIER="$XDG_DATA_HOME/tmuxifier"
export TMUXIFIER_LAYOUT_PATH="$TMUX_HOME/layouts"
export TMUXIFIER_TMUX_OPTS="-f '$TMUX_HOME/tmux.conf' $TMUXIFIER_TMUX_OPTS"

path=( $TMUXIFIER/bin $path )

#
_cache tmuxifier init -
