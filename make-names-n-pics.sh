#!/bin/bash

#
# Script to generate pdf from images and names, both extracted from
# Workday.
#
# Usage: make-names-n-pic.sh (no arguments)
#
# See: https://github.com/mark-claypool/names-n-pics
#
# Last signficantly modified: March 2022
#

# Required supporting programs:
# + xlsx2csv
# + Latex caption package
# + Latex subcaption package
# + pandoc
# + convert (in package imagemagick)
# + csvformat (in package csvkit)

# Exit codes:
# 0 - all is well
# 1 - warning (maybe input or output odd)
# 2 - error (likely input error)
# 3 - error (system or other)

VERSION=v3.8

# For layout
SIZE=150  # in pixels
MAX_COLS=3

# For file names
MD=names-n-pics.md
OUT=names-n-pics.pdf
IMG=image
PIC=pic
ROSTER=roster
TSV=temp.tsv
NAMES=names.txt
PRONOUNS=pronouns.txt
NONAMES=0 # 0 - generate file 'names.txt', 1 - reuse

#####################################
# usage - print usage message and quit.
function usage() {
  echo "make-names-n-pics.sh ($VERSION) - create classlist with pictures"
  echo "  usage: make-names-n-pics.sh [-ndvh]"
  echo "         -n  do not generate names, but use pre-built '$NAMES'"
  echo "         -d  turn on debug (default off)"
  echo "         -v  print version"
  echo "         -h  this help message"
  exit 3
}

#######################################
# parse command line args.
while getopts "vdhn?" opt; do
  case "${opt}" in
    n)  NONAMES=1
	;;
    v)  echo "Version $VERSION"
	usage
	;;
    d)  set -x
	;;
    h|\?|*)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

if [ ! "$#" == "0" ] ; then
  echo "Error!  No command line arguments needed (or allowed)."
  usage
fi

#####################################
# Check for needed utility programs.
if ! command -v xlsx2csv &> /dev/null ; then
  echo "Error!  Requires 'xlsx2csv'."
  exit 3
fi
if ! command -v convert &> /dev/null ; then
  echo "Error!  Requires 'convert'."
  exit 3
fi
if ! command -v pandoc &> /dev/null ; then
  echo "Error!  Requires 'pandoc'."
  exit 3
fi
if ! command -v csvformat &> /dev/null ; then
  echo "Error!  Requires 'csvformat'."
  exit 3
fi
if ! command -v latex &> /dev/null ; then
  echo "Error!  Requires 'latex'."
  exit 3
fi
if ! command -v pdfimages &> /dev/null ; then
  echo "Error!  Requires 'pdfimages'."
  exit 3
fi
kpsewhich caption.sty >& /dev/null  # kpsewhich should come with latex
if [ ! $? -eq 0 ]; then
  echo "Error!  Requires 'caption.sty'"
  exit 3
fi
kpsewhich subcaption.sty >& /dev/null
if [ ! $? -eq 0 ]; then
  echo "Error!  Requires 'subcaption.sty'."
  exit 3  
fi

#####################################
# is-white - compute colors in a file.  If "white", will only be 1.
# Otherwise, will be something else (-1).
#
# $1 - file name.
# 
# for one color (e.g., white), the command:
#   identify --verbose
#
# will have
# ...
# Histogram:
#     22500: (255,255,255) #FFFFFF gray(255)
# Colormap entries: 256
# ...
# usage: colors=$(count-colors "$file")
function is-white() {
  local file=$1

  first=`identify -verbose "$file" | \
    grep -n "Histogram:" | \
    sed s/:/\/g | \
    awk '{print $1}' | head -n 1`
  first=$((first+1))
  last=`identify -verbose $file | \
    grep -n 'Colormap entries:' | \
    sed s/:/\/g | \
    awk '{print $1}' | \
    head -n 1`
  diff=$((last-first))
  echo "$diff"
}

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

# Check for needed roster xlsx and pdf.
if [ ! -f $ROSTER.xlsx ]; then
  echo "Error! File '$ROSTER.xlsx' does not exist. Should be exported from Workday."
  exit 2
fi
if [ ! -f $ROSTER.pdf ]; then
  echo "Error! File '$ROSTER.pdf' does not exist. Should be exported from Workday."
  exit 2
fi

# Clean up any old files.
echo "Cleaning up old files..."
/bin/rm -f $OUT
/bin/rm -f $MD
/bin/rm -f $TSV
/bin/rm -f $IMG*.png
/bin/rm -f $PIC*.png
if [ "$NONAMES" == "0" ] ; then
  /bin/rm -f $NAMES
  /bin/rm -f $PRONOUNS
fi

# Extract images.
echo "Extracting images..."
pdfimages -png $ROSTER.pdf $IMG
image_count=`ls -1 $IMG*.png | wc -l`

# Error check here since there could have been an incorrect roster.
if [ "$image_count" == "0" ] ; then
  echo "Error!  No images found in $ROSTER.pdf."
  exit 2
fi

# Check for white images (these appear mysteriously in some roster.pdf
# files and do not correspond to any students).  
for (( i=0; i<$image_count; i++ )); do
  img=$IMG-`seq -f "%03g" $i $i`.png
  white=$(is-white "$img")

  # If found, remove and "scoot" remaining.
  if [ $white == "1" ] ; then
    echo "Found 'white' image ($img).  Scooting over..."
    next=$((i+1))
    for (( j=$next; j<$image_count; j++ )); do
      prev=$((j-1))
      img1=$IMG-`seq -f "%03g" $prev $prev`.png
      img2=$IMG-`seq -f "%03g" $j $j`.png
      mv $img2 $img1
    done
    image_count=$((image_count-1))
  fi
done

# Convert xlsx to tab-separated tsv.
echo "Converting xlsx to tab-separated tsv..."
xlsx2csv -e $ROSTER.xlsx | csvformat -T > $TSV

# Extract names.
if [ "$NONAMES" == "0" ] ; then

  echo "Extracting names..."

  start=`grep -Tn "Email" $TSV | sed s/:/\/g | awk '{print $1}' | head -n 1`

  # There seem to be two types of formats:
  # A) Photo, Student, Pronoun...
  # B) Reg, Student, Photo...
  echo "Examining header to determine column format..."
  col1=`sed -n "$start"p $TSV | awk -F '\t' '{print $1}'`
  if [ "$col1" == "Photo" ] ; then
    format="ALTERNATE"
  else
    format="standard"
  fi
  echo "Format: $format"
  start=$((start+1))

  if [ "$format" == "standard" ] ; then
    # Standard format.
    tail -n +$start $TSV | \
      grep '@' | \
      grep -v '^[[:blank:]]*$' | \
      awk -F '\t' '{print $3}' | \
      sed s/\"/\/g | \
      awk -F',' '{print $2, $1}' | \
      grep -v "Registered" | \
      grep -v "Waitlisted" > $NAMES
  else
    # Alternate format.
    tail -n +$start $TSV | \
      grep '@' | \
      grep 'jpg\|jpeg' | \
      awk -F '\t' '{print $3}' | \
      grep -v '^[[:blank:]]*$' > $NAMES
    
    # pronouns
    tail -n +$start $TSV | \
      grep '@' | \
      awk -F '\t' '{print $4}' > $PRONOUNS

  fi
  
else  

  echo "Using pre-built $NAMES..."
  if [ ! -f $NAMES ] ; then
    echo "Error!  '$NAMES' not found"
    exit 2
  fi

fi
name_count=`wc -l $NAMES | awk '{print $1}'`
echo -n "--> total names: "
echo $name_count

# Enumerate extracted images --> pics.
echo "Enumerating pics from images..."
missing_count=0
for (( i=1; i<=$name_count; i++ )); do

  if [ "$format" == "standard" ] ; then
    has_photo=`grep -i '@wpi.edu' $TSV | cat -n | awk "NR==$i" | grep 'Photo' | wc -l`
  else
    has_photo=`grep -i '@wpi.edu' $TSV | cat -n | awk "NR==$i" | awk -F'\t' '{print $2}' | grep 'jpg\|jpeg' | wc -l`
  fi

  # Use a silhouette as the pic for each missing image.
  if [ "$has_photo" == "0" ]; then
    echo "Missing photo for name $i.  Using anonymous..."
    missing_count=$((missing_count+1))
    image="anonymous-png"
    idx=$(($i-1))
    pic=$PIC-`seq -f "%03g" $idx $idx`.png
  fi

  # Otherwise, copy extracted image as the pic.
  if [ "$has_photo" == "1" ]; then
    old_idx=$(($i-$missing_count-1))
    image=$IMG-`seq -f "%03g" $old_idx $old_idx`.png      
    idx=$(($i-1))
    pic=$PIC-`seq -f "%03g" $idx $idx`.png
  fi

  cp $image $pic

done

# Compare final image count to name count.  They should be the same.
final_image_count=`ls -1 $PIC*.png | wc -l`
echo -n "--> total images: "
echo $final_image_count
if [ ! "$final_image_count" == "$name_count" ] ; then
  echo "WARNING! # names ($name_count) != # images ($image_count)"
  exit 1
fi

# Add markdown header to markdown file.
echo "Preparing markdown file..."
/bin/rm -f $MD &> /dev/null
echo "---" >> $MD
echo "header-includes: |" >> $MD
echo "    \usepackage{caption}" >> $MD
echo "    \usepackage{subcaption}" >> $MD
echo "    \captionsetup[subfigure]{labelformat=empty}" >> $MD
echo "---" >> $MD
echo " " >> $MD

# Get class header and write to markdown file.

if [ "$format" == "standard" ] ; then
  # Standard format header.
  header=`grep "WPI.EDU" $TSV | awk -F '\t' '{print $1}' | head -n 1 | tr -d '\n' | awk -F' - ' '{print $(NF-1), "-", $(NF)}'`
  if [ "$header" == "" ] ; then
    echo "  Header not found. Trying alternate...."
    header=`grep "Course Section" $TSV | awk -F '\t' '{print $2}' | tr -d '\n'`
  fi
else
  # Alternate format header.
  header=`grep -i '@wpi.edu' $TSV | awk -F'\t' '{print $18}' | head -n 1 | tr -d '\n'`
fi
if [ "$header" == "" ] ; then
  echo "  No classlist suitable header found."
  header="Names and Pictures"
fi
echo "  Header: '$header'"
echo "## $header" >> $MD
echo " " >> $MD

# Make white image for padding (as needed for narrow photos).
convert -size "$SIZE"x"$SIZE" xc:white white.png

# Loop through each name, adding name and image to markdown file.
echo "Making name + pic for each student: "
i=0
col=1
MISSING=0
array=()
while IFS= read -r name; do

  echo -n "."
  
  # Add this name to array of names.
  array+=( "$name" )
  
  # Get next image in sequence.
  pic=$PIC-`seq -f "%03g" $i $i`.png
  if [ ! -f "$pic" ]; then
    pic="(No pic)"
    MISSING=$((MISSING+1))
  else

    # If width is not 150px then pad with white image.
    width=`file $pic | awk '{print $5}'`
    if (( $width < $SIZE )); then
      offset=$((($SIZE - $width) / 2))
      convert white.png $pic -geometry +$offset+0 -composite temp.png
      mv temp.png $pic
    fi

  fi

  # Add to file.
  echo "![$name]($pic){ width=200px }" >> $MD

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
echo " "

# Handle any remaining uncaptioned photos/empty spaces.
if [ ! "$col" == "1" ] ; then
  for  (( j=0; j<$col; j++ )); do
    caption "${array[$j]}" $j
  done
  for  (( i=j; i<$MAX_COLS; i++ )); do
    caption "" $i
  done
  echo " "
fi

# Run pandoc to format markdown to PDF.
echo "Running pandoc..."
pandoc --standalone --self-contained -V fontsize=12pt -V geometry:"margin=1in" -o $OUT $MD
if [ ! $? -eq 0 ]; then
  echo "WARNING! pandoc error."
  exit 2
fi

echo "OUTPUT: $OUT"

# Exit with proper warning code for any calling scripts.
if [ "$MISSING" -gt 0 ] ; then
  echo "WARNING!  Missing $MISSING image(s).  Names may be off."
  exit 1    
fi
if [ "$missing_count" -gt 4 ] ; then
  echo "WARNING!  $missing_count anonymous images.  May be file upload error."
  exit 1    
fi

exit 0
