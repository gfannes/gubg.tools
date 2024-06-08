#Make sure we do not output anything in interactive mode. Else, scp will fail.
[[ -o interactive ]] || exit 0

export gubg_shell=zsh
export gubg_script_dir=$(dirname -- $0:A)

alias rake='noglob rake'
alias fix='noglob fix'
alias ge='noglob ge'

source "$gubg_script_dir/all_.sh"

autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

unset gubg_script_dir
