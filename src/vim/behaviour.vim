" Auto-save and reloading buffers
let g:auto_save=1
set autoread | autocmd CursorHold * checktime

" Visual mode should use I-shaped cursor
set selection=exclusive

" Searching
set ignorecase
set smartcase

" Add line numbers
set number

" Set linenumbers while printing
set printoptions=number:y

" Do not wrap long lines by default
set nowrap
