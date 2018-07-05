" Default fzf layout
" - down / up / left / right
let g:fzf_layout = { 'down': '~80%' }

" Customize fzf colors to match your color scheme
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }

if has('win32')
    let g:fzf_history_dir = '$HOME/.fzf_vim_history'
else
    let g:fzf_directories = '~/.fzf_vim_history'
endif

"FZF keymaps
" https://github.com/junegunn/fzf.vim#commands
nnoremap <leader>fb  :Buffers<CR>
" nnoremap <leader>b   :Buffers<CR>
nnoremap <leader>ff  :Files<CR>
nnoremap <leader>fgf :GFiles<CR>
nnoremap <leader>fag :Ag<CR>
nnoremap <leader>fl  :Lines<CR>
nnoremap <leader>fh  :History<CR>
nnoremap <leader>;   :History<CR>
nnoremap <leader>fs  :Snippets<CR>
nnoremap <leader>fco :Commits<CR>
nnoremap <leader>fcb :BCommits<CR>
nnoremap <leader>fw  :Windows<CR>

" " Customize fzf colors to match your color scheme
" " let g:fzf_colors =
" " \ { 'fg':      ['fg', 'Normal'],
" "   \ 'bg':      ['bg', 'Normal'],
" "   \ 'hl':      ['fg', 'Comment'],
" "   \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
" "   \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
" "   \ 'hl+':     ['fg', 'Statement'],
" "   \ 'info':    ['fg', 'PreProc'],
" "   \ 'border':  ['fg', 'Ignore'],
" "   \ 'prompt':  ['fg', 'Conditional'],
" "   \ 'pointer': ['fg', 'Exception'],
" "   \ 'marker':  ['fg', 'Keyword'],
" "   \ 'spinner': ['fg', 'Label'],
" "   \ 'header':  ['fg', 'Comment'] }
" " Some default colors didn't render well on solarized, they where
" " difficult to read. The other colors I liked. So adjusted some of them:
" let g:fzf_colors = {
"             \ 'info':    ['fg', 'PreProc'],
"             \ 'prompt':  ['fg', 'Conditional'],
"             \ 'spinner': ['fg', 'Label']
"             \ }
" " when search with ag, only match content, not filename
" command! -bang -nargs=* Ag call fzf#vim#ag(<q-args>, {'options': '--delimiter : --nth 4..'}, <bang>0) b
" " Use ripgrep to list searches, should be faster
" command! -bang -nargs=* Rg
"             \ call fzf#vim#grep(
"             \   'rg --column --line-number --no-heading --color=always '.shellescape(<q-args>), 1,
"             \   <bang>0 ? fzf#vim#with_preview('up:60%')
"             \           : fzf#vim#with_preview('right:50%:hidden', '?'),
"             \   <bang>0)
" " Files command with preview window
" " command! -bang -nargs=? -complete=dir Files
"             " \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)
" 
