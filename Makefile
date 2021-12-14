.PHONY: clean-all clean install uninstall

PREFIX ?= /usr/local
D := $(DESTDIR)/$(PREFIX)

mkpipe: mkpipe.c
	gcc -Wall -Wno-main -o $@ $<

clean-all: clean
	rm -f mkpipe

clean:
	rm -f *.o *~

install: mkpipe
	install -d $(D)/bin/
	install mkpipe $(D)/bin/
	install -d $(D)/lib/mkpipe
	install mkpipe.sh $(D)/lib/mkpipe/
	sed -i -Ee "s/^MKPIPE_BIN=.+$$/MKPIPE_BIN=$(subst /,\/,$(PREFIX))\/bin\/mkpipe/" $(D)/lib/mkpipe/mkpipe.sh

uninstall:
	rm $(D)/bin/mkpipe
	rm $(D)/lib/mkpipe/mkpipe.sh
	rmdir --ignore-fail-on-non-empty $(D)/lib/mkpipe
