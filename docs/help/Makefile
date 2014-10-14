#---------------------------------------------------------------------
# TITLE:
#    Makefile -- minerva/docs/help Makefile
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    This Makefile defines the following targets:
#
#    all       Builds all documentation in this directory.
#    clean     Deletes all build products.
#    show      Opens the helpbrowser on the help file
#
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Settings

TOP_DIR = ../..

# Standard definitions are found in the following file.

HELP_FILES   = $(wildcard *.help)
HELPDB_FILES = $(wildcard *.helpdb)
HELP_TOOL    = $(TOP_DIR)/bin/helptool.tcl

#---------------------------------------------------------------------
# Target: all

all: athena.helpdb

#---------------------------------------------------------------------
# Target: athena.helpdb

athena.helpdb: $(HELP_FILES)
	$(HELP_TOOL) athena.help

#---------------------------------------------------------------------
# Target: clean -- Removes build products

clean:
	rm -f $(HELPDB_FILES)


#---------------------------------------------------------------------
# Target: show -- builds and displays help

show: clean all
	$(HELP_BROWSER) athena.helpdb


