if [ -z "$gubg" ]; then
  export gubg=$HOME/gubg
fi
export PATH=$gubg/bin:$PATH
export PATH=$PATH:$HOME/software/bin
#gem install bundler jekyll
export PATH=$PATH:$HOME/.gem/ruby/2.6.0/bin
export PATH=$PATH:$HOME/.cargo/bin
export EDITOR=$gubg/bin/editor
export GIT_EXTERNAL_DIFF=$gubg/bin/git_diff.sh

export PYTHONPATH=$PYTHONPATH:$gubg/gubg.io/src
export PYTHONPATH=$PYTHONPATH:$gubg/gubg.ml/src
export PYTHONPATH=$PYTHONPATH:$gubg/gubg.algo/src
export PYTHONPATH=$PYTHONPATH:$gubg/gubg.data/src

# Enable ** recursion
case $gubg_shell in
    bash)
    shopt -s globstar
    ;;
esac

aptfzf() {
    sudo apt update && sudo apt install $(apt-cache pkgnames | fzf --multi --cycle --reverse --preview "apt-cache show {1}" --preview-window=:57%:wrap:hidden --bind=space:toggle-preview)
}

# from https://wiki.archlinux.org/title/Fzf#Pacman
alias yays="yay -Slq | fzf --multi --preview 'yay -Si {1}' | xargs -ro yay -S"
alias yayr="yay -Qq | fzf --multi --preview 'yay -Qi {1}' | xargs -ro yay -Rns"

# Open file with 'gg' based on output from 'mo', preview with 'bat'
o() {
    mo -l "$@" | fzf --multi --preview 'bat --style=numbers --color=always --line-range :500 {}' --preview-window 'right:60%' | xargs -I % gg %
}

# Open file with 'gg' based on output from 'mo', preview with 'mo'
s() {
    export all_args="$*"
    mo -l "$@" | fzf --multi --preview 'mo -i -k 1 -f {} -B 2 -A 4 ${all_args}' --preview-window 'right:60%' | xargs -I % gg %
}

c() {
    z `mo -L "$@" | fzf`
}

# cargo install zoxide
eval "$(zoxide init bash)"

#VI commandline setup
# autoload edit-command-line; zle -N edit-command-line
# bindkey -M vicmd v edit-command-line
# bindkey -v
