gubg.tools
==========

Development tools

## Neovim

### Windows

* Install the [prebuilts](https://github.com/neovim/neovim/wiki/Installing-Neovim)
* Create `%userprofile\AppData\Local\nvim\init.vim` as `source $gubg/vim/nvim.windows.vim`

### Linux

* Create `.config\nvim\init.vim` as `source $gubg/vim/nvim.linux.vim`

### Raspberry PI

Build [neovim](https://github.com/neovim/neovim.git) from source
* `sudo apt-get install git`
* `git clone https://github.com/neovim/neovim.git`
* `sudo apt-get install libtool libtool-bin autoconf automake cmake g++ pkg-config unzip`
* `cd neovim`
* `make CMAKE_BUILD_TYPE=RelWithDebInfo`
* `sudo make install`

### VIM Plug

Install [vim-plug](https://github.com/junegunn/vim-plug)

* Linux: `curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim`
* Run `:PlugInstall` the first time

### Language Server Protocol (LSP)

* [CCLS](https://github.com/MaskRay/ccls): LSP server for C++
  * Install `llvm`: `sudo pacman -S llvm llvm-libs`
  * Build and install via `rake run`
* [CoC](https://github.com/neoclide/coc.nvim): LSP client implementation
  * Install `npm` and `yarn`: `sudo pacman -S npm yarn`
  * Update .vim scripts: `rake prepare`
  * Reload .vim scripts: `:source ~/.config/nvim/init.vim`
  * Install plugin: `:PlugInstall`
  * Open coc configuration file: `:CocConfig` (`~/.config/nvim/coc-settings.json`)
    * Handled by `rake prepare`
* Ruby support
  * Install `solargraph` ruby LSP server: `gem install --user solargraph`
  * `:CocInstall coc-solargraph`
  * Install solargraph config file
    * Via `rake prepare`
    * or `solargraph config` and adjust the `require:` folder pattern

### YouCompleteMe

* Run `:PlugInstall` to install
* Make sure you have a `CMakeLists.txt` file, eg created via [cook](http://cook-build.org).
* Open [nvim](https://neovim.org) and run `:YcmGenerateConfig`
  * This translates the `CMakeLists.txt` into a `.ycm_extra_conf.py`

## Vim

### rtags

* Install rtags: `yaourt rtags`
* Install rtags-vim plugin: done in `rakefile.rb`
* Create `compile_commands.json` file via following code:

```
function compile_commands {
    rm -rf build_compile_commands
    mkdir build_compile_commands
    cd build_compile_commands
    cmake .. -DCMAKE_EXPORT_COMPILE_COMMANDS=1
    cp compile_commands.json ..
    cd ..
    rm -rf build_compile_commands
}
```

* Run `rdm &`
* Run `rc -J .` from the toplevel folder where the `compile_commands.json` is located.
* See commands on [https://github.com/Andersbakken/rtags](rtags site).

### Links

* [Learn vimscript the hard way](http://learnvimscriptthehardway.stevelosh.com/)

## License

This software is licensed under the EUPL v1.1 license with the explicit interpretation of the term _modification_ as explained in [license.txt](license.txt).

I try to be as permissive as possible, when in doubt, please contact me.
