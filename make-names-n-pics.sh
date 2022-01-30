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

VERSION=v2.1
MD=names-n-pics.md
OUT=names-n-pics.pdf
NAMES=names.txt
IMG=image
ROSTER=roster
CSV=temp.csv
MAX_COLS=3

#####################################
# usage - print usage message and quit.
function usage() {
  echo "make-names-n-pics.sh ($VERSION) - create classlist with pictures"
  echo "  usage: make-names-n-pics.sh [-hd]"
  echo "         -d  turn on debug (default off)"
  echo "         -h  this help message"
  exit 1
}

#######################################
# parse command line args.
while getopts "dh?" opt; do
  case "${opt}" in
    d)  set -x
	;;
    h|\?|*)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

if [ ! "$#" == "0" ] ; then
  echo "Error!  No command line arguements needed."
  usage
fi

#####################################
# Check for needed utility programs.
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
kpsewhich caption.sty >& /dev/null  # kpsewhich should come with latex
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
# Add one caption.
# $1 - student name
# $2 - column number
function caption() {
  local name=$1
  local col=$2
  col=$(($col+1))
  
  # Determine caption width.
  local bc=`echo "1/$MAX_COLS" | bc -l`
  local width=`printf "%.1f\n" $bc`
  
  # If first, add begin.
  if [ "$col" == "1" ]; then
    echo "\begin{figure}[!h]" >> $MD
  fi
  
  # Add caption.
  echo "\begin{subfigure}[t]{$width\textwidth}" >> $MD
  echo "\caption{$name}" >> $MD
  echo "\end{subfigure}" >> $MD

  # If last in row then end, else add "\hfill".
  if [ "$col" == "$MAX_COLS" ]; then
    echo "\end{figure}" >> $MD
  else
    echo "\hfill" >> $MD
  fi      
}

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
start=`grep -Tn "Email Address" temp.csv | sed s/:/\/g | awk '{print $1}' | head -n 1`
start=$((start+1))
tail -n +$start $CSV | \
    grep -v "Waitlisted Students" | \
    grep -v "Email Address" | \
    awk -F ',' '{print $3, $2}' | \
    grep -v '^[[:blank:]]*$' | \
    sed s/,/\/g | \
    sed s/\"/\/g | \
    grep -v "Registered" | \
    grep -v "Waitlisted" > $NAMES

# Add markdown header to markdown file.
echo "Preparing markdown file..."
echo "---" >> $MD
echo "header-includes: |" >> $MD
echo "    \usepackage{caption}" >> $MD
echo "    \usepackage{subcaption}" >> $MD
echo "    \captionsetup[subfigure]{labelformat=empty}" >> $MD
echo "---" >> $MD
echo " " >> $MD

# Get class header and write to markdown file.
header=`grep "Course Section" temp.csv | awk -F',' '{print $2}' | tr -d '\n'`
echo "## $header" >> $MD
echo " " >> $MD

# Make white image for padding (as needed for narrow photos).
convert -size 150x150 xc:white white.png

# Loop through each name, adding name and image to markdown file.
echo "Making name + pic for each student: "
i=0
col=1
array=()
while IFS= read -r name; do

  echo -n "."
  
  # Add this name to array of names.
  array+=( "$name" )
  
  # Get next image in sequence.
  image=$IMG-`seq -f "%03g" $i $i`.png
  if [ ! -f "$image" ]; then
    image="(No image)"

  else

    # If width is not 150px then pad with white image.
    width=`file $image | awk '{print $5}'`
    if (( $width < 150 )); then
      offset=$(((150 - $width) / 2))
      convert white.png $image -geometry +$offset+0 -composite temp.png
      mv temp.png $image
    fi

  fi

  # Add to file.
  echo "![$name]($image){ width=300px }" >> $MD

  # If done with row, add captions.
  if [ "$col" == "$MAX_COLS" ]; then

    for  (( j=0; j<$MAX_COLS; j++ )); do
      caption "${array[$j]}" $j
    done

    echo " " >> $MD

    # Get ready for next row.
    col=0
    array=()
  fi
  
  i=$((i+1))
  col=$((col+1))
  
done < "$NAMES"

# Handle any remaining uncaptioned photos.
if [ ! "$col" == "0" ] ; then
  for  (( j=0; j<$col; j++ )); do
    caption "${array[$j]}" $j
  done
  if [ ! "$j" == "$col" ]; then
    echo "\end{figure}" >> $MD
  fi
  echo " "
fi

# Run pandoc to format markdown to PDF.
echo "Running pandoc..."
pandoc --standalone --self-contained -V fontsize=12pt -V geometry:"margin=1in" -o $OUT $MD

echo "OUTPUT: $OUT"

