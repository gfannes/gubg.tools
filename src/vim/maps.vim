" Utility functions
function! ReadString(message)
  let curline = getline('.')
  call inputsave()
  let name = input(a:message . ': ')
  call inputrestore()
  call setline('.', curline . name)
endfunction
function! ReadStringNoEcho(message)
  let curline = getline('.')
  call inputsave()
  let name = input(a:message . ': ')
  call inputrestore()
  call setline('.', curline)
  return name
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
map <leader>s :let @s = ReadStringNoEcho("Search string")<CR>/\<<C-R>s\><CR>
nnoremap <leader>cd :cd %:p:h<CR>:pwd<CR>
" * Per filetype
" ** C/C++
autocmd BufEnter,BufNewFile,BufRead *.cpp source $gubg/vim/maps.cpp.vim
autocmd BufEnter,BufNewFile,BufRead *.h source $gubg/vim/maps.cpp.vim
autocmd BufEnter,BufNewFile,BufRead *.hpp source $gubg/vim/maps.cpp.vim
autocmd BufEnter,BufNewFile,BufRead *.c source $gubg/vim/maps.cpp.vim
" * ASD
autocmd BufEnter,BufNewFile,BufRead *.asd source $gubg/vim/maps.cpp.vim
autocmd BufEnter,BufNewFile,BufReadPost *.asd set filetype=cpp
" * Asymptote
autocmd BufEnter,BufNewFile,BufRead *.asy source $gubg/vim/maps.cpp.vim
autocmd BufEnter,BufNewFile,BufReadPost *.asy set filetype=cpp
" * NAFT
autocmd BufEnter,BufNewFile,BufRead *.naft source $gubg/vim/maps.naft.vim
autocmd BufEnter,BufNewFile,BufReadPost *.naft set filetype=javascript
autocmd BufEnter,BufNewFile,BufRead *.pit source $gubg/vim/maps.naft.vim
autocmd BufEnter,BufNewFile,BufReadPost *.pit set filetype=javascript
" * Python
autocmd BufEnter,BufNewFile,BufRead *.py source $gubg/vim/maps.python.vim
autocmd BufEnter,BufNewFile,BufReadPost *.py set filetype=python
" * NERDTree
map <leader>g :NERDTree<CR>
