map <leader>i   :py3f /usr/share/clang/clang-format-11/clang-format.py<CR>
" map <,-c> :py3f /usr/share/clang/clang-format-11/clang-format.py<cr>
" imap <,-c> <c-o>:py3f /usr/share/clang/clang-format-11/clang-format.py<cr>

" custom setting for clangformat
" let g:neoformat_cpp_clangformat = {
"     \ 'exe': 'clang-format-10',
"     \ 'args': ['-style=file']
" \}
let g:neoformat_cpp_clangformat = {
    \ 'exe': 'clang-format-11',
    \ 'args': ['--style=file']
\}
let g:neoformat_enabled_cpp = ['clangformat']
let g:neoformat_enabled_c = ['clangformat']

