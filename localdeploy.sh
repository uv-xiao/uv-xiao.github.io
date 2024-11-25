#! /bin/bash

occupy=$(sudo lsof -t -i:4000)
if [ -n "$occupy" ]; then
  sudo kill -9 $occupy
fi


# run marp silently
npx @marp-team/marp-cli@latest --watch _slide/ -I _slide/ -o assets/slide/ &

# run jekyll serve silently
bundle exec jekyll serve --lsi
