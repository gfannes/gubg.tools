#Use this file in gnome terminal by setting the "Custom command" to something "bash --init-file /home/geert/gubg/bin/personal.gfannes.sh"

echo ">> Loading environment from $BASH_SOURCE ..."

#xmodmap $HOME/.xmodmap

alias ls="ls --color "
alias l="find ./ -name "
alias mymount="sudo mount -o rw,noauto,async,user,umask=1000 "
alias myumount="sudo umount "

PS1="\[\033[1;32m\]\u\[\033[1;30m\]@\[\033[1;34m\]\h \[\033[1;34m\]\W\[\033[1;30m\]>\[\033[0m\] "

export LS_COLORS="no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jpg=01;35:*.png=01;35:*.gif=01;35:*.bmp=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.png=01;35:*.mpg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:"

export GIT_EXTERNAL_DIFF=$gubg/bin/git_diff.sh

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

function qcc {
    git commit "-am" "$@"
}

#>> gubg
export gubg=$HOME/gubg
export PATH=$gubg/bin:$PATH
export EDITOR=$gubg/bin/editor
#<< gubg

#>> auro
export auro_publish=$HOME/pub

function auro_notify {
export auro_compiler=${auro_compiler_brand}_${auro_compiler_arch}-${auro_compiler_config}
#Remove the previous $AURO_BIN from $PATH, if any
if [ "$AURO_BIN" != "" ]
then
export PATH=`echo $PATH | sed "s|:$AURO_BIN||g"`
fi

export AURO_BIN=$auro_publish/bin/$auro_compiler
export PATH=$PATH:$AURO_BIN

echo auro_compiler: $auro_compiler
echo auro_publish:  $auro_publish
echo auro_test:  $auro_test
echo Added $AURO_BIN to PATH
}

#Some defaults
export auro_compiler_brand=gcc
export auro_compiler_arch=x64
export auro_compiler_config=release
export auro_test=ut

function use_gcc {
export auro_compiler_brand=gcc
auro_notify
}

function use_clang {
export auro_compiler_brand=clang
auro_notify
}

function x32 {
export auro_compiler_arch=x32
auro_notify
}

function x64 {
export auro_compiler_arch=x64
auro_notify
}

function release {
export auro_compiler_config=release
auro_notify
}

function profile {
export auro_compiler_config=release_gprof
auro_notify
}

function debug {
export auro_compiler_config=debug
auro_notify
}

function publish {
export auro_publish=$1
auro_notify
}

function catch {
export auro_test=$1
auro_notify
}

use_gcc
release

function klone {
    git clone https://git.auro-technologies.com/scm/$1
}
#<< auro

echo "<< ... done"

cd $HOME

touches_fn=$HOME/gubg.sh
if [ -f $touches_fn ]
then
    echo ">> Executing local touches from $touches_fn ..."
    source $touches_fn
    echo "<< ... done"
fi
