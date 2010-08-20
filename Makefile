VER=0.12.3
PKG_NAME=bootchart2
PKG_TARBALL=$(PKG_NAME)-$(VER).tar.bz2

CC = gcc
CFLAGS = -g -Wall -O0

BINDIR ?= /usr/bin
PY_LIBDIR ?= /usr/lib/python2.6
PY_SITEDIR ?= $(PY_LIBDIR)/site-packages
LIBC_A_PATH = /usr/lib

COLLECTOR = \
	collector/collector.o \
	collector/output.o \
	collector/tasks.o \
	collector/tasks-netlink.o \
	collector/dump.o

all: bootchart-collector

%.o:%.c
	$(CC) $(CFLAGS) -pthread -DVERSION=\"$(VER)\" -c $^ -o $@

bootchart-collector: $(COLLECTOR)
	$(CC) -pthread -Icollector -o $@ $^

py-install-compile:
	install -d $(DESTDIR)$(PY_SITEDIR)/pybootchartgui
	cp pybootchartgui/*.py $(DESTDIR)$(PY_SITEDIR)/pybootchartgui
	install -D -m 755 pybootchartgui.py $(DESTDIR)$(BINDIR)/pybootchartgui
	cd $(DESTDIR)$(PY_SITEDIR)/pybootchartgui ; \
		python $(PY_LIBDIR)/py_compile.py *.py ; \
		PYTHONOPTIMIZE=1 python $(PY_LIBDIR)/py_compile.py *.py

install-chroot:
	install -d $(DESTDIR)/lib/bootchart/tmpfs

install-collector: all install-chroot
	install -m 755 -D bootchartd $(DESTDIR)/sbin/bootchartd
	install -m 644 -D bootchartd.conf $(DESTDIR)/etc/bootchartd.conf
	install -m 755 -D bootchart-collector $(DESTDIR)/lib/bootchart/bootchart-collector

install: all py-install-compile install-collector
	mkdir -p $RPM_BUILD_ROOT/lib/bootchart/mnt

clean:
	-rm -f bootchart-collector bootchart-collector-dynamic collector/*.o

dist:
	COMMIT_HASH=`git show-ref -s -h | head -n 1` ; \
	git archive --prefix=$(PKG_NAME)-$(VER)/ --format=tar $$COMMIT_HASH \
		| bzip2 -f > $(PKG_TARBALL)
