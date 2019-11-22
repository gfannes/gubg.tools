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

" Overrule ruby indentation that is set in ftplugin
autocmd FileType ruby setlocal expandtab shiftwidth=4 tabstop=4
