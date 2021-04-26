call plug#begin('~/.nvim/plugged')
source $gubg/vim/plugins.vim
Plug 'lyuts/vim-rtags'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
    " suggested extra settings:
    " Some server have issues with backup files, see #649
    set nobackup
    set nowritebackup
    " don't give |ins-completion-menu| messages.
    set shortmess+=c
call plug#end()
