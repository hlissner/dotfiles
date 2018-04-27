export BROWSER=firefox
export GNUPGHOME="$XDG_CONFIG_HOME/gpg"
export GTK2_RC_FILES="${0:A:h}/config/gtk-2.0/gtkrc"
export URXVT_PERL_LIB="$XDG_CONFIG_HOME/urxvt"
export QT_QPA_PLATFORMTHEME=gtk2

_source "$XDG_RUNTIME_DIR/ssh-agent-env" >/dev/null
if [[ -z $SSH_AGENT_PID ]] || ! ps $SSH_AGENT_PID >/dev/null; then
  ssh-agent -s >"$XDG_RUNTIME_DIR/ssh-agent-env"
  _source "$XDG_RUNTIME_DIR/ssh-agent-env" >/dev/null
fi

_is_running gpg-agent || {
  gpg-agent --pinentry-program /usr/bin/pinentry-gtk-2 --daemon >"$XDG_RUNTIME_DIR/gpg-agent-env"
}
_source "$XDG_RUNTIME_DIR/gpg-agent-env" >/dev/null
