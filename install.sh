#! /bin/zsh

set -e

CURDIR=$(pwd)

if [ ! -d "$HOME/.rbenv/" ]; then
  # if exit with error, rm -rf $HOME/.rbenv
  trap 'rm -rf $HOME/.rbenv' ERR
  echo "Installing rbenv..."
  git clone https://github.com/rbenv/rbenv.git $HOME/.rbenv
  cd $HOME/.rbenv && src/configure && make -C src
  cd $CURDIR

  echo "Setting up .zshrc"
  text="# enable rbenv
  if [ -d \"\$HOME/.rbenv/\" ]; then
    export PATH=\"\$HOME/.rbenv/bin:\$PATH\"
    eval \"\$(rbenv init - bash)\"
  fi
  "
  echo "$text" >> $HOME/.zshrc
  # source $HOME/.zshrc

  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init - zsh)"

  echo "Installing ruby-build..."
  mkdir -p "$(rbenv root)"/plugins
  git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build

  sudo apt install -y libssl-dev
  rbenv install 3.1.2
  
  # cancle the trap
  trap - ERR
fi

# assert if $(pwd)!=CURDIR
if [ "$(pwd)" != "$CURDIR" ]; then
  echo "not in the correct directory"
  exit 1
fi

rbenv local 3.1.2
gem install bundle
bundle install

python3 -m pip install --user pipx
pipx install jupyter

gem pristine --all

chmod +x ./localdeploy.sh
chmod +x ./newpost.sh
