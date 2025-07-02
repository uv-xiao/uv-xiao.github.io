#!/bin/bash

# Source environment setup
source "$(dirname "$0")/setup-env.sh"

echo "Building Jekyll site..."
bundle exec jekyll build

echo "Jekyll site built successfully!"