# Allow command line editing in an external editor.
autoload -Uz edit-command-line
zle -N edit-command-line

export GIT_MERGE_AUTOEDIT=no
unsetopt CORRECT_ALL

setopt append_history share_history extended_history
setopt histignorealldups histignorespace
setopt extended_glob
setopt longlistjobs
setopt nonomatch
setopt notify
setopt hash_list_all

# Don't send SIGHUP to background processes when the shell exits.
setopt nohup

setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt nobeep
setopt noglobdots
setopt noshwordsplit
setopt unset
