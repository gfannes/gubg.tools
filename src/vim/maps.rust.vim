" Rust mappings

" println!()
map -p Aprintln!("");<Esc>==$hhi
" struct
map -c o<M-p>struct <Esc>:call ReadString("Struct name")<CR>-oa{<Esc>-oa}<M-p><Esc>k$
" for
map -f o<M-p>for el in <Esc>o{<Esc>o}<M-p><Esc>kkA
" block
map -b -oa<M-p>{<Esc>-oa}<M-p><Esc>k$

"
"
" include ""
" map -r <Bslash>aOextern crate <Esc>:call ReadString("Crate")<CR>A;<Esc>j<Bslash>a
" " block
" map -b -o<Bslash>aa{<Esc>-oa}<Esc><Bslash>ak$
" " for
" map -f <Bslash>aofor (<Esc>:call ReadString("Type")<CR>A::iterator it = <Esc>:call ReadString("Container")<CR>A.begin(); it != .end(); ++it)<Esc>o{<Esc>o}<Esc><Bslash>akhhhhhhh
