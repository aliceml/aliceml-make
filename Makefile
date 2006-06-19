#
# Global Makefile for building Alice and Seam under Windows/Linux
# 2004-2005 Andreas Rossberg
#
# Usage:
# - 'make setup' to checkout everything from CVS and create an appropriate
#   directory structure.
# - 'make update' to update from CVS.
# - 'make all' to build Alice for the actual OS
# - 'make clean' to remove everything built.
# - 'make cleanbuild' to build from scratch.
# After setup you must include seam-support in your path to be able to build:
#   PATH=$(PREFIX)/seam-support/install/bin:$PATH
# (See $PREFIX below.)
#
# Make sure, you have set the SMLNJ_HOME variable, before build starts.
#
# The system consists of several parts:
# - seam: the virtual machine framework (uses autoconf)
# - gecode: the constraint library (uses autoconf)
# - alice-ll: the Alice language layer for Seam (uses autoconf)
# - alice-bootstrap: Alice compiler and libraries
# All parts can be built or cleaned individually, using 'make build-XXX' and
# 'make clean-XXX' targets. The build targets ought to be fool-safe, but can
# take a while, as they reconfigure everything. There are also
# 'make rebuild-XXX' targets, which avoid some of the work and are useful after
# local changes.
#
# After a build is complete, you can use Alice by setting $PATH and $ALICE_HOME
# properly:
#   PATH=<dir>/distro/bin:<dir>/distro/lib/seam:$PATH
#   ALICE_HOME=<dir>/distro/share/alice
#
#### WINDOWS #####
#
# Note: Building under Windows is a PITA: it is horribly slow and very fragile.
#
# You need to have SMLNJ Version >110.55 - Cygwin-Installation
# on your system and the SMLNJ-bin dir in your PATH variable.
#
# You also need:
#	autoconf  v. 2.57, 
#	automake  v. 1.7.6
#	gmp       v. 4.1.3
#	lightning v. 1.2
#	libtool   v. 1.5.20
#
# To build the documentation - without having PHP installed -
# the generated HTML pages must be prepared in the
# $DOC directory specified below. The actual generation is not done in this
# Makefile, since it requires PHP. Invoking 'make docs' builds a compiled
# help file (.chm) from it (Windows).
#
# To prepare the distribution, you must have a build and the documentation.
# Invoking 'make distro' will build special Windows .exe wrappers 
# (to be able to use Alice without Cygwin) 
# and copy everything to the InstallShield directory.
#
#########
#
# Troubleshooting:
# - Gecode is not available in a CVS Version, download the package at 
#   http://www.gecode.org and unpack it in PWD/gecode/sources
#   disable the respective calls in 'make setup'
# - Check $PATH and $ALICE_HOME. In particular, $ALICE_HOME must use proper
#   Windows syntax, not Cygwin (e.g. for drives)!
# - After having performed 'make distro' it is no longer possible to invoke
#   Alice from a Cygwin shell or do a 'make build-alice-bootstrap', because
#   the shell scripts have been replaced by .exe files. 
#   Invoke 'make unbuild-win-exec' to enable it again.
# - Sometimes something just keeps failing for incomprehensible reasons. 
#   In that case it's best to do a 'make cleanbuild'.
# - If your system becomes notably slower you might have some orphaned Alice
#   processes hanging around (e.g. because some Ctrl-C might have failed to 
#   kill subprocesses properly, which is a frequent problem on Windows/Cygwin).
#   Kill them.
#

# Configure this properly

CVSROOT = :pserver:anoncvs:anoncvs@ps.uni-sb.de:/services/alice/CVS
DOC = /cygdrive/z/root/home/ps/httpd/html/alice/manual-devel

GECODE_VERSION=1.2
VERSION=1.3

# From here on no change should be needed

PWD := $(shell (cd ..; pwd))
PREFIX = $(PWD)/distro

UNAME := $(shell if [ -x /bin/uname ]; then echo "/bin/uname"; \
		 elif [ -x /usr/bin/uname ]; then echo "/usr/bin/uname"; \
		 else echo "uname"; \
		 fi)

# make it lowercase for easier comparing
SYSTEM := $(shell echo "`$(UNAME) -m` `$(UNAME) -s` `$(UNAME) -r`" | tr [A-Z] [a-z])

# source packages
GECODE_ARCHIVE_NAME=gecode-$(GECODE_VERSION)
SEAM_ARCHIVE_NAME=seam-$(VERSION)
ALICE_LL_ARCHIVE_NAME=alice-$(VERSION)
ALICE_GTK_ARCHIVE_NAME=alice-gtk-$(VERSION)
ALICE_GECODE_ARCHIVE_NAME=alice-gecode-$(VERSION)
ALICE_REGEX_ARCHIVE_NAME=alice-regex-$(VERSION)
ALICE_SQLITE_ARCHIVE_NAME=alice-sqlite-$(VERSION)
ALICE_XML_ARCHIVE_NAME=alice-xml-$(VERSION)
ALICE_RUNTIME_ARCHIVE_NAME=alice-runtime-$(VERSION)

# download paths
GECODE_URL = http://www.gecode.org/download/$(GECODE_ARCHIVE_NAME).tar.gz
ALICE_MAIN_URL=http://www.ps.uni-sb.de/alice/download/sources
SEAM_URL=$(ALICE_MAIN_URL)/$(SEAM_ARCHIVE_NAME).tar.gz
ALICE_LL_URL=$(ALICE_MAIN_URL)/$(ALICE_LL_ARCHIVE_NAME).tar.gz
ALICE_GTK_URL=$(ALICE_MAIN_URL)/$(ALICE_GTK_ARCHIVE_NAME).tar.gz
ALICE_GECODE_URL=$(ALICE_MAIN_URL)/$(ALICE_GECODE_ARCHIVE_NAME).tar.gz
ALICE_REGEX_URL=$(ALICE_MAIN_URL)/$(ALICE_REGEX_ARCHIVE_NAME).tar.gz
ALICE_SQLITE_URL=$(ALICE_MAIN_URL)/$(ALICE_SQLITE_ARCHIVE_NAME).tar.gz
ALICE_XML_URL=$(ALICE_MAIN_URL)/$(ALICE_XML_ARCHIVE_NAME).tar.gz
ALICE_RUNTIME_URL=$(ALICE_MAIN_URL)/$(ALICE_RUNTIME_ARCHIVE_NAME).tar.gz

# can stand here, because PWD/WinGtk2 is not build under non-windows systems
WIN_GTK_DIR := $(PWD)/WinGtk2
PKG_CONFIG_PATH := $(PWD)/seam-support/install/lib/pkgconfig:$(PWD)/gecode/install/lib/pkgconfig:$(WIN_GTK_DIR)/lib/pkgconfig:$(PKG_CONFIG_PATH)
PC_OPTS := "gtk+-2.0 glib-2.0 libgnomecanvas-2.0 --define-variable=prefix=$(WIN_GTK_DIR)"
PATH := $(WIN_GTK_DIR)/bin:$(WIN_GTK_DIR)/lib:$(PATH)
export PKG_CONFIG_PATH
export PC_OPTS
export PATH

########### Global ############

.PHONY:	info
info:
	@echo To build distro, \`make clean all\'.
	@echo To test, \`make rungui\'.
	@echo Optionally, \`make update\' first.
	@echo For initial checkout, \`make setup\'.
	@echo For releasing, \`make setup-release\' and \`make release\'.

.PHONY:	setup setup-wingtk setup-release
setup:
	cvs -d $(CVSROOT) login
	(cd $(PWD) && cvs -d $(CVSROOT) get seam-support)
	make build-seam-support
	mkdir -p $(PWD)/seam
	mkdir -p $(PWD)/seam/build
	(cd $(PWD)/seam && cvs -d $(CVSROOT) get seam && mv seam sources)
	mkdir -p $(PWD)/gecode
	mkdir -p $(PWD)/gecode/build
	(cd $(PWD)/gecode; wget $(GECODE_URL) -O - | tar xz; mv $(GECODE_ARCHIVE_NAME) sources)
	mkdir -p $(PWD)/alice
	mkdir -p $(PWD)/alice/build
	(cd $(PWD)/alice && cvs -d $(CVSROOT) get alice && mv alice sources)
	@echo Setup complete.
	@echo Include $(PWD)/seam-support/install/bin into your PATH.

setup-wingtk:
	cp $(PWD)/seam-support/windows/WinGtk2.tgz $(PWD)
	(cd $(PWD) && tar xvfz WinGtk2.tgz)
	(cd $(PWD)/WinGtk2 && ./patch.sh)
	rm $(PWD)/WinGtk2.tgz

setup-release:
	cvs -d $(CVSROOT) login
	(cd $(PWD) && cvs -d $(CVSROOT) get seam-support)
	make build-seam-support
	mkdir -p $(PWD)/seam
	mkdir -p $(PWD)/seam/build
	rm -rf $(PWD)/seam/sources
	(cd $(PWD)/seam && wget $(SEAM_URL) -O - | tar xz; mv $(SEAM_ARCHIVE_NAME) sources)
	mkdir -p $(PWD)/gecode
	mkdir -p $(PWD)/gecode/build
	rm -rf $(PWD)/gecode/sources
	(cd $(PWD)/gecode; wget $(GECODE_URL) -O - | tar xz; mv $(GECODE_ARCHIVE_NAME) sources)
	mkdir -p $(PWD)/alice/build
	mkdir -p $(PWD)/alice/sources
	rm -rf $(PWD)/alice/sources/vm-seam
	(cd $(PWD)/alice/sources && wget $(ALICE_LL_URL) -O - | tar xz; mv $(ALICE_LL_ARCHIVE_NAME) vm-seam)
	rm -rf $(PWD)/alice-gtk
	(cd $(PWD) && wget $(ALICE_GTK_URL) -O - | tar xz; mv $(ALICE_GTK_ARCHIVE_NAME) alice-gtk)
	rm -rf $(PWD)/alice-gecode
	(cd $(PWD) && wget $(ALICE_GECODE_URL) -O - | tar xz; mv $(ALICE_GECODE_ARCHIVE_NAME) alice-gecode)
	rm -rf $(PWD)/alice-regex
	(cd $(PWD) && wget $(ALICE_REGEX_URL) -O - | tar xz; mv $(ALICE_REGEX_ARCHIVE_NAME) alice-regex)
	rm -rf $(PWD)/alice-sqlite
	(cd $(PWD) && wget $(ALICE_SQLITE_URL) -O - | tar xz; mv $(ALICE_SQLITE_ARCHIVE_NAME) alice-sqlite)
	rm -rf $(PWD)/alice-xml
	(cd $(PWD) && wget $(ALICE_XML_URL) -O - | tar xz; mv $(ALICE_XML_ARCHIVE_NAME) alice-xml)
	rm -rf $(PWD)/alice-runtime
	(cd $(PWD) && wget $(ALICE_RUNTIME_URL) -O - | tar xz; mv $(ALICE_RUNTIME_ARCHIVE_NAME) alice-runtime)

	@echo Setup complete.
	@echo Include $(PWD)/seam-support/install/bin into your PATH.

.PHONY:	update
update:
	(cd $(PWD)/seam-support && cvs -q -d $(CVSROOT) update -dP) && \
	(cd $(PWD)/gecode/sources && cvs -q -d $(GECODECVSROOT) update -dP) && \
	(cd $(PWD)/seam/sources && cvs -q -d $(CVSROOT) update -dP) && \
	(cd $(PWD)/alice/sources && cvs -q -d $(CVSROOT) update -dP)

.PHONY:	clean
clean: clean-distro clean-gecode clean-seam clean-alice-ll clean-alice-bootstrap

.PHONY:	cleanbuild
cleanbuild: clean all

.PHONY:	build-windows build-linux build-freebsd build-ppc-darwin
build-windows: build-gecode-windows build-seam-windows build-alice-ll-windows build-alice-bootstrap build-suffix

build-linux: build-gecode-linux build-seam-linux build-alice-ll-linux build-alice-bootstrap build-suffix 

build-freebsd:
	@echo TODO

build-ppc-darwin:
	@echo TODO

build-suffix:
	@echo Build complete.
	@echo Try running $(PREFIX)/bin/alice.
	@echo You probably have to set:
	@echo PATH=$(PREFIX)/bin:PATH
	@echo ALICE_HOME=$(PREFIX)/share/alice
	@echo for Windows: PATH=$(WIN_GTK_DIR)/bin:$(WIN_GTK_DIR)/lib:PATH

.PHONY: release-windows release-linux release-freebsd release-ppc-darwin
release-windows: setup-wingtk build-gecode-windows build-seam-windows build-alice-ll-windows build-alice-bootstrap-release build-suffix

release-linux: build-gecode-linux build-seam-linux build-alice-ll-linux build-alice-bootstrap-release build-suffix

release-freebsd:    build-freebsd
release-ppc-darwin: build-ppc-darwin

.PHONY: all windows linux freebsd ppc-darwin
windows:    setup-wingtk build-windows
linux:	    build-linux
freebsd:    build-freebsd
ppc-darwin: build-ppc-darwin

# remember: values in SYSTEM are lowercase (see setting SYSTEM)
all:
	@case " $(SYSTEM) " in \
	   *i[3456]86*linux*) \
		echo "building for Linux" ; \
		make linux ; \
	   	;; \
	   *i[3456]86*freebsd*) \
		echo "building for FreeBSD" ; \
	        make freebsd ; \
	   	;; \
	   *i[3456]86*cygwin*) \
		echo "building for Win32/Cygwin" ; \
		make windows ; \
	   	;; \
	   *power*mac*darwin*) \
		echo "building for Power Mac Darwin" ; \
	        make ppc-darwin ; \
	   	;; \
	   *) \
		echo "Non-supported OS: $(SYSTEM)"; \
		exit 1 \
	   	;; \
	esac

release:
	@case " $(SYSTEM) " in \
	   *i[3456]86*linux*) \
		echo "building for Linux" ; \
		make release-linux ; \
	   	;; \
	   *i[3456]86*freebsd*) \
		echo "building for FreeBSD" ; \
	        make release-freebsd ; \
	   	;; \
	   *i[3456]86*cygwin*) \
		echo "building for Win32/Cygwin" ; \
		make release-windows ; \
	   	;; \
	   *power*mac*darwin*) \
		echo "building for Power Mac Darwin" ; \
	        make release-ppc-darwin ; \
	   	;; \
	   *) \
		echo "Non-supported OS: $(SYSTEM)"; \
		exit 1 \
	   	;; \
	esac

########### Support ############

.PHONY:	build-seam-support
build-seam-support:
	(cd $(PWD)/seam-support && ./build.sh)

########### Gecode ############

.PHONY:	clean-gecode
clean-gecode:
	(cd $(PWD)/gecode/build && rm -rf *)

.PHONY:	configure-gecode-windows
configure-gecode-windows:
	(cd $(PWD)/gecode/build && \
	 ../sources/configure \
		CXX='g++ -mno-cygwin' \
		CC='gcc -mno-cygwin' \
		--enable-static --disable-shared \
		--disable-examples --disable-search --disable-minimodel \
		--prefix='$(PWD)/gecode/install')

.PHONY:	configure-gecode-linux
configure-gecode-linux:
	(cd $(PWD)/gecode/build && \
	 ../sources/configure \
		--enable-static \
		--disable-examples --disable-search --disable-minimodel \
		--prefix='$(PWD)/gecode/install')

.PHONY:	rebuild-gecode
rebuild-gecode:
	(cd $(PWD)/gecode/build && make install)

.PHONY:	build-gecode-windows build-gecode-linux
build-gecode-windows: configure-gecode-windows rebuild-gecode
build-gecode-linux: configure-gecode-linux rebuild-gecode

########### Seam ############

.PHONY:	clean-seam
clean-seam:
	(cd $(PWD)/seam/build && rm -rf *)

.PHONY: setup-seam
setup-seam:
	(cd $(PWD)/seam/sources && make -f Makefile.cvs)

.PHONY:	configure-seam-windows
configure-seam-windows:
	(cd $(PWD)/seam/build && \
	 ../sources/configure \
		CXX='g++ -mno-cygwin -DS_IXOTH=S_IXUSR -DS_IXGRP=S_IXUSR' \
		CC='gcc -mno-cygwin -DS_IXOTH=S_IXUSR -DS_IXGRP=S_IXUSR' \
		--prefix='$(PREFIX)' \
		--with-warnings=yes \
		--with-zlib='$(PWD)/seam-support/install')

.PHONY:	configure-seam-linux
configure-seam-linux:
	(cd $(PWD)/seam/build && \
	 ../sources/configure \
		--prefix='$(PREFIX)' \
		--with-warnings=yes \
		--with-zlib='$(PWD)/seam-support/install')

.PHONY:	rebuild-seam
rebuild-seam:
	(cd $(PWD)/seam/build && make install)

.PHONY:	build-seam-windows build-seam-linux
build-seam-windows: setup-seam configure-seam-windows rebuild-seam
build-seam-linux: setup-seam configure-seam-linux rebuild-seam

########### Alice Language Layer ############

.PHONY:	clean-alice-ll
clean-alice-ll:
	(cd $(PWD)/alice/build && rm -rf *)

.PHONY: setup-alice-ll
setup-alice-ll:
	(cd $(PWD)/alice/sources/vm-seam && make -f Makefile.cvs)

.PHONY:	configure-alice-ll-windows
configure-alice-ll-windows:
	PATH="$(PREFIX)/bin:$(PATH)" && \
	(cd $(PWD)/alice/build && \
	 ../sources/vm-seam/configure \
		--prefix='$(PREFIX)' \
		--with-warnings=yes \
		--with-gmp='$(PWD)/seam-support/install')

.PHONY:	configure-alice-ll-linux
configure-alice-ll-linux:
	PATH="$(PREFIX)/bin:$(PATH)" && \
	(cd $(PWD)/alice/build && \
	 ../sources/vm-seam/configure \
		--prefix='$(PREFIX)' \
		--with-warnings=yes)

.PHONY:	rebuild-alice-ll
rebuild-alice-ll:
	PATH="$(PREFIX)/bin:$(PATH)" && \
	(cd $(PWD)/alice/build && make install)

.PHONY:	build-alice-ll-windows build-alice-ll-linux
build-alice-ll-windows: setup-alice-ll configure-alice-ll-windows rebuild-alice-ll
build-alice-ll-linux: setup-alice-ll configure-alice-ll-linux rebuild-alice-ll

########### Alice Compiler & Library ############

.PHONY:	clean-alice-bootstrap
clean-alice-bootstrap:
	(cd $(PWD)/alice/sources && make distclean)

.PHONY: setup-alice-bootstrap
setup-alice-bootstrap:
	(cp $(PWD)/alice/build/Makefile.bootstrap $(PWD)/alice/sources/vm-seam) && \
	PATH="$(PREFIX)/bin:$(PATH)" && \
	(cd $(PWD)/alice/sources && \
	 make PREFIX="$(PREFIX)" \
	      TARGET=seam \
	      bootstrap-smlnj)

.PHONY:	rebuild-alice-bootstrap
rebuild-alice-bootstrap:
	PATH="$(PREFIX)/bin:$(PATH)" && \
	(cd $(PWD)/alice/sources && \
	 make PREFIX="$(PREFIX)" \
	      TARGET=seam \
	      reinstall-seam)

.PHONY:	build-alice-bootstrap
build-alice-bootstrap: setup-alice-bootstrap rebuild-alice-bootstrap

########### Alice Compiler & Library from precompiled packages ###########

.PHONY: build-alice-bootstrap-release

ALICE_LIBS=gtk gecode regex sqlite xml

build-release-runtime:
	PATH="$(PREFIX)/bin:$(PATH)" && \
	cd $(PWD)/alice-runtime && \
	./configure --prefix=$(PREFIX) && \
	make install	

build-release-libs:
	PATH="$(PREFIX)/bin:$(PATH)" && \
	for p in $(ALICE_LIBS); do \
	  (cd $(PWD)/alice-$$p/ && \
	   make compiledll installdll \
	   INSTALLDIR=$(PREFIX)/share/alice/lib/$$p);\
	done

build-alice-bootstrap-release: build-release-runtime build-release-libs

########### Documentation ############

.PHONY: docs
docs:
	rm -rf $(PWD)/docs && \
	cp -r $(DOC) $(PWD)/docs && \
	cp $(PWD)/alice/sources/doc/manual/Alice.hh? $(PWD)/docs && \
	(cd $(PWD)/docs && /c/Programme/HTML\ Help\ Workshop/hhc Alice || true) && \
	echo Docs built.

.PHONY:	docs-offline
docs-offline:
	cp $(PWD)/alice/sources/doc/manual/Alice.hh? $(PWD)/docs && \
	(cd $(PWD)/docs && /c/Programme/HTML\ Help\ Workshop/hhc Alice || true)

########### Windows Binaries ############

.PHONY:	build-win-exec
build-win-exec:
	PATH="$(PREFIX)/bin:$(PATH)" && \
	(cd $(PWD)/alice/sources/vm-seam/bin/windows && make all PREFIX=$(PREFIX) install)

.PHONY:	unbuild-win-exec
unbuild-win-exec:
	rm -f $(PREFIX)/bin/alice*.exe &&
	make rebuild-alice-ll

########### Distribution ############

.PHONY:	clean-distro
clean-distro:
	rm -rf $(PWD)/distro

.PHONY:	build-xml-dll
build-xml-dll:
	cp $(PWD)/seam-support/install/bin/cygxml2-2.dll $(PWD)/distro/bin

.PHONY: distro
distro: build-win-exec build-xml-dll
	(rm -rf $(PWD)/../InstallShield/Files/Alice) && \
	(cp -r $(PWD)/distro $(PWD)/../InstallShield/Files/Alice) && \
	(mkdir -p $(PWD)/../InstallShield/Files/Alice/doc) && \
	(cp $(PWD)/docs/Alice.chm $(PWD)/../InstallShield/Files/Alice/doc/) && \
	echo Distro prepared. Run InstallShield/Scripts/Alice/Alice.ism.

########### Test Run ############

.PHONY:	run
run:
	@export ALICE_HOME && \
	ALICE_HOME=`cygpath -m "$(PREFIX)/share/alice"` && \
	PATH="$(PREFIX)/bin:$(PREFIX)/lib/seam:/c/Programme/GTK2-Runtime/bin:/c/Programme/GTK2-Runtime/lib:/c/Programme/GTK2-Runtime/lib/gtk-2.0/2.4.0/engines:$(PATH)" && \
	alice

.PHONY:	rungui
rungui:
	@export ALICE_HOME && \
	ALICE_HOME=`cygpath -m "$(PREFIX)/share/alice"` && \
	PATH="$(PREFIX)/bin:$(PREFIX)/lib/seam:/c/Programme/GTK2-Runtime/bin:/c/Programme/GTK2-Runtime/lib:/c/Programme/GTK2-Runtime/lib/gtk-2.0/2.4.0/engines:$(PATH)" && \
	alicewin

selectgui:
	PATH="/c/Programme/GTK2-Runtime/bin:/c/Programme/GTK2-Runtime/lib:$(PATH)" && \
	gtk2_prefs
