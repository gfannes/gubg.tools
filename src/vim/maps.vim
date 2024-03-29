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
map <leader><Space> <C-o>
map <leader>s :let @s = ReadStringNoEcho("Search string")<CR>/\<<C-R>s\><CR>
nnoremap <leader>cd :cd %:p:h<CR>:pwd<CR>

" let g:goto_header_use_find = 0 " By default it's value is 0
" nnoremap <leader>h :GotoHeader <CR>
nnoremap <leader>h :A <CR>

" * Per filetype
" ** C/C++
autocmd BufEnter,BufNewFile,BufRead *.cpp source $gubg/vim/maps.cpp.vim
autocmd BufEnter,BufNewFile,BufRead *.hpp source $gubg/vim/maps.cpp.vim
autocmd BufEnter,BufNewFile,BufRead *.c source $gubg/vim/maps.c.vim
autocmd BufEnter,BufNewFile,BufRead *.h source $gubg/vim/maps.c.vim
" ** Rust
autocmd BufEnter,BufNewFile,BufRead *.rs source $gubg/vim/maps.rust.vim
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
" * XML
autocmd BufEnter,BufNewFile,BufRead *.xml source $gubg/vim/maps.xml.vim
autocmd BufEnter,BufNewFile,BufRead *.html source $gubg/vim/maps.xml.vim
" * OpenSCAD
autocmd BufEnter,BufNewFile,BufRead *.scad source $gubg/vim/maps.cpp.vim
autocmd BufEnter,BufNewFile,BufRead *.scad set syntax=cpp

"" * NERDTree
map <leader>g :NERDTree<CR>
" * rnvimr
"map <leader>g :RnvimrToggle<CR>
"" * floaterm ranger
"map <leader>g :FloatermNew ranger<CR>

"" * nvim-toggleterm
"map <leader>t :execute 'ToggleTerm dir='.expand('%:p:h')<CR>
" * floaterm
map <leader>t :FloatermNew<CR>
