#!/bin/bash

# Check if file argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <file>"
  exit 1
fi

echo "Watching $1 for changes..."
npm exec -c "marp -c marp.config.mjs -w \"$1\" -o \"$1.html\""