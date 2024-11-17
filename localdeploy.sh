#! /bin/bash

occupy=$(sudo lsof -t -i:4000)
if [ -n "$occupy" ]; then
  sudo kill -9 $occupy
fi

# run jekyll serve silently
bundle exec jekyll serve --lsi
