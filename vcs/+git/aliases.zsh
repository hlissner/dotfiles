is-callable hub && alias git='hub'

# g = git status
# g ... = git $@
g() { [[ $# = 0 ]] && git status --short . || git $*; }
compdef g=hub

alias gbr='git browse'
alias gi='git init'
alias gs='git status --short'
alias gsu='git submodule'
alias greb='git rebase --autostash -i origin/master'
alias gco='git checkout'
alias gcoo='git checkout --'
alias gc='git commit'
alias gcl='git clone'
alias gcm='noglob git commit -m'
alias gcma='noglob git commit --amend -m'
alias gcf='noglob git commit --fixup'
alias gd='git diff'
alias gp='git push'
alias gpb='git push origin'
alias gpt='git push --follow-tags'
alias gpl='git pull --rebase --autostash'
alias ga='git add'
alias gau='git add -u'
alias gb='git branch'
alias gbd='git branch -D'
alias gap='git add --patch'
alias gr='git reset HEAD'
alias gt='git tag'
alias gtd='git tag -d'
alias gta='git tag -a'
alias gl='git log --oneline --decorate'

