#!/bin/bash

#
# Script to generate pdf from images and names, both extracted from
# Workday.
#
# Usage: make-names-n-pic.sh (no arguments)
#
# See: https://github.com/mark-claypool/names-n-pics
#
# Last signficantly modified: January 2022
#

# Required supporting programs:
# + xlsx2csv
# + Latex caption package
# + Latex subcaption package
# + pandoc
# + convert (ImageMagick)

# Uncomment to debug
#set -x

VERSION=v2.0
MD=names-n-pics.md
OUT=names-n-pics.pdf
NAMES=names.txt
IMG=image
ROSTER=roster
CSV=temp.csv

#####################################
# Check for needed programs.
if ! command -v xlsx2csv &> /dev/null ; then
  echo "Error!  Requires 'xlsx2csv'"
  exit
fi
if ! command -v convert &> /dev/null ; then
  echo "Error!  Requires 'convert'"
  exit
fi
if ! command -v xlsx2csv &> /dev/null ; then
  echo "Error!  Requires ' xlsx2csv'"
  exit
fi
if ! command -v pandoc &> /dev/null ; then
  echo "Error!  Requires 'pandoc'"
  exit
fi
if ! command -v latex &> /dev/null ; then
  echo "Error!  Requires 'latex'"
  exit
fi
kpsewhich caption.sty >& /dev/null
if [ ! $? -eq 0 ]; then
  echo "Error!  Requires 'caption.sty'"
  exit    
fi
kpsewhich subcaption.sty >& /dev/null
if [ ! $? -eq 0 ]; then
  echo "Error!  Requires 'subcaption.sty'"
  exit    
fi

#####################################

# Clean up any old files.
echo "Cleaning up old files..."
/bin/rm -f $OUT
/bin/rm -f $MD
/bin/rm -f $NAMES
/bin/rm -f $CSV

# Extract images.
echo "Extracting images..."
pdfimages -png $ROSTER.pdf $IMG

# Extract names.
echo "Extracting names..."
xlsx2csv $ROSTER.xlsx > $CSV
start=`grep -Tn "Email Address" temp.csv | sed s/:/\/g | awk '{print $1}'`
((start=start+1))
tail -n +$start $CSV | \
    awk -F ',' '{print $3, $2}' | \
    grep -v '^[[:blank:]]*$' | \
    sed s/,/\/g | \
    sed s/\"/\/g | \
    grep -v Registered > $NAMES

# Markdown header
echo "Preparing markdown file..."
echo "---" >> $MD
echo "header-includes: |" >> $MD
echo "    \usepackage{caption}" >> $MD
echo "    \usepackage{subcaption}" >> $MD
echo "    \captionsetup[subfigure]{labelformat=empty}" >> $MD
echo "---" >> $MD
echo " " >> $MD

# Class header
header=`grep "Course Section" temp.csv | awk -F',' '{print $2}' | tr -d '\n'`
echo "## $header" >> $MD
echo " " >> $MD

# Make white image for padding (if needed)
convert -size 150x150 xc:white white.png

# Loop through each name, adding to markdown.
echo "Making name + pic for each student: "
i=0
col=1
array=()
while IFS= read -r name; do

  echo -n "."
  
  # array of names
  array+=( "$name" )
  
  # Get next image in sequence"
  image=$IMG-`seq -f "%03g" $i $i`.png
  if [ ! -f "$image" ]; then
    echo $image="(No image)"

  else

    # If width is not 150px then pad.
    width=`file $image | awk '{print $5}'`
    if (( $width < 150 )); then
      offset=$(((150 - $width) / 2))
      convert white.png $image -geometry +$offset+0 -composite temp.png
      mv temp.png $image
    fi

  fi

  # Add to file
  echo "![$name]($image){ width=300px }" >> $MD

  # if done with row, add captions
  if [ "$col" == 3 ]; then

    echo "\begin{figure}[!h]" >> $MD
    echo "\begin{subfigure}[t]{0.3\textwidth}" >> $MD
    echo "\caption{${array[0]}}" >> $MD
    echo "\end{subfigure}" >> $MD
    echo "\hfill" >> $MD
    echo "\begin{subfigure}[t]{0.3\textwidth}" >> $MD
    echo "\caption{${array[1]}}" >> $MD
    echo "\end{subfigure}" >> $MD
    echo "\hfill" >> $MD
    echo "\begin{subfigure}[t]{0.3\textwidth}" >> $MD
    echo "\caption{${array[2]}}" >> $MD
    echo "\end{subfigure}" >> $MD
    echo "\end{figure}" >> $MD

    # Newline.
    echo " " >> $MD

    col=0
    array=()
  fi
  
  i=$((i+1))
  col=$((col+1))
  
done < "$NAMES"

echo " "

# Run pandoc to format markdown to PDF.
echo "Running pandoc..."
pandoc --standalone --self-contained -V fontsize=12pt -V geometry:"margin=1in" -o $OUT $MD

echo "OUTPUT: $OUT"
