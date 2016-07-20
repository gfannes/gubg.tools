" Tree mappings

" node
map -n <Bslash>ao()<Esc><Bslash>ai
" attribute
map -a <Bslash>a$w?)\\|]<CR>a[]<Esc><Bslash>a:noh<CR>i
" story
map -s <Bslash>a$w?)\\|]<CR>a[s:]<Esc><Bslash>a:noh<CR>i
" end
map -e <Bslash>a$w?)\\|]<CR>a[e:]<Esc><Bslash>a:noh<CR>i
" duration
map -d <Bslash>a$w?)\\|]<CR>a[d:]<Esc><Bslash>a:noh<CR>i
" block
map -b <Bslash>aA{<Esc>o}<Esc><Bslash>ak$
