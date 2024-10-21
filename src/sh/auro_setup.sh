export auro_publish=$HOME/pub

export auro_bin_dir=$HOME/auro/bin

export PATH=$PATH:$auro_bin_dir
export PATH=$PATH:/opt/local/auro/android-ndk-r21b

export GST_PLUGIN_PATH=$auro_bin_dir

function auro_notify {
    export auro_compiler=${auro_compiler_brand}-${auro_compiler_arch}-${auro_compiler_config}${auro_compiler_subconfig}${auro_compiler_linker}${auro_compiler_cpp}${auro_compiler_thread}${auro_compiler_pic}${auro_compiler_vlc}${auro_compiler_gstreamer}${auro_compiler_wwise}${auro_compiler_wall}${auro_compiler_color}${auro_compiler_mss}
    echo auro_compiler: $auro_compiler
    echo auro_publish:  $auro_publish
    echo auro_ti_base:  $auro_ti_base
    echo auro_test:  $auro_test
    echo Added $AURO_BIN to PATH
}

#Some defaults
export auro_compiler_brand=gcc
export auro_compiler_arch=x64
export auro_compiler_config=release
export auro_compiler_subconfig=
export auro_compiler_linker=
export auro_compiler_cpp=
export auro_compiler_thread=
export auro_compiler_pic=
export auro_compiler_vlc=
export auro_compiler_wwise=
export auro_compiler_wall=
export auro_compiler_color=-color
export auro_compiler_mss=-mss_log_in_release
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

function use_mold {
export auro_compiler_linker=-use_mold
auro_notify
}

function use_nomold {
export auro_compiler_linker=
auro_notify
}
function use_ld {
export auro_compiler_linker=
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

function use_gstreamer {
    export auro_compiler_gstreamer=-gstreamer=1
    auro_notify
}
function use_nogstreamer {
    export auro_compiler_gstreamer=
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

function use_wall {
    export auro_compiler_wall=-wall
    auro_notify
}
function use_nowall {
    export auro_compiler_wall=
    auro_notify
}

function use_color {
    export auro_compiler_color=-color
    auro_notify
}
function use_nocolor {
    export auro_compiler_color=
    auro_notify
}

function use_mss {
    export auro_compiler_mss=-mss_log_in_release
    auro_notify
}
function use_nomss {
    export auro_compiler_mss=
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
use_nogstreamer
use_nowwise
use_nowall
use_color
use_vlc

function klone {
    git clone https://git.auro-technologies.com/scm/$1
}
