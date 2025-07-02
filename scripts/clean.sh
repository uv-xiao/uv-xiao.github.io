#!/bin/bash

# Source environment setup
source "$(dirname "$0")/setup-env.sh"

echo "Cleaning Jekyll build directory..."
bundle exec jekyll clean

echo "Jekyll build directory cleaned!"