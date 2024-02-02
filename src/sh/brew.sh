if [ $gubg_use_brew_clang == 1 ]; then
  export PATH=/usr/local/opt/llvm/bin:$PATH
  export LDFLAGS=-L/usr/local/opt/llvm/lib
  export CPPFLAGS=-I/usr/local/opt/llvm/include
fi
