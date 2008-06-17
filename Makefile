GZIP=gzip
MAN1PAGES=emms-print-metadata.1
DOCDIR=doc/
LISPDIR=lisp

ALLSOURCE=$(wildcard $(LISPDIR)/*.el)
ALLCOMPILED=$(wildcard $(LISPDIR)/*.elc)

DESTDIR=
PREFIX=$(DESTDIR)/usr/local
INFODIR=$(PREFIX)/info
MAN1DIR=$(PREFIX)/share/man/man1
SITELISP=$(PREFIX)/share/emacs/site-lisp/emms

INSTALLINFO = /usr/sbin/install-info --info-dir=$(INFODIR)

.PHONY: all install lisp docs deb-install clean
.PRECIOUS: %.elc
all: lisp docs

lisp:
	$(MAKE) -C $(LISPDIR)

docs:
	$(MAKE) -C $(DOCDIR)

emms-print-metadata: emms-print-metadata.c
	$(CC) -o $@ $< -I/usr/include/taglib -L/usr/lib -ltag_c

install:
	test -d $(SITELISP) || mkdir -p $(SITELISP)
	[ -d $(INFODIR) ] || install -d $(INFODIR)
	install -m 644 $(ALLSOURCE) $(SITELISP)
	install -m 644 $(ALLCOMPILED) $(SITELISP)
	install -m 0644 $(DOCDIR)emms.info $(INFODIR)/emms
	for p in $(MAN1PAGES) ; do $(GZIP) -9c $$p > $(MAN1DIR)/$$p.gz ; done
	$(INSTALLINFO) emms.info

remove-info:
	$(INSTALLINFO) --remove emms.info

deb-install:
	install -m 644 $(ALLSOURCE) $(SITELISP)

ChangeLog:
	darcs changes > $@

clean:
	-rm -f *~ $(DOCDIR)emms.info $(DOCDIR)emms.html emms-print-metadata
	$(MAKE) -C $(LISPDIR) clean
