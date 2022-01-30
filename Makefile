#
# Makefile
#

RM=/bin/rm

all: roster.xlsx roster.pdf
	./make-names-n-pics.sh

clean:
	$(RM) -f *.png
	$(RM) -f roster.csv
	$(RM) -f names.txt
	$(RM) -f names-n-pics.md 

very-clean: clean
	$(RM) -f names-n-pics.pdf


