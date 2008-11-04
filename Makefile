#---------------------------------------------------------------------
# TITLE:
#    Makefile -- Minerva Makefile
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    This Makefile defines the following targets:
#
#    	all          Builds Minerva code and documentation.
#    	docs         Builds Minerva documentation
#    	test         Runs Minerva unit tests.
#    	clean        Deletes all build products
#       build        Builds code and documentation from scratch,
#                    and runs tests.
#       tag          Tags the current branch or trunk.  Requires
#                    MARS_VERSION=x.y and MINERVA_VERSION=x.y.z.
#       cmbuild      Official build; requires MINERVA_VERSION=x.y.z
#                    on make command line.  Builds code and 
#                    documentation from scratch.
#    	installdocs  Installs documentation in the Minerva AFS Page
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
#        make MINERVA_VERSION=x.y.z cmbuild
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
# Build Minerva executable; C/C++ source must be built first.  Note that
# the executable is always built; it really has too many dependencies
# to try to build it only when some dependency has changed, and on top
# of that it's not usually needed or built during day-to-day 
# development.

BASE_KIT = $(TOP_DIR)/tools/basekits/base-tk-thread-linux-ix86
ARCHIVE = $(MINERVA_TCL_HOME)/lib/teapot


bin: check_env src
	@ echo ""
	@ echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@ echo "+              Building Minerva Executable             +"
	@ echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@ echo ""
	tclapp $(TOP_DIR)/bin/minerva.tcl                   \
		$(TOP_DIR)/lib/*/*                          \
		$(TOP_DIR)/mars/lib/*/*                     \
		-out $(TOP_DIR)/bin/minerva                 \
		-prefix $(BASE_KIT)                         \
		-archive $(ARCHIVE)                         \
		-follow                                     \
		-pkgref "comm"                              \
		-pkgref "Img       -require 1.3"            \
	        -pkgref "snit      -require 2.2"            \
	        -pkgref "BWidget   -require 1.8"            \
                -pkgref "Tktable"                           \
		-pkgref "treectrl"                          \
		-pkgref "sqlite3   -require 3.5"            \
		-pkgref "tablelist -require 4.9"            \
		-pkgref "tdom"                              \
		-pkgref "textutil::expander"                \
		-pkgref "Plotchart"

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
# Copy documentation to the Minerva AFS page.

installdocs: check_env
	cd $(TOP_DIR)/docs ; make install


#---------------------------------------------------------------------
# Target: build
#
# Build code and documentation from scratch, and run tests.

build: clean src bin docs test

#---------------------------------------------------------------------
# Tag Build

BUILD_TAG = https://oak.jpl.nasa.gov/svn/minerva/tags/minerva_$(MINERVA_VERSION)
MARS_TAG  = https://oak.jpl.nasa.gov/svn/mars/tags/mars_$(MARS_VERSION)

# The svn ls of the MARS_TAG ensures that the Mars version is defined.

tag: check_cmbuild
	svn ls $(MARS_TAG)
	svn copy -m"Build $(MINERVA_VERSION)" . $(BUILD_TAG)
	svn switch $(BUILD_TAG) .
	$(TOP_DIR)/mars/bin/mars import $(MARS_VERSION)

#---------------------------------------------------------------------
# Target: cmbuild
#
# Official CM build.  Requires a valid (numeric) MINERVA_VERSION.

cmbuild: check_cmbuild clean srctar src bin docs tar
	@ echo ""
	@ echo "*****************************************************"
	@ echo "         CM Build: Minerva $(MINERVA_VERSION) Complete"
	@ echo "*****************************************************"
	@ echo ""

check_cmbuild:
	@ echo ""
	@ echo "*****************************************************"
	@ echo "                CM Build: Minerva $(MINERVA_VERSION)"
	@ echo "                CM Build: Mars $(MARS_VERSION)"
	@ echo "*****************************************************"
	@ echo ""
	@ $(TOP_DIR)/tools/bin/chkversion $(MINERVA_VERSION) $(MARS_VERSION)

#---------------------------------------------------------------------
# Target: tar

tar:
	@ echo ""
	@ echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@ echo "+               Making ../minerva_$(MINERVA_VERSION).tar"
	@ echo "+               Making ../minerva_$(MINERVA_VERSION)_docs.tar"
	@ echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@ echo ""

	$(TOP_DIR)/tools/bin/make_tar install $(MINERVA_VERSION)
	$(TOP_DIR)/tools/bin/make_tar docs    $(MINERVA_VERSION)

#---------------------------------------------------------------------
# Target: srctar

srctar:
	@ echo ""
	@ echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@ echo "+               Making ../minerva_$(MINERVA_VERSION)_src.tar"
	@ echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@ echo ""

	$(TOP_DIR)/tools/bin/make_tar source $(MINERVA_VERSION)


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
	-rm $(TOP_DIR)/bin/minerva
	cd $(TOP_DIR)/mars ; make clean
	cd $(TOP_DIR)/src  ; make clean
	cd $(TOP_DIR)/test ; make clean
	cd $(TOP_DIR)/docs ; make clean

#---------------------------------------------------------------------
# Shared Rules

include MakeRules






