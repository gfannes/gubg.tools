" When using a dark terminal background
set background=light

" Size
if os == "windows"
set lines=50 columns=190
endif
if os == "linux"
set lines=60 columns=190
endif

" Font
if os == "windows"
set gfn=Courier\ New:h12:cANSI
endif
if os == "linux"
set gfn=Monospace\ 11
endif

" Colorscheme
colorscheme desert
