#!/bin/bash

# Source environment setup
source "$(dirname "$0")/setup-env.sh"

# Try to free port 4000 without sudo
if lsof -t -i:4000 > /dev/null 2>&1; then
    echo "Port 4000 is in use. Please stop the process using it or use a different port."
    echo "You can check what's using port 4000 with: lsof -i:4000"
    exit 1
fi

# Build slides only if _slide directory exists and has markdown files
if [ -d "_slide" ] && find _slide -name "*.md" -type f | grep -q .; then
    echo "Building slides..."
    npm exec -c "marp -c marp.config.mjs -I _slide/ -o assets/slide/"

    # Copy any image files from _slide to assets/slide, preserving directory structure
    image_files=$(find _slide -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.svg" \))
    if [ -n "$image_files" ]; then
        echo "Copying slide images..."
        echo "$image_files" | while read -r img_file; do
            # Get relative path and create destination directory if needed
            rel_path="${img_file#_slide/}"
            dest_dir="assets/slide/$(dirname "$rel_path")"
            mkdir -p "$dest_dir"
            cp "$img_file" "assets/slide/$rel_path"
        done
    fi
fi

# Start Jekyll server
echo "Starting Jekyll server on http://localhost:4000"
bundle exec jekyll serve --lsi