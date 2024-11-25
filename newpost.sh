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
# date=$(date +"%Y-%m-%d")
# set date to yesterday to avoid "has a future date"
date=$(date -d "yesterday" +"%Y-%m-%d")
# time=$(date +"%H:%M:%S")
time="00:00:00" # set as 00:00:00 to avoid "has a future date"

# create the post
post_path="_posts/$date-$title.md"

# create the post
touch $post_path

# echo header

echo "---
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
" > $post_path


echo "Created post at $post_path"
