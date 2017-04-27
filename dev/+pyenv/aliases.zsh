alias py='python'
command -v python2 >/dev/null && alias py2='python2'
command -v python3 >/dev/null && alias py3='python3'

alias pye='pyenv'
alias ipy='ipython'

# shortcut for calculator
function = { ipython --pylab=qt5 --no-banner; }
