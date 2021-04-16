.PHONY: clean-all clean install uninstall

mkpipe: mkpipe.c
	gcc -Wall -o $@ $<

clean-all: clean
	rm -f mkpipe

clean:
	rm -f *.o *~

install: mkpipe
	install -d $(DESTDIR)/usr/local/bin/
	install mkpipe $(DESTDIR)/usr/local/bin/
	install -d $(DESTDIR)/usr/lib/mkpipe
	install mkpipe.sh $(DESTDIR)/usr/lib/mkpipe/

uninstall:
	rm $(DESTDIR)/usr/local/bin/mkpipe
	rm $(DESTDIR)/usr/lib/mkpipe/mkpipe.sh
