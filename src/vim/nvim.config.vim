" Plugins
call plug#begin('~/.nvim/plugged')
Plug 'tpope/vim-sensible'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'tpope/vim-commentary'
Plug '907th/vim-auto-save'
Plug 'lyuts/vim-rtags'
Plug 'jiangmiao/auto-pairs'
Plug 'junegunn/seoul256.vim'
Plug 'jeetsukumaran/vim-filebeagle'
" Plug 'gfannes/personal-vim'
call plug#end()

" Auto-save and reloading buffers
let g:auto_save=1
set autoread | autocmd CursorHold * checktime

" When using a dark terminal background
set background=dark

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
" ** C/C++
autocmd BufEnter,BufNewFile,BufRead *.cpp source $gubg/vim/maps.cpp.vim
autocmd BufEnter,BufNewFile,BufRead *.h source $gubg/vim/maps.cpp.vim
autocmd BufEnter,BufNewFile,BufRead *.hpp source $gubg/vim/maps.cpp.vim
autocmd BufEnter,BufNewFile,BufRead *.c source $gubg/vim/maps.cpp.vim
" * NAFT
autocmd BufEnter,BufNewFile,BufRead *.naft source $gubg/vim/maps.naft.vim
autocmd BufEnter,BufNewFile,BufReadPost *.naft set filetype=javascript

" echomsg "gubg/vim/nvim.config.vim loaded"
