#! /bin/bash

# first argument is the title
# parse argments or print help
if [ $# -eq 0 ]; then
    echo "Usage: $0 \"Post Title\""
    echo "Creates a new blog post with the given title"
    exit 1
fi

title="$1"

# get date
date=$(date +"%Y-%m-%d")

# create the post
post_path="_posts/$date-$title.md"

# create the post
touch $post_path

# echo header

echo "---
layout: post
title: supported features
date: 2024-11-18 00:32:13
description: this is what features are supported in posts
tags:
categories: sample-posts
tabs: true
thumbnail: assets/img/9.jpg
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
" > $post_path


echo "Created post at $post_path"
