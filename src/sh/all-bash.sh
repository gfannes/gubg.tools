#Use this file in gnome terminal by setting the "Custom command" to something "bash --init-file /home/geert/gubg/bin/all-bash.sh"

#Make sure we do not output anything in interactive mode. Else, scp will fail.
[[ $- == *i* ]] || return

export gubg_shell=bash
export gubg_script_dir=$( dirname "$BASH_SOURCE" )

source "$gubg_script_dir/all_.sh"

unset gubg_script_dir
