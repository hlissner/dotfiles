export GNUPGHOME="$XDG_CONFIG_HOME/gpg"
export GTK2_RC_FILES="${0:A:h}/config/gtk-2.0/gtkrc"
export TERMINFO="$XDG_CONFIG_HOME/terminfo"
export BROWSER=firefox
export URXVT_PERL_LIB="$XDG_CONFIG_HOME/urxvt"

_is_running ssh-agent || {
  ssh-agent -s >"$XDG_RUNTIME_DIR/ssh-agent-env"
}
_is_running gpg-agent || {
  gpg-agent --daemon >"$XDG_RUNTIME_DIR/gpg-agent-env"
}
_source "$XDG_RUNTIME_DIR/ssh-agent-env" >/dev/null
_source "$XDG_RUNTIME_DIR/gpg-agent-env" >/dev/null
