# Don't offer history completion; we have fzf, C-r, and
# zsh-history-substring-search for that.
ZSH_AUTOSUGGEST_STRATEGY=(completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=30

# Completion is slow. Use a cache! For the love of god, use a cache...
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

# Expand partial paths, e.g. cd f/b/z == cd foo/bar/baz (assuming no ambiguity)
zstyle ':completion:*:paths' path-completion yes

# Options
setopt COMPLETE_IN_WORD    # Complete from both ends of a word.
setopt EXTENDED_GLOB       # Use extended globbing syntax.
setopt PATH_DIRS           # Perform path search even on command names with slashes.
setopt AUTO_MENU           # Show completion menu on a successive tab press.
setopt AUTO_LIST           # Automatically list choices on ambiguous completion.
# setopt AUTO_PARAM_SLASH    # If completed parameter is a directory, add a trailing slash.
# setopt AUTO_PARAM_KEYS
unsetopt FLOW_CONTROL        # Redundant with tmux
unsetopt MENU_COMPLETE     # Do not autoselect the first completion entry.
unsetopt COMPLETE_ALIASES  # Disabling this enables completion for aliases
# unsetopt ALWAYS_TO_END     # Move cursor to the end of a completed word.

# Deferred because `hey.cache dircolors` runs after this file is sourced, so
# LS_COLORS is empty here on first login shell.
zstyle -e ':completion:*:default' list-colors 'reply=(${(s.:.)LS_COLORS})'

# Fuzzy match mistyped completions.
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*' matcher-list 'm:{[:lower:]-}={[:upper:]_}' 'r:[[:ascii:]]||[[:ascii:]]=** r:|?=**'
zstyle ':completion:*:match:*' original only
# Increase the number of errors based on the length of the typed word.
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3))numeric)'
# Don't complete unavailable commands.
zstyle ':completion:*:(functions|parameters)' ignored-patterns '(_*|.*|-*|+*|autosuggest-*|pre(cmd|exec))'
# Group matches and describe.
zstyle ':completion:*:corrections' format '%B%F{green}%d (errors: %e)%f%b'
zstyle ':completion:*:messages' format '%B%F{yellow}%d%f%b'
zstyle ':completion:*:warnings' format '%B%F{red}No such %d%f%b'
zstyle ':completion:*:errors' format '%B%F{red}No such %d%f%b'
zstyle ':completion:*:descriptions' format '%B%F{magenta}%d%f%b'
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
# Without this every match lands in one anonymous group
zstyle ':completion:*' group-name ''
# Arrow/TAB-key selection cycling
zstyle ':completion:*' menu select
# $PATH's contents change under our feet if I run `hey sync`; make sure zsh
# isn't completing an older generation's binaries
zstyle ':completion:*' rehash true
# Offer ./ and ../ , which pairs with the cd ignore-parents rule below
zstyle ':completion:*' special-dirs true
# Omit parent and current directories when they are already in the input
zstyle ':completion:*:*:cd:*' ignore-parents parent pwd
# Merge multiple, consecutive slashes in paths
zstyle ':completion:*' squeeze-slashes true
# Don't wrap around when navigating to either end of history
zstyle ':completion:*:history-words' stop yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' list false
zstyle ':completion:*:history-words' menu yes
# Exclude internal/fake envvars
zstyle ':completion::*:(-command-|export):*' fake-parameters ${${${_comps[(I)-value-*]#*,}%%,*}:#-*-}
# Sort array completion candidates
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters
# Complete hostnames from ssh files too
zstyle -e ':completion:*:hosts' hosts 'reply=(
  ${=${=${=${${(f)"$(cat {/etc/ssh_,~/.{config/,}ssh/known_}hosts(|2)(N) 2>/dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
  ${=${${${${(@M)${(f)"$(cat ~/.{config/,}ssh/config 2>/dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
)'
# Don't complete uninteresting users
zstyle ':completion:*:users' ignored-patterns \
  adm amanda apache avahi beaglidx bin cacti canna clamav daemon \
  dbus distcache dovecot fax ftp games gdm gkrellmd gopher \
  hacluster haldaemon halt hsqldb ident junkbust ldap lp mail \
  mailman mailnull mldonkey mysql nagios \
  named netdump news nfsnobody nobody 'nixbld*' nscd ntp nut nx openvpn \
  operator pcap postfix postgres privoxy pulse pvm quagga radvd \
  rpc rpcuser rpm shutdown squid sshd sync 'systemd-*' uucp vcsa xfs '_*'
# ... unless we really want to.
zstyle '*' single-ignored show
# Ignore multiple entries.
zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
zstyle ':completion:*:rm:*' file-patterns '*:all-files'
# PID completion for kill
zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,command -w'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*' insert-ids single
# Man
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true
zstyle ':completion:*:*:(play|mpv|ffplay):*' file-patterns \
  '*.(#i)(flac|opus|mp3|ogg|wav|m4a|aac):audio-files:audio *(-/):directories:directories' \
  '*:all-files:all\ files'
zstyle ':completion:*:*:(imv|swayimg|swappy):*' file-patterns \
  '*.(#i)(png|jpg|jpeg|gif|webp|avif|bmp|tif|tiff|svg):image-files:images *(-/):directories:directories' \
  '*:all-files:all\ files'
zstyle ':completion:*:*:bat:*' file-patterns \
  '^*.(#i)(o|a|so|zwc|png|jpg|jpeg|gif|webp|avif|pdf|zip|gz|xz|zst|flac|opus|mp3|ogg|wav|m4a|aac|mp4|mkv):text-files:files *(-/):directories:directories' \
  '*:all-files:all\ files'
# SSH/SCP/RSYNC
zstyle ':completion:*:(scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:ssh:*' group-order hosts-domain hosts-host users hosts-ipaddr
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'
