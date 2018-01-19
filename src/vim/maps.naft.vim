" NAFT mappings

" node
map -n o[]<Esc>i
" attribute
map -a $w?]\\|)<CR>a()<Esc>:noh<CR>i
" story
map -s $w?]\\|)<CR>a(s:)<Esc>:noh<CR>i
" end
map -e $w?]\\|)<CR>a(e:)<Esc>:noh<CR>i
" duration
map -d $w?]\\|)<CR>a(d:)<Esc>:noh<CR>i
" block
map -b A{<CR><Esc>k$
