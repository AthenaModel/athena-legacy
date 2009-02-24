#---------------------------------------------------------------------
# TITLE:
#    Makefile -- Athena Test Makefile
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    This Makefile defines the following targets:
#
#    	all          test
#    	test         Runs all Athena tests.
#       packages     Runs tests for Tcl packages
#    	clean        Deletes all build products
#
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Settings

TOP_DIR = $(shell pwd)/..

# Standard definitions are found in the following file.

include $(TOP_DIR)/MakeDefs

PACKAGES = projectlib

#---------------------------------------------------------------------
# Target: all

all: test

#---------------------------------------------------------------------
# Target: clean

clean:
	rm -f packages.log apps.log

#---------------------------------------------------------------------
# Target: test
#
# Test Tcl packages first, then compiled libraries and applications.

test: 
	@echo "TOP_DIR = $(TOP_DIR)"
	@echo "Testing Library Packages: $(PACKAGES)"
	@make packages | tee packages.log | grep Failed
	@echo "Testing Application: athena_sim"
	@$(TEST_TOOL) all | tee app_sim.log | grep Failed


#---------------------------------------------------------------------
# Standard Rules
#
# Standard rules and settings are defined in this rules file.

include $(TOP_DIR)/MakeRules

#---------------------------------------------------------------------
# MakePackages
#
# The Make rules for testing Tcl packages are defined in this
# file.

include MakePackages








