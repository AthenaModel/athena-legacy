#---------------------------------------------------------------------
# TITLE:
#    Makefile -- Athena Makefile
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    This Makefile defines the following targets:
#
#    	all          Builds Athena code and documentation.
#    	docs         Builds Athena documentation
#    	test         Runs Athena unit tests.
#    	clean        Deletes all build products
#       build        Builds code and documentation from scratch,
#                    and runs tests.
#       tag          Tags the current branch or trunk.  Requires
#                    MARS_VERSION=x.y and ATHENA_VERSION=x.y.z.
#       cmbuild      Official build; requires ATHENA_VERSION=x.y.z
#                    on make command line.  Builds code and 
#                    documentation from scratch.
#    	installdocs  Installs documentation in the Athena AFS Page
#
#    For normal development, this Makefile is usually executed as
#    follows:
#
#        make
#
#    Optionally, this is followed by
#
#        make test
#
#    For official builds (whether development or release), this
#    sequence is used:
#
#        make build                          
#
#    Resolve any problems until "make build" runs cleanly. Then,
#
#        make ATHENA_VERSION=x.y.z cmbuild
#
#    NOTE: Before doing the official build, docs/build.html should be
#    updated with the build notes for the current version.
#
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Settings

# Set the root of the directory tree.
TOP_DIR = .

.PHONY: all docs test src build cmbuild tag tar srctar clean

#---------------------------------------------------------------------
# Shared Definitions

include MakeDefs

#---------------------------------------------------------------------
# Target: all
#
# Build code and documentation.

all: src bin docs

#---------------------------------------------------------------------
# Target: src
#
# Build compiled modules.

src: check_env
	@ echo ""
	@ echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@ echo "+          Building Binaries From Source            +"
	@ echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@ echo ""
	cd $(TOP_DIR)/mars ; make src
	cd $(TOP_DIR)/src ; make

#---------------------------------------------------------------------
# Target: bin
#
# Build Athena executable; C/C++ source must be built first.  Note that
# the executable is always built; it really has too many dependencies
# to try to build it only when some dependency has changed, and on top
# of that it's not usually needed or built during day-to-day 
# development.

BASE_KIT = $(TOP_DIR)/tools/basekits/base-tk-thread-linux-ix86
ARCHIVE = $(ATHENA_TCL_HOME)/lib/teapot

# tclapp has a nasty habit of not halting the build on error, and
# the error messages get lost for some reason.  So explicitly delete
# the binary before calling tclapp, so that on error we don't have
# a binary.
bin: check_env src
	@ echo ""
	@ echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@ echo "+              Building Athena Executable           +"
	@ echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@ echo ""
	-rm $(TOP_DIR)/bin/athena
	tclapp $(TOP_DIR)/bin/athena.tcl                    \
		$(TOP_DIR)/lib/*/*                          \
		$(TOP_DIR)/mars/lib/*/*                     \
		-out $(TOP_DIR)/bin/athena                  \
		-prefix $(BASE_KIT)                         \
		-archive $(ARCHIVE)                         \
		-follow                                     \
		-pkgref "comm"                              \
		-pkgref "Img       -require 1.4"            \
	        -pkgref "snit      -require 2.3"            \
	        -pkgref "BWidget   -require 1.9"            \
                -pkgref "Tktable"                           \
		-pkgref "treectrl"                          \
		-pkgref "sqlite3   -require 3.6.23"         \
		-pkgref "tablelist -require 4.12"           \
		-pkgref "tdom"                              \
		-pkgref "textutil::expander"                \
		-pkgref "Plotchart"                         \
		-pkgref "Tkhtml    -require 2.0"

#---------------------------------------------------------------------
# Target: docs
#
# Build development documentation.

docs: check_env
	@ echo ""
	@ echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@ echo "+              Building Documentation               +"
	@ echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@ echo ""

	cd $(TOP_DIR)/mars ; make docs
	cd $(TOP_DIR)/docs ; make

#---------------------------------------------------------------------
# Target: test
#
# Run all unit tests.

test: check_env
	@ echo ""
	@ echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@ echo "+               Running Unit Tests                  +"
	@ echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@ echo ""

	cd $(TOP_DIR)/mars ; make test
	cd $(TOP_DIR)/test ; make

#---------------------------------------------------------------------
# Target: installdocs
#
# Copy documentation to the Athena AFS page.

INSTALLDIRS = \
	$(ATHENA_DOCS) \
	$(ATHENA_DOCS)/docs           \
	$(ATHENA_DOCS)/docs/man1      \
	$(ATHENA_DOCS)/docs/man5      \
	$(ATHENA_DOCS)/docs/mani      \
	$(ATHENA_DOCS)/docs/mann      \
	$(ATHENA_DOCS)/docs/mansim    \
	$(ATHENA_DOCS)/docs/dev       \
	$(ATHENA_DOCS)/mars           \
	$(ATHENA_DOCS)/mars/docs      \
	$(ATHENA_DOCS)/mars/docs/man1 \
	$(ATHENA_DOCS)/mars/docs/man5 \
	$(ATHENA_DOCS)/mars/docs/mani \
	$(ATHENA_DOCS)/mars/docs/mann \
	$(ATHENA_DOCS)/mars/docs/dev

installdocs: $(INSTALLDIRS)
	-cp docs/index.html            $(ATHENA_DOCS)/docs
	-cp docs/developer.html        $(ATHENA_DOCS)/docs
	-cp docs/build_notes.html      $(ATHENA_DOCS)/docs
	-cp docs/dev/*.html            $(ATHENA_DOCS)/docs/dev
	-cp docs/dev/*.doc             $(ATHENA_DOCS)/docs/dev
	-cp docs/dev/*.odt             $(ATHENA_DOCS)/docs/dev
	-cp docs/dev/*.ods             $(ATHENA_DOCS)/docs/dev
	-cp docs/dev/*.pdf             $(ATHENA_DOCS)/docs/dev
	-cp docs/dev/*.txt             $(ATHENA_DOCS)/docs/dev
	-cp docs/man1/*.html           $(ATHENA_DOCS)/docs/man1
	-cp docs/man5/*.html           $(ATHENA_DOCS)/docs/man5
	-cp docs/mani/*.html           $(ATHENA_DOCS)/docs/mani
	-cp docs/mann/*.html           $(ATHENA_DOCS)/docs/mann
	-cp docs/mansim/*.html         $(ATHENA_DOCS)/docs/mansim
	-cp docs/man1/*.gif            $(ATHENA_DOCS)/docs/man1
	-cp docs/man5/*.gif            $(ATHENA_DOCS)/docs/man5
	-cp docs/mani/*.gif            $(ATHENA_DOCS)/docs/mani
	-cp docs/mann/*.gif            $(ATHENA_DOCS)/docs/mann
	-cp docs/mansim/*.gif          $(ATHENA_DOCS)/docs/mansim
	-cp mars/docs/index.html       $(ATHENA_DOCS)/mars/docs
	-cp mars/docs/build_notes.html $(ATHENA_DOCS)/mars/docs
	-cp mars/docs/dev/*.html       $(ATHENA_DOCS)/mars/docs/dev
	-cp mars/docs/dev/*.doc        $(ATHENA_DOCS)/mars/docs/dev
	-cp mars/docs/dev/*.pdf        $(ATHENA_DOCS)/mars/docs/dev
	-cp mars/docs/dev/*.txt        $(ATHENA_DOCS)/mars/docs/dev
	-cp mars/docs/man1/*.html      $(ATHENA_DOCS)/mars/docs/man1
	-cp mars/docs/man5/*.html      $(ATHENA_DOCS)/mars/docs/man5
	-cp mars/docs/mani/*.html      $(ATHENA_DOCS)/mars/docs/mani
	-cp mars/docs/mann/*.html      $(ATHENA_DOCS)/mars/docs/mann
	-cp mars/docs/man1/*.gif       $(ATHENA_DOCS)/mars/docs/man1
	-cp mars/docs/man5/*.gif       $(ATHENA_DOCS)/mars/docs/man5
	-cp mars/docs/mani/*.gif       $(ATHENA_DOCS)/mars/docs/mani
	-cp mars/docs/mann/*.gif       $(ATHENA_DOCS)/mars/docs/mann

$(INSTALLDIRS):
	mkdir -p $@


#---------------------------------------------------------------------
# Target: build
#
# Build code and documentation from scratch, and run tests.

build: clean src bin docs test

#---------------------------------------------------------------------
# Target: cmbuild
#
# Official CM build.  Requires a valid (numeric) ATHENA_VERSION.

cmbuild: check_cmbuild clean srctar src bin docs tar
	@ echo ""
	@ echo "*****************************************************"
	@ echo "         CM Build: Athena $(ATHENA_VERSION) Complete"
	@ echo "*****************************************************"
	@ echo ""

check_cmbuild:
	@ echo ""
	@ echo "*****************************************************"
	@ echo "                CM Build: Athena $(ATHENA_VERSION)"
	@ echo "                CM Build: Mars $(MARS_VERSION)"
	@ echo "*****************************************************"
	@ echo ""

#---------------------------------------------------------------------
# Target: tar

tar:
	@ echo ""
	@ echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@ echo "+               Making ../athena_$(ATHENA_VERSION).tar"
	@ echo "+               Making ../athena_$(ATHENA_VERSION)_docs.tar"
	@ echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@ echo ""

	$(TOP_DIR)/tools/bin/make_tar install $(ATHENA_VERSION)
	$(TOP_DIR)/tools/bin/make_tar docs    $(ATHENA_VERSION)

#---------------------------------------------------------------------
# Target: srctar

srctar:
	@ echo ""
	@ echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@ echo "+               Making ../athena_$(ATHENA_VERSION)_src.tar"
	@ echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@ echo ""

	$(TOP_DIR)/tools/bin/make_tar source $(ATHENA_VERSION)


#---------------------------------------------------------------------
# Target: clean
#
# Delete all build products.

clean: check_env
	@ echo ""
	@ echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@ echo "+                     Cleaning                      +"
	@ echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@ echo ""
	-rm $(TOP_DIR)/bin/athena
	cd $(TOP_DIR)/mars ; make clean
	cd $(TOP_DIR)/src  ; make clean
	cd $(TOP_DIR)/test ; make clean
	cd $(TOP_DIR)/docs ; make clean

#---------------------------------------------------------------------
# Shared Rules

include MakeRules









