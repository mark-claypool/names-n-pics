#
# Makefile
#

RM=/bin/rm

all: roster.txt roster.pdf
	cat roster.txt | awk -F '\t' '{print $2}' | grep ',' > names.txt
	pdfimages -png roster.pdf image
	./make-name-pic.sh

clean:
	$(RM) -f *.png
	$(RM) -f names.txt
	$(RM) -f name-pic.md 

very-clean: clean
	$(RM) -f name-pic.pdf


