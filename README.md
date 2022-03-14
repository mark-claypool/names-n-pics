# README

## Names and Pictures

v3.4

These instructions and script are to create a list of students in a
class with a decent-sized photo for each.

It's designed to work with the classlists created by Workday, which
(at WPI) only have a thumbnail version of the student photos, and
these are embedded in a list with all the class information.  The
script extracts each photo to a decent size and includes it with just
a name.  This may be useful for, say, learning the names of students
in a class.

Besides needing Workday to get the classlist (PDF and Excel), the
following tools are required:

- pdfimages (to extract the images from the PDF)
- xlsx2csv (to convert the Excel file to csv)
- csvformat (to convert csv to tsv)
- Latex caption package (for aligning figures, 3 per row)
- Latex subcaption package (for centering names on figures)
- convert (from ImageMagick, for padding figures that are narrow)
- pandoc (for converting markdown to PDF)

Tip: for Linux Ubuntu, the following commands will install everything
needed:

```
sudo apt update
sudo apt install \
  pandoc \
  xlsx2csv \
  latex \
  texlive-latex-recommended \
  Imagemagick \
  poppler-utils \
  csvkit

```

It's been tested on Linux (Ubuntu).

----------------------

## Instructions

1. Get class list from Workday

`Workday -> Teaching -> View Course Section Roster -> (select class)`

----------------------

2. Export class list to PDF

`View printable Version (PDF)` (button labeled "PDF" in upper right corner)

Download this file, save as "roster.pdf".

----------------------

3. Export class list to Excel

(button with a little X to the top right of the roster window)

Download this file, save as "roster.xlsx".

----------------------

4. Extract images, get names, build document

Type: `make`

This should extract the images from `roster.pdf`, extract the names
from `roster.txt`, create a temporary markdown file `names-n-pic.md` and
finally generate the classlist with pictures: 

"**names-n-pic.pdf**"

----------------------

5. (Optional) Clean up.

To remove temporary files made, type:

`make clean`

To remove everything, including final PDF type:

`make very-clean`

----------------------

## Special cases handled

Missing images replaced with anonymous silhouette.

Narrow/wide images resized or padded, as needed, and centered.

Students on the waitlist included, listed after others.

Classlists with "lastname, firstname" as well as "firstname lastname".

----------------------

## To Do

Make options to generate "names-n-pic.html" and "names-n-pic.docx".

----------------------

Enjoy!

-- Mark Claypool  
claypool@cs.wpi.edu
