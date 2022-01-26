#!/bin/bash

#
# Script to generate pdf from images and names,
# both extracted from Workday.
#
# Last signficantly modified: January 2022

MD=pic-name.md
OUT=pic-name.pdf
NAMES=names.txt
IMG=image

# Clean up any old files.
/bin/rm -f $OUT
/bin/rm -f $MD

i=0
while IFS= read -r name; do

  echo "$name" 

  # Print "firstname lastname"
  echo "$name" | \
    sed s/,/\/g | \
    sed s/\"/\/g | \
    awk '{print $2, $1}' >> $MD

  # Get next image in sequence"
  image=$IMG-`seq -f "%03g" $i $i`.png
  if [ ! -f "$image" ]; then
    echo "(No image)" >> $MD
  else
    echo "![alt text]($image)" >> $MD
  fi

  # Newline.
  echo " " >> $MD

  i=$((i+1))
  
done < "$NAMES"

echo "Running pandoc..."

pandoc --standalone --self-contained -V fontsize=12pt -V geometry:"margin=1in" -o $OUT $MD

echo "OUTPUT: $OUT"

