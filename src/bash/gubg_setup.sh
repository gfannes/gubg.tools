if [ -z "$gubg" ]; then
  export gubg=$HOME/gubg
fi
export PATH=$gubg/bin:$PATH
export PATH=$PATH:$HOME/software/bin
#gem install bundler jekyll
export PATH=$PATH:$HOME/.gem/ruby/2.6.0/bin
export EDITOR=$gubg/bin/editor
export GIT_EXTERNAL_DIFF=$gubg/bin/git_diff.sh

export PYTHONPATH=$PYTHONPATH:$gubg/gubg.io/src
export PYTHONPATH=$PYTHONPATH:$gubg/gubg.ml/src
export PYTHONPATH=$PYTHONPATH:$gubg/gubg.algo/src

# Enable ** recursion
shopt -s globstar
