#!/bin/bash

set -e

# Source environment setup
source "$(dirname "$0")/setup-env.sh"

# Install Ruby gems
echo "Installing Ruby gems..."
gem install bundler --no-document
bundle config set --local path "${GEM_HOME}"
bundle install

# Install npm packages
echo "Installing npm packages..."
npm install

echo "Installation complete!"