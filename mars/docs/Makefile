#---------------------------------------------------------------------
# TITLE:
#    Makefile -- Mars Documentation Makefile
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    This Makefile defines the following targets:
#
#    all       Builds all documentation.
#    clean     Deletes all build products.
#    subs      Builds subdirectories
#    <subdir>  Rebuilds the specific subdirectory (make clean all)
#    install   Installs documentation in the JNEM Home Page on AFS
#
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Settings

TOP_DIR = ..

# Standard definitions are found in the following file.

include $(TOP_DIR)/MakeDefs

# Subdirectories to build
SUBS       = dev man1 man5 mann mani

# Documents to build
EHTML_DOCS = $(wildcard *.ehtml)
HTML_DOCS  = $(EHTML_DOCS:%.ehtml=%.html)\

#---------------------------------------------------------------------
# Target: all

all: check_env subs $(HTML_DOCS)

#---------------------------------------------------------------------
# Target: $(HTML_DOCS) -- Builds EHTML docs (other than manpages)

$(HTML_DOCS): $(EHTML_DOCS)
	$(DOC_TOOL) $(EHTML_DOCS)

#---------------------------------------------------------------------
# Target: <subdir> -- Rebuilds individual subdirectories

.PHONY: $(SUBS) 

$(SUBS):
	cd $@ ; make clean ; make

#---------------------------------------------------------------------
# Target: clean -- Removes build products

clean: cleansubs
	rm -f $(HTML_DOCS)
        

#---------------------------------------------------------------------
# Standard Rules
#
# Standard rules are defined in the following rules file.

include $(TOP_DIR)/MakeRules


#---------------------------------------------------------------------
# MakeSubs
#
# The Make rules for building subdirectories are defined in this
# file.

include MakeSubs

