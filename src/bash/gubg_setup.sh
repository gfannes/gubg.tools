if [ -z "$gubg" ]; then
  export gubg=$HOME/gubg
fi
export PATH=$gubg/bin:$PATH
#gem install bundler jekyll
export PATH=$PATH:$HOME/.gem/ruby/2.6.0/bin
export EDITOR=$gubg/bin/editor
export GIT_EXTERNAL_DIFF=$gubg/bin/git_diff.sh

# Enable ** recursion
shopt -s globstar
