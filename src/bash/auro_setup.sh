export auro_publish=$HOME/pub

function auro_notify {
export auro_compiler=${auro_compiler_brand}-${auro_compiler_arch}-${auro_compiler_config}${auro_compiler_subconfig}${auro_compiler_cpp}${auro_compiler_thread}${auro_compiler_pic}${auro_compiler_vlc}${auro_compiler_wwise}
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
export auro_compiler_cpp=
export auro_compiler_thread=
export auro_compiler_pic=
export auro_compiler_vlc=
export auro_compiler_wwise=
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

function i7 {
export auro_compiler_arch=i7
auro_notify
}

function release {
export auro_compiler_config=release
auro_notify
}
function debug {
export auro_compiler_config=debug
auro_notify
}

function normal {
export auro_compiler_subconfig=
auro_notify
}
function rtc {
export auro_compiler_subconfig=-rtc
auro_notify
}
function profile {
export auro_compiler_subconfig=-profile
auro_notify
}

function cpp03 {
export auro_compiler_cpp=-cpp03
auro_notify
}

function nothread {
export auro_compiler_thread=-nothread
auro_notify
}

function use_pic {
    export auro_compiler_pic=-pic
    auro_notify
}
function use_nopic {
    export auro_compiler_pic=
    auro_notify
}

function use_vlc {
    export auro_compiler_vlc=-vlc
    auro_notify
}
function use_novlc {
    export auro_compiler_vlc=
    auro_notify
}

function use_wwise {
    export auro_compiler_wwise=
    auro_notify
}
function use_nowwise {
    export auro_compiler_wwise=-nowwise
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
normal
use_pic
use_nowwise

function klone {
    git clone https://git.auro-technologies.com/scm/$1
}
