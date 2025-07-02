#!/bin/bash

# Parse arguments or print help
if [ $# -eq 0 ]; then
    echo "Usage: $0 \"Post Title\""
    echo "Creates a new blog post with the given title"
    exit 1
fi

title="$1"

# Set date to yesterday to avoid "has a future date" error
date=$(date -d "yesterday" +"%Y-%m-%d")
time="00:00:00"

# Create the post path
post_path="_posts/$date-$title.md"

# Create the post with frontmatter
cat > "$post_path" << EOF
---
layout: post
title: $title
date: $date $time
description:
tags:
categories:
tabs: true
thumbnail:
mermaid:
  enabled: true
  zoomable: true
toc:
  beginning: true
  # sidebar: left
pretty_table: true
tikzjax: true
pseudocode: true
---

EOF

echo "Created post at $post_path"