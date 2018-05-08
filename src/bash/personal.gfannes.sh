#Use this file in gnome terminal by setting the "Custom command" to something "bash --init-file /home/geert/gubg/bin/personal.gfannes.sh"

echo ">> Loading environment from $BASH_SOURCE ..."

self_dir=$( dirname "$BASH_SOURCE" )

source "$self_dir/git.sh"
source "$self_dir/env_setup.sh"
source "$self_dir/gubg_setup.sh"
source "$self_dir/auro_setup.sh"
source "$self_dir/brew.sh"

echo "<< ... done"

source "$self_dir/gubg_touches.sh"
