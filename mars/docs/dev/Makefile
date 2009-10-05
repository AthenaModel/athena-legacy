#---------------------------------------------------------------------
# TITLE:
#    Makefile -- mars/docs/dev Makefile
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

# Documents to build
EHTML_DOCS = $(wildcard *.ehtml)
HTML_DOCS  = $(EHTML_DOCS:%.ehtml=%.html)

#---------------------------------------------------------------------
# Target: all

all: $(HTML_DOCS)

#---------------------------------------------------------------------
# Target: $(HTML_DOCS) -- Builds EHTML docs

$(HTML_DOCS): $(EHTML_DOCS)
	$(DOC_TOOL) -debug $(EHTML_DOCS)

#---------------------------------------------------------------------
# Target: clean -- Removes build products

clean:
	rm -f $(HTML_DOCS)

#---------------------------------------------------------------------
# Standard Rules
#
# Standard rules and settings are defined in the following rules file.

include $(TOP_DIR)/MakeRules

