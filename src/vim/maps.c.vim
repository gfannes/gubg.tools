" C mappings

" include <>
map -r O<M-p>#include <<Esc>:call ReadString("Header")<CR>A><M-p><Esc>j
" include ""
map -R O<M-p>#include "<Esc>:call ReadString("Header")<CR>A"<M-p><Esc>j
" guard
map -g i#ifndef HEADER_<Esc>:call ReadString("Path to header")<CR>A_ALREADY_INCLUDED<Esc>$by$o#define <Esc>p-o-o-o-oo#endif<Esc>kkk
" block
map -b -oa<M-p>{<Esc>-oa}<M-p><Esc>k$
" struct
map -C o<M-p>typedef struct <Esc>:call ReadString("Struct name")_<CR>-oa{<Esc>-oa};<M-p><Esc>k$
" switch
map -S o<M-p>switch (<Esc>:call ReadString("Switcher")<CR>A)<Esc>o{<Esc>ocase : break;<Esc>o}<M-p><Esc>khhhhhhh
" for
map -f o<M-p>AURO_FOR_BEGIN(unsigned int i = 0, i < size, ++i)<Esc>o{<Esc>o}<Esc>oAURO_FOR_END()<M-p><Esc>khhhhhhh

" MSS
map -n jO<M-p>MSS_BEGIN_RC(auro_ReturnCode_t);<Esc>oMSS_END_RC();<M-p><Esc>k$
map -N jO<M-p>MSS_BEGIN_B();<Esc>oMSS_END_RC();<M-p><Esc>k$
map -m jO<M-p>MSS_RC();<M-p><Esc>hi
map -M jO<M-p>MSS_B();<M-p><Esc>hi
map -v o<M-p>auro_ReturnCode_t<Esc>o{<Esc>oMSS_BEGIN_RC(auro_ReturnCode_t);<Esc>oMSS_END_RC();<Esc>o}<M-p><Esc>kkkkA 
