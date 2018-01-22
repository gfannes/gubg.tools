" NAFT mappings

" node
map -n o<M-p>[]<M-p><Esc>i
" attribute
map -a $w?]\\|)<CR>a<M-p>()<M-p><Esc>:noh<CR>i
" story
map -s $w?]\\|)<CR>a<M-p>(s:)<M-p><Esc>:noh<CR>i
" end
map -e $w?]\\|)<CR>a<M-p>(e:)<M-p><Esc>:noh<CR>i
" duration
map -d $w?]\\|)<CR>a<M-p>(d:)<M-p><Esc>:noh<CR>i
" block
map -b A<M-p>{<CR>}<M-p><Esc>k$
