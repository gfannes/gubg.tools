""" coc.nvim
" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
" otherwise <cr> doesn't newline as expected:
" Or use `complete_info` if your vim support it, like:
inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
" TODO: same as clang-format? does it use .clang-format?
nmap <silent> <leader>of <Plug>(coc-format)
vmap <silent> <leader>of <Plug>(coc-format-selected)
" list all code actions and ask for user input. (e.g. clang Fixits)
nmap <silent> <leader>oa <Plug>(coc-codeaction)
" Fix autofix problem on current line (q = quick)
nmap <silent> <leader>oq <Plug>(coc-fix-current)
" in normal mode selected means that this is a command that expectes a
" movement like <leader>osap (around paragraph)
nmap <silent> <leader>os <Plug>(coc-codeaction-selected)
vmap <silent> <leader>oa <Plug>(coc-codeaction-selected)
" Remap for do codeAction of selected region, ex: `<leader>aap` for current paragraph, TODO: check this out and find appropriate mapping
" xmap <leader>a  <Plug>(coc-codeaction-selected)
" Fix autofix problem of current line (quick)
nmap <leader>oq  <Plug>(coc-fix-current)
" TODO: find out what this does
nmap <silent> <leader>ol <Plug>(coc-codelens-action)
nmap <silent> <leader>oI <Plug>(coc-diagnostic-info)
nmap <silent> <leader>o[ <Plug>(coc-diagnostic-perv)
nmap <silent> <leader>o] <Plug>(coc-diagnostic-next)
" Use `[g` and `]g` to navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
" when on type or instance -> goto definition.
nmap <silent> <leader>od <Plug>(coc-definition)
" most used feature, easier mapping for above
nmap <silent> <leader>d <Plug>(coc-definition)
" e.g. when on virtual function, find all implementations.
nmap <silent> <leader>oi <Plug>(coc-implementation)
" when on instance -> goto definition of instance type.
nmap <silent> <leader>ot <Plug>(coc-type-definition)
" TODO: seems to only work for files open in buffer or something,
" coc-references does find all references though.
nmap <silent> <leader>on <Plug>(coc-rename)
" find all references of a function, type, instance. Jumps when only one
" result.
nmap <silent> <leader>or <Plug>(coc-references)
" TODO: whut? seems to work in C++ to open #include files, but not in ruby to
" open requires
nmap <silent> <leader>oo <Plug>(coc-openlink)
" Show signature and/or doxygen docs.
nnoremap <silent> <leader>oh :call CocActionAsync('doHover')<cr>
" Use K for show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>
function! s:show_documentation()
  if &filetype == 'vim'
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction
" Use <c-space> for trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()
" Highlight symbol under cursor on CursorHold, problem is that it overrides
" the mark.vim
" autocmd CursorHold * silent call CocActionAsync('highlight')
" TODO move to appropriate place?
" Use `:Format` for format current buffer
command! -nargs=0 Format :call CocAction('format')
" Use `:Fold` for fold current buffer
command! -nargs=? Fold :call CocAction('fold', <f-args>)
" use `:OR` for organize import of current buffer
command! -nargs=0 OR :call CocAction('runCommand', 'editor.action.organizeImport')
" Create mappings for function text object, requires document symbols feature of languageserver. TODO: check, might already work?
" xmap if <Plug>(coc-funcobj-i)
" xmap af <Plug>(coc-funcobj-a)
" omap if <Plug>(coc-funcobj-i)
" omap af <Plug>(coc-funcobj-a)
"
" Use <C-d> for select selections ranges, needs server support, like: coc-tsserver, coc-python. TODO: no clue?
" nmap <silent> <C-d> <Plug>(coc-range-select)
" xmap <silent> <C-d> <Plug>(coc-range-select)
"""" coc.vim ccls lsp provider specific mappings (TODO: move to c cpp only ftplugin folder)
" shortcuts using x as short for cross-reference.
" find all base types, if one, jump to it.
nn <silent> <leader>xb :call CocLocations('ccls','$ccls/inheritance')<cr>
" same as above, but up to 3 levels
" nn <silent> <leader>xb :call CocLocations('ccls','$ccls/inheritance',{'levels':3})<cr>
" find all derived types, if one, jump to it
nn <silent> <leader>xd :call CocLocations('ccls','$ccls/inheritance',{'derived':v:true})<cr>
" derived of up to 3 levels
nn <silent> <leader>xD :call CocLocations('ccls','$ccls/inheritance',{'derived':v:true,'levels':3})<cr>
" caller: find all callers, i.e. find all references.
nn <silent> <leader>xc :call CocLocations('ccls','$ccls/call')<cr>
" callee: which functions are called from this function.
nn <silent> <leader>xC :call CocLocations('ccls','$ccls/call',{'callee':v:true})<cr>
" When on a typename, show member variables / variables in a namespace
nn <silent> <leader>xm :call CocLocations('ccls','$ccls/member')<cr>
" When on a typename, member functions / functions in a namespace
nn <silent> <leader>xf :call CocLocations('ccls','$ccls/member',{'kind':3})<cr>
" nested classes / types in a namespace
nn <silent> <leader>xs :call CocLocations('ccls','$ccls/member',{'kind':2})<cr>
" e.g. when cursor on type, similar to refernces, but only show where it is
" used to instantiate variables or used in function arguments.
nn <silent> <leader>xv :call CocLocations('ccls','$ccls/vars')<cr>
" same as xv, but not function arguments.
nn <silent> <leader>xV :call CocLocations('ccls','$ccls/vars',{'kind':1})<cr>

