#! /bin/bash

if [! -d "$HOME/.rbenv/"]; then
  echo "Installing rbenv..."
  git clone https://github.com/rbenv/rbenv.git $HOME/.rbenv
  cd $HOME/.rbenv && src/configure && make -C src

  echo "Setting up .zshrc"
  text="# enable rbenv
  if [ -d "$HOME/.rbenv/" ]; then
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval \"\$(rbenv init - bash)\"
  fi
  "
  echo "$text" >> $HOME/.zshrc
  source $HOME/.zshrc

  echo "Installing ruby-build..."
  mkdir -p "$(rbenv root)"/plugins
  git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build

  sudo apt install -y libssl-dev
  rbenv install 3.1.2
fi

echo "make sure we're inside a jekyll project"
rbenv local 3.1.2
gem install bundle
bundle install

python3 -m pip install --user pipx
pipx install jupyter

gem pristine --all

chmod +x ./localdeploy.sh
