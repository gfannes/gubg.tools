" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<tab>"  " use <Tab> to trigger autocompletion
let g:UltiSnipsJumpForwardTrigger="<c-j>"
let g:UltiSnipsJumpBackwardTrigger="<c-k>"

" Place your snippets in $HOME/.config/nvim/my-snippets/ft.snippets
let g:UltiSnipsSnippetDirectories=["UltiSnips", "my-snippets"]

map -r :call UltiSnips#RefreshSnippets()<CR>
