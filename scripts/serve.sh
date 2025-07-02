#!/bin/bash

# Source environment setup
source "$(dirname "$0")/setup-env.sh"

# Try to free port 4000 without sudo
if lsof -t -i:4000 > /dev/null 2>&1; then
    echo "Port 4000 is in use. Please stop the process using it or use a different port."
    echo "You can check what's using port 4000 with: lsof -i:4000"
    exit 1
fi

# Build slides first
echo "Building slides..."
npm exec -c "marp -c marp.config.mjs -I _slide/ -o assets/slide/"

# # Convert all slides to images
# for file in _slide/*.md; do
#     if [ -f "$file" ]; then
#         bash ./scripts/slide-to-images.sh "$file"
#     fi
# done

# Copy slide images
if ls _slide/*.png >/dev/null 2>&1; then
    cp _slide/*.png assets/slide/
fi

# Start Jekyll server
echo "Starting Jekyll server on http://localhost:4000"
bundle exec jekyll serve --lsi