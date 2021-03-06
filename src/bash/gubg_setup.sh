if [ -z "$gubg" ]; then
  export gubg=$HOME/gubg
fi
export PATH=$gubg/bin:$PATH
export PATH=$PATH:$HOME/software/bin
#gem install bundler jekyll
export PATH=$PATH:$HOME/.gem/ruby/2.6.0/bin
export EDITOR=$gubg/bin/editor
export GIT_EXTERNAL_DIFF=$gubg/bin/git_diff.sh

export PYTHONPATH=$PYTHONPATH:$gubg/gubg.io/src
export PYTHONPATH=$PYTHONPATH:$gubg/gubg.ml/src
export PYTHONPATH=$PYTHONPATH:$gubg/gubg.algo/src

# Enable ** recursion
shopt -s globstar

aptfzf() {
    sudo apt update && sudo apt install $(apt-cache pkgnames | fzf --multi --cycle --reverse --preview "apt-cache show {1}" --preview-window=:57%:wrap:hidden --bind=space:toggle-preview)
}

o() {
    mo -l $* | fzf --multi --preview 'bat --style=numbers --color=always --line-range :500 {}' --preview-window 'right:60%' | xargs -I % gg %
}

s() {
    export all_args="$*"
    mo -l $* | fzf --multi --preview 'mo -c -i ${all_args} -C {}' --preview-window 'right:60%' | xargs -I % gg %
}

c() {
    z `mo -L $* | fzf`
}

# cargo install zoxide
eval "$(zoxide init bash)"

