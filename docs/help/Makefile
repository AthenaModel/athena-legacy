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
#
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Settings

TOP_DIR = ../..

# Standard definitions are found in the following file.

include $(TOP_DIR)/MakeDefs

HELP_FILES   = $(wildcard *.help)
HELPDB_FILES = $(wildcard *.helpdb)

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
# Standard Rules
#
# Standard rules and settings are defined in the following rules file.

include $(TOP_DIR)/MakeRules

