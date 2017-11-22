"source $gubg/vim/colors/darkblue.vim
"source $gubg/vim/colors/ir_black.vim
colorscheme desert
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab
set autochdir
set nowrap
set visualbell
set scroll=1
"Remove the 3000 character syntax highlighting limit
set synmaxcol=0

function! ReadString(message)
  let curline = getline('.')
  call inputsave()
  let name = input(a:message . ': ')
  call inputrestore()
  call setline('.', curline . name)
endfunction
map _o :a<CR><CR>.<CR>
map -o :a<CR><CR>.<CR>

function! InsertOneChar()
    let c = nr2char(getchar())
    let i = 0
    while i < v:count1
        :exec "normal i".c."\el"
        let i += 1
    endwhile
endfunction
command -count InsertOneCharCmd call InsertOneChar()
map <Space> :InsertOneCharCmd<CR>

command LongLines /\%>110v.\+

autocmd BufEnter,BufNewFile,BufRead *.rb source $gubg/vim/maps.ruby.vim
autocmd BufEnter,BufNewFile,BufRead *.lua source $gubg/vim/maps.lua.vim
autocmd BufEnter,BufNewFile,BufRead *.d source $gubg/vim/maps.d.vim
autocmd BufEnter,BufNewFile,BufRead *.cpp source $gubg/vim/maps.cpp.vim
autocmd BufEnter,BufNewFile,BufRead *.h source $gubg/vim/maps.cpp.vim
autocmd BufEnter,BufNewFile,BufRead *.hpp source $gubg/vim/maps.cpp.vim
autocmd BufEnter,BufNewFile,BufRead *.c source $gubg/vim/maps.cpp.vim
autocmd BufEnter,BufNewFile,BufRead *.inc source $gubg/vim/maps.cpp.vim
autocmd BufEnter,BufNewFile,BufRead *.chai source $gubg/vim/maps.cpp.vim
autocmd BufEnter,BufNewFile,BufRead *.rs source $gubg/vim/maps.rust.vim
autocmd BufEnter,BufNewFile,BufRead *.js source $gubg/vim/maps.js.vim
autocmd BufEnter,BufNewFile,BufRead *.jscad source $gubg/vim/maps.js.vim
""autocmd BufEnter,BufNewFile,BufRead *.rs source $gubg/vim/maps.cpp.vim
""autocmd BufEnter,BufNewFile,BufRead *.rs source $gubg/vim/rust.vim
autocmd BufEnter,BufNewFile,BufRead *.txt source $gubg/vim/maps.markdown.vim
autocmd BufEnter,BufNewFile,BufRead *.html source $gubg/vim/maps.xml.vim
autocmd BufEnter,BufNewFile,BufRead *.xml source $gubg/vim/maps.xml.vim
autocmd BufEnter,BufNewFile,BufRead *.vcxproj source $gubg/vim/maps.xml.vim
autocmd BufEnter,BufNewFile,BufRead *.props source $gubg/vim/maps.xml.vim
autocmd BufEnter,BufNewFile,BufRead *.json source $gubg/vim/json.vim
autocmd BufEnter,BufNewFile,BufRead *.asciidoc source $gubg/vim/asciidoc2.vim
autocmd BufEnter,BufNewFile,BufRead *.adoc source $gubg/vim/asciidoc2.vim
autocmd BufEnter,BufNewFile,BufRead *.puml source $gubg/vim/plantuml.vim
autocmd BufEnter,BufNewFile,BufRead *.tjp source $gubg/vim/tjp.vim
autocmd BufEnter,BufNewFile,BufRead *.tji source $gubg/vim/tjp.vim
"au! BufRead,BufNewFile *.json set filetype=json foldmethod=syntax 
autocmd BufNewFile,BufReadPost *.md set filetype=markdown

autocmd BufEnter,BufNewFile,BufRead *.naft source $gubg/vim/maps.naft.vim
" autocmd BufEnter,BufNewFile,BufRead *.naft source $gubg/vim/vim-tree/syntax/tree.vim
autocmd BufEnter,BufNewFile,BufReadPost *.naft set filetype=javascript

""source $gubg/vim/hexmode.vim

command -bar Q q

source $gubg/vim/tabnumber.vim
source $gubg/vim/autoclose.vim
source $gubg/vim/cscope_maps.vim
""source $gubg/vim/git.vim
""source $gubg/vim/rust.vim

:au FocusLost * silent! wa

set ignorecase
set smartcase

source $gubg/vim/autoload/pathogen.vim
execute pathogen#infect($gubg.'/vim/bundle/{}')

syntax on
filetype plugin indent on

""let g:exvim_custom_path='$gubg/extern/main/'
""source $gubg/extern/main/.vimrc

set runtimepath^=$gubg.'/vim/bundle/ctrlp.vim'

set complete-=i
set wrap

" set number
set printoptions=number:y

"auro style
set cindent  
set cinoptions+=g0
set cinoptions+=+0  
