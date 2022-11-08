export NNN_PLUG="p:preview-tui;f:fzopen"

#Colors
nnn_blk="c1"
nnn_chr="e2"
nnn_dir="32"
nnn_exe="2e"
nnn_fil="00"
nnn_hrd="60"
nnn_lnk="33"
nnn_mis="f7"
nnn_orp="c6"
nnn_pip="d6"
nnn_soc="ab"
nnn_und="c4"

export NNN_FCOLORS=${nnn_blk}${nnn_chr}${nnn_dir}${nnn_exe}${nnn_fil}${nnn_hrd}${nnn_lnk}${nnn_mis}${nnn_orp}${nnn_pip}${nnn_soc}${nnn_und}
export NNN_FIFO="/tmp/nnn.fifo"

alias nnn="nnn -A -e"
