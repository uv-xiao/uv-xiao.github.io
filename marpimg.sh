#! /bin/bash

# $1 is the file to be converted to images
if [ -z "$1" ]; then
  echo "Usage: $0 <file>"
  exit 1
fi

dirname=$(dirname $1)
basename=$(basename $1)
woext=${basename%.*}

echo $dirname
echo $basename
echo $woext


# run marp silently, when $1 is given, watch $1
npm exec -c "marp -c marp.config.mjs $1 --images png"

# mv $dirname/$woext.*.png assets/slide_img/
mv $dirname/$woext.*.png assets/slide_img/