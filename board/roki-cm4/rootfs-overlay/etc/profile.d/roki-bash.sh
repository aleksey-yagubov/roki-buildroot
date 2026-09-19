# Interactive Bash defaults for the Roki image.

case $- in
    *i*) ;;
    *) return ;;
esac

[ -n "${BASH_VERSION:-}" ] || return

export EDITOR=nano
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=5000
export HISTFILESIZE=10000

shopt -s checkwinsize cmdhist histappend

alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias ip='ip -c'

PS1='\u@\h:${PWD}\$ '
