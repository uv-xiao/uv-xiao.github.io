#! /bin/bash

occupy=$(sudo lsof -t -i:4000)
if [ -n "$occupy" ]; then
  sudo kill -9 $occupy
fi


# run marp silently
# npx @marp-team/marp-cli@latest --watch _slide/ -I _slide/ -o assets/slide/ &
npm exec -c "marp -c marp.config.mjs -I _slide/ -o assets/slide/"

# for every *.md file in _slide, convert to images
for file in _slide/*.md; do
  ./marpimg.sh $file
done

# cp _slide/*.[png/jpg] assets/slide/
cp _slide/*.png assets/slide/
cp _slide/*.jpg assets/slide/

# start another thread for watching _slide/?

# run jekyll serve silently
bundle exec jekyll serve --lsi
