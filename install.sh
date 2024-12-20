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
pipx install jupyter --include-deps

gem pristine --all

# if nvm is not installed(command -v nvm does not print nvm), install it
if ! command -v nvm &> /dev/null
then
  wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  source $HOME/.zshrc
fi

# if node is not installed, install it
if ! node -v &> /dev/null
then
  nvm install node
fi

npm -v

npm install -D @marp-team/marp-cli

sudo apt install x11-apps -y

if ! command -v google-chrome &> /dev/null
then
  wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo apt install --fix-missing ./google-chrome-stable_current_amd64.deb
fi

rm ./google-chrome-stable_current_amd64.deb

chmod +x ./localdeploy.sh
chmod +x ./newpost.sh
chmod +x ./marpimg.sh