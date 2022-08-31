export gubg_shell=zsh
export gubg_script_dir=$(dirname -- $0:A)

alias rake='noglob rake'

source "$gubg_script_dir/all_.sh"

unset gubg_script_dir