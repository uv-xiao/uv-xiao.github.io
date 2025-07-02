#!/bin/bash

# Check if file argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <file>"
  exit 1
fi

dirname=$(dirname "$1")
basename=$(basename "$1")
woext=${basename%.*}

echo "Converting $basename to images..."

# Create assets/slide_img directory if it doesn't exist
mkdir -p assets/slide_img

# Convert to images
npm exec -c "marp -c marp.config.mjs \"$1\" --images png"

# Move generated images to assets/slide_img/
if ls "$dirname/$woext".*.png >/dev/null 2>&1; then
    mv "$dirname/$woext".*.png assets/slide_img/
    echo "Images saved to assets/slide_img/"
fi