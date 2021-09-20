os=unknown
unamestr=`uname`
if [[ $unamestr == Linux ]]; then
  os=linux
fi
if [[ $unamestr == Darwin ]]; then
  os=macos
fi
