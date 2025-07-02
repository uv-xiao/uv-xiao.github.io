#!/bin/bash

# Source environment setup
source "$(dirname "$0")/setup-env.sh"

echo "Building all slides..."
npm exec -c "marp -c marp.config.mjs -I _slide/ -o assets/slide/"

# Copy any PNG images from _slide to assets/slide
if ls _slide/*.png >/dev/null 2>&1; then
    cp _slide/*.png assets/slide/
fi

echo "Slides built successfully!"