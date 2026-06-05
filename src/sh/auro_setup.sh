export auro_publish=$HOME/pub

export auro_bin_dir=$HOME/auro/bin

export PATH=$PATH:$auro_bin_dir
export PATH=$PATH:/opt/local/auro/android-ndk-r21b

export GST_PLUGIN_PATH=$auro_bin_dir

function auro_notify {
    export auro_compiler=${auro_compiler_brand}-${auro_compiler_arch}-${auro_compiler_config}${auro_compiler_subconfig}${auro_compiler_linker}${auro_compiler_cpp}${auro_compiler_thread}${auro_compiler_pic}${auro_compiler_vlc}${auro_compiler_gstreamer}${auro_compiler_wwise}${auro_compiler_wall}${auro_compiler_color}${auro_compiler_mss}
}
export -f auro_notify

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
export auro_compiler_mss=-auro_mss_log_in_release
export auro_test=ut

function use_gcc {
export auro_compiler_brand=gcc
auro_notify
}
export -f use_gcc

function use_clang {
export auro_compiler_brand=clang
auro_notify
}
export -f use_clang

function x32 {
export auro_compiler_arch=x32
auro_notify
}
export -f x32

function x64 {
export auro_compiler_arch=x64
auro_notify
}
export -f x64

function i7 {
export auro_compiler_arch=i7
auro_notify
}
export -f i7

function release {
export auro_compiler_config=release
auro_notify
}
export -f release
function debug {
export auro_compiler_config=debug
auro_notify
}
export -f debug

function normal {
export auro_compiler_subconfig=
auro_notify
}
export -f normal
function rtc {
export auro_compiler_subconfig=-rtc
auro_notify
}
export -f rtc
function profile {
export auro_compiler_subconfig=-profile
auro_notify
}
export -f profile

function use_mold {
export auro_compiler_linker=-use_mold
auro_notify
}
export -f use_mold

function use_nomold {
export auro_compiler_linker=
auro_notify
}
export -f use_nomold
function use_ld {
export auro_compiler_linker=
auro_notify
}
export -f use_ld

function cpp03 {
export auro_compiler_cpp=-cpp03
auro_notify
}
export -f cpp03

function nothread {
export auro_compiler_thread=-nothread
auro_notify
}
export -f nothread

function use_pic {
    export auro_compiler_pic=-pic
    auro_notify
}
export -f use_pic
function use_nopic {
    export auro_compiler_pic=
    auro_notify
}
export -f use_nopic

function use_vlc {
    export auro_compiler_vlc=-vlc
    auro_notify
}
export -f use_vlc
function use_novlc {
    export auro_compiler_vlc=
    auro_notify
}
export -f use_novlc

function use_gstreamer {
    export auro_compiler_gstreamer=-gstreamer=1
    auro_notify
}
export -f use_gstreamer
function use_nogstreamer {
    export auro_compiler_gstreamer=
    auro_notify
}
export -f use_nogstreamer

function use_wwise {
    export auro_compiler_wwise=
    auro_notify
}
export -f use_wwise
function use_nowwise {
    export auro_compiler_wwise=-nowwise
    auro_notify
}
export -f use_nowwise

function use_wall {
    export auro_compiler_wall=-wall
    auro_notify
}
export -f use_wall
function use_nowall {
    export auro_compiler_wall=
    auro_notify
}
export -f use_nowall

function use_color {
    export auro_compiler_color=-color
    auro_notify
}
export -f use_color
function use_nocolor {
    export auro_compiler_color=
    auro_notify
}
export -f use_nocolor

function use_mss {
    export auro_compiler_mss=-auro_mss_log_in_release
    auro_notify
}
export -f use_mss
function use_nomss {
    export auro_compiler_mss=
    auro_notify
}
export -f use_nomss

function publish {
export auro_publish=$1
auro_notify
}
export -f publish

function catch {
export auro_test=$1
auro_notify
}
export -f catch

use_gcc
release
normal
use_pic
use_nogstreamer
use_nowwise
use_nowall
use_color
use_vlc
