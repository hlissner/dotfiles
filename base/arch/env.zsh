export GNUPGHOME="$XDG_CONFIG_HOME/gpg"
export TERMINFO="$XDG_CONFIG_HOME/terminfo"

_is_running ssh-agent || {
  ssh-agent -s >"$XDG_RUNTIME_DIR/ssh-agent-env"
}
_is_running gpg-agent || {
  gpg-agent --daemon >"$XDG_RUNTIME_DIR/gpg-agent-env"
}
_source "$XDG_RUNTIME_DIR/ssh-agent-env" >/dev/null
_source "$XDG_RUNTIME_DIR/gpg-agent-env" >/dev/null
