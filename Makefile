#
# Makefile
#

RM=/bin/rm

all: roster.txt roster.pdf
	cat roster.txt | awk -F '\t' '{print $2}' | grep ',' > names.txt
	pdfimages -png roster.pdf image
	./make-pic-name.sh

clean:
	$(RM) -f *.png
	$(RM) -f pic-name.md 

very-clean: clean
	$(RM) -f pic-name.pdf


