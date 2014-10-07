#---------------------------------------------------------------------
# TITLE:
#    Makefile -- Mars Makefile
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    This Makefile defines the following targets:
#
#    	all          Builds Mars code and documentation.	
# 	    src          Builds Mars C code
#    	docs         Builds Mars documentation
#    	test         Runs Mars unit tests.
#    	clean        Deletes all build products
#       build        Builds code and documentation from scratch,
#                    and runs tests.
#       tag          Tags the contents of the current work area;
#                    requires MARS_VERSION=<tag>.  The <tag> is usually
#                    a version number, x.y.
#       cmbuild      Official build; requires MARS_VERSION=x.y
#                    on make command line.  Builds code and 
#                    documentation from scratch, using the version
#                    number.  Should only be used after checking out
#                    the tagged code.
#
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Settings

# Set the root of the directory tree.
TOP_DIR = .

.PHONY: all src docs test build cmbuild clean

#---------------------------------------------------------------------
# Shared Definitions

include MakeDefs

#---------------------------------------------------------------------
# Target: all
#
# Build code and documentation.

all: src docs

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
	cd $(TOP_DIR)/src ; make

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

	cd $(TOP_DIR)/test ; make

#---------------------------------------------------------------------
# Target: build
#
# Build code and documentation from scratch, and run tests.

build: clean src docs test

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
	cd $(TOP_DIR)/src  ; make clean
	cd $(TOP_DIR)/test ; make clean
	cd $(TOP_DIR)/docs ; make clean

#---------------------------------------------------------------------
# Target: tag
#
# Tags the version in the current work area.

BUILD_TAG = mars_$(MARS_VERSION)
TAG_DIR   = https://oak.jpl.nasa.gov/svn/mars/tags/$(BUILD_TAG)

tag: check_env check_ver
	@ echo ""
	@ echo "*****************************************************"
	@ echo "         Tagging: Mars $(MARS_VERSION)"
	@ echo "*****************************************************"
	@ echo ""
	svn copy -m"Tagging Mars $(MARS_VERSION)" . $(TAG_DIR)
	svn switch $(TAG_DIR) .
	echo $(MARS_VERSION) > $(VERSION_FILE)
	svn commit -m"Tagging Mars $(MARS_VERSION)" $(VERSION_FILE)
	@ echo ""
	@ echo "*****************************************************"
	@ echo "         Now in $(TAG_DIR)"
	@ echo "*****************************************************"
	@ echo ""

check_ver:
	@ if test ! -n "$(MARS_VERSION)" ; then \
	    echo "Makefile variable MARS_VERSION is not set." ; exit 1 ; fi
	@ if test "$(MARS_VERSION)" = "$(MARS_VERSION_DEFAULT)" ; then \
	    echo "Makefile variable MARS_VERSION is not set." ; exit 1 ; fi

#---------------------------------------------------------------------
# Shared Rules

include MakeRules



