" Python mappings

" from import
map -R O<M-p>from <Esc>:call ReadString("Package")<CR>A import <M-p><Esc>A
" class
map -c o<M-p>class <Esc>:call ReadString("Class name")<CR>A:<CR>def __init__(self):<Esc><M-p><Esc>$h
" def
map -d o<M-p>def <Esc>:call ReadString("Function name")<CR>A(self):<Esc><M-p><Esc>$h
" assign
map -a o<M-p>self.<Esc>:call ReadString("Variable")<CR>A = <Esc><M-p><Esc>A
" self. on a new line
map -u o<M-p>self.<Esc><M-p><Esc>A
" self. inline
map -e aself.
