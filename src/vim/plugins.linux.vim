call plug#begin('~/.nvim/plugged')
source $gubg/vim/plugins.vim

Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'ludovicchabant/vim-gutentags'

" Plug 'Yohannfra/Vim-Goto-Header'
Plug 'vim-scripts/a.vim'

Plug 'lyuts/vim-rtags'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
    " suggested extra settings:
    " Some server have issues with backup files, see #649
    set nobackup
    set nowritebackup
    " don't give |ins-completion-menu| messages.
    set shortmess+=c

Plug 'kevinhwang91/rnvimr'
" Plug 'akinsho/nvim-toggleterm.lua'
Plug 'voldikss/vim-floaterm'

call plug#end()
