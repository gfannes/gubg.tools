" Cpp mappings
map -y a<M-p>" <<  << "<M-p><Esc>4hi

" include <>
map -r O<M-p>#include <<Esc>:call ReadString("Header")<CR>A><M-p><Esc>j
" include ""
map -R O<M-p>#include "<Esc>:call ReadString("Header")<CR>A"<M-p><Esc>j
" guard
map -g i#ifndef HEADER_<Esc>:call ReadString("Path to header")<CR>A_ALREADY_INCLUDED<Esc>$by$o#define <Esc>p-o-o-o-oo#endif<Esc>kkk
" block
map -b -oa<M-p>{<Esc>-oa}<M-p><Esc>k$
" class
map -c o<M-p>class <Esc>:call ReadString("Class name")<CR>-oa{<Esc>-oapublic:<Esc>-oaprivate:<Esc>-oa};<M-p><Esc>kk$
" struct
map -C o<M-p>struct <Esc>:call ReadString("Struct name")<CR>-oa{<Esc>-oa};<M-p><Esc>k$
" namespace
map -s A<M-p>namespace <Esc>:call ReadString("Namespace name")<CR>A { <Esc>-oa}<M-p><Esc>Jk$
" switch
map -S o<M-p>switch (<Esc>:call ReadString("Switcher")<CR>A)<Esc>o{<Esc>ocase : break;<Esc>o}<M-p><Esc>khhhhhhh
" for
map -f o<M-p>for (auto ix = 0u; ix < size; ++ix)<Esc>o{<Esc>o}<M-p><Esc>kk$bbbb
" template
map -t o<M-p>template <typename <Esc>:call ReadString("Type")<CR>A><M-p><Esc>$
" lambda
map -a o<M-p>auto <Esc>:call ReadString("Lambda")<CR>A = [&]()<CR>{<CR>};<M-p><Esc>kk$i
" TEST_CASE_FAST
map -e o<M-p>TEST_CASE_FAST(" tests", "[]")<M-p><Esc>-bkbbbbla
" SECTION
map -E o<M-p>SECTION("")<M-p><Esc>-bkbla
" REQUIRE
map -u o<M-p>REQUIRE();<M-p><Esc>ba

" MSS
map -n jO<M-p>MSS_BEGIN(bool);<Esc>oMSS_END();<M-p><Esc>k$
map -N jO<M-p>MSS_BEGIN(<Esc>:call ReadString("ReturnCode")<CR>A);<Esc>oMSS_END();<M-p><Esc>k$
map -m jO<M-p>MSS();<M-p><Esc>hi
map -v o<M-p>bool<Esc>o{<Esc>oMSS_BEGIN(bool);<Esc>oMSS_END();<Esc>o}<M-p><Esc>kkkkA 
