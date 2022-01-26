# README

v1.0

These instructions and script are to create a list of students in a
class with a decent-sized photo for each.

It's designed to work with the classlists created by Workday, which
only have a thumbnail version of the photo embedded in a list of class
information.  The script extracts the photo to a decent size and
include it with a names.  This may be useful for, say, learning the
names of students in a class.

Doing this requires the tools:

- Workday (to get the classlist, PDF and Excel)
- Excel (to convert the class list to text for names)
- pdfimages (to extract the images from the PDF)
- bash (to run the script)

It's been tested on Linux (Ubuntu).


## Instructions

1. Get class list

> Workday -> Teaching -> View Course Section Roster -> (select class)



2. Export to PDF

View printable Version (PDF) (button labeled "PDF" in upper right
corner)

Save this file as "roster.pdf"


3. Export to Excel (requires Excel)

(button with a little X to the top right of the roster window)

"Save as" a tab-delimited file named "roster.txt"


4. Extract images, get names, build document

Note, requires `pdfimages` (On Linux: apt install poppler-utils`)
and `pandoc` (On Linux: `apt install pandoc`).

Type:

`make`

This should extract the images from `roster.pdf`, extract the names
from `roster.txt`, create a temporary markdown file `pic-name.md`
and finally generate the classlist with pictures as:

`pic-name.pdf`


7. (Optional) Clean up.

To remove temporary files made, type:

`make clean`

To remove everything, including final PDF type:

`make very-clean`


## To Do

Cleaner ouput, maybe one with "flash cards" to help learn name.

Single script that does it all (after initial saves).

Make options to generate "pic-name.html" and "pic-name.docx".

------------

Enjoy!

-- Mark Claypool  
claypool@cs.wpi.edu

