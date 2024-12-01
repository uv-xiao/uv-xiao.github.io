#! /bin/bash

# $1 is the file to watch
if [ -z "$1" ]; then
  echo "Usage: $0 <file>"
  exit 1
fi

# run marp silently, when $1 is given, watch $1
npm exec -c "marp -c marp.config.mjs -w $1 -o $1.html"
