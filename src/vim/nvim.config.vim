" Visual mode should use I-shaped cursor
set selection=exclusive

" Indentation settings
" * Global
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab
" * Auro
set cindent  
set cinoptions+=g0
set cinoptions+=+0  

" Searching
set ignorecase
set smartcase

" Utility functions
function! ReadString(message)
  let curline = getline('.')
  call inputsave()
  let name = input(a:message . ': ')
  call inputrestore()
  call setline('.', curline . name)
endfunction
function! InsertOneChar()
    let c = nr2char(getchar())
    let i = 0
    while i < v:count1
        :exec "normal i".c."\el"
        let i += 1
    endwhile
endfunction
command! -count InsertOneCharCmd call InsertOneChar()

" Keyboard mappings
" * Global
map _o :a<CR><CR>.<CR>
map -o :a<CR><CR>.<CR>
map <Space> :InsertOneCharCmd<CR>
" * Per filetype
autocmd BufEnter,BufNewFile,BufRead *.cpp source $gubg/vim/maps.cpp.vim
autocmd BufEnter,BufNewFile,BufRead *.h source $gubg/vim/maps.cpp.vim
autocmd BufEnter,BufNewFile,BufRead *.hpp source $gubg/vim/maps.cpp.vim
autocmd BufEnter,BufNewFile,BufRead *.c source $gubg/vim/maps.cpp.vim

echomsg "gubg/vim/nvim.config.vim loaded"
