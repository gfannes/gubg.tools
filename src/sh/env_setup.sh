source "$gubg_script_dir/os.sh"

if [[ "$os" == macos ]]; then
  alias ls="ls "
  ulimit -n 10240
else
  alias ls="ls --color "
fi
alias l="find ./ -name "
alias mymount="sudo mount -o rw,noauto,async,user,umask=1000 "
alias myumount="sudo umount "

alias gsf="git submodule foreach "

case $gubg_shell in
  bash)
  export PS1="\[\033[1;32m\]\u\[\033[1;32m\]@\[\033[1;34m\]\h \[\033[1;34m\]\W\[\033[1;32m\]>\[\033[0m\] "
  echo Enabling VI commandline setup
  set -o vi
  # Does not work for Ubuntu22.04
  # bind -m vi-insert "\C-r": reverse-search-history
  ;;

  zsh)
  # export newline=$'\n'
  # export PS1='${newline}[%F{blue}%n%f@%F{green}%m%f :: %~]${newline}# '
  export PS1='[%F{blue}%n%f@%F{green}%m%f :: %~]# '

  echo Enabling VI commandline setup
  autoload edit-command-line; zle -N edit-command-line
  bindkey -M vicmd v edit-command-line
  bindkey -v
  bindkey -M viins '^R' history-incremental-search-backward
  ;;
esac

export LS_COLORS="no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jpg=01;35:*.png=01;35:*.gif=01;35:*.bmp=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.png=01;35:*.mpg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:"

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

function use_ccache {
    # In this folder there are wrappers for gcc and clang that need to come
    # first in the path
    # manjaro
    export PATH=/usr/lib/ccache/bin/:$PATH
    # macos installed with brew
    export PATH=/opt/homebrew/opt/ccache/libexec:$PATH
}

# Necessary for fixing a problem with valgrind wrt `Fatal error at startup`
export DEBUGINFOD_URLS=https://debuginfod.archlinux.org
