#---------------------------------------------------------------------
# TITLE:
#    Makefile -- Mars Binary Code Makefile
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    This Makefile defines the following targets:
#
#    all       Build all binary code in all subdirectories.
#    clean     Deletes all build products in all subdirectories.
#    subs      Builds all subdirectories.
#    <subdir>  Rebuilds the specified subdirectory from scratch.
#
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Settings

TOP_DIR = ..

# Standard definitions are found in the following file.

include $(TOP_DIR)/MakeDefs

SRCLIBDIR = $(TOP_DIR)/src/lib

# Subdirectories to build
SUBS = libGeotrans libGeostars libMarsutil

.PHONY: all

all: $(SRCLIBDIR) subs

#---------------------------------------------------------------------
# Target: <subdir> -- Rebuilds individual subdirectories

.PHONY: $(SUBS)

$(SUBS):
	cd $@ ; make clean ; make

#---------------------------------------------------------------------
# Target: lib -- creates the lib directory

$(SRCLIBDIR):
	mkdir $(SRCLIBDIR)


#---------------------------------------------------------------------
# Standard Rules

include $(TOP_DIR)/MakeRules

#---------------------------------------------------------------------
# Making Subdirectories

include MakeSubs



