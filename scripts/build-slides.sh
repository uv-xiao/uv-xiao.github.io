#!/bin/bash

# Source environment setup
source "$(dirname "$0")/setup-env.sh"

# Check if _slide directory exists and has markdown files
if [ ! -d "_slide" ] || ! find _slide -name "*.md" -type f | grep -q .; then
    echo "No slide files found in _slide/ directory"
    exit 0
fi

echo "Building all slides..."
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

echo "Slides built successfully!"