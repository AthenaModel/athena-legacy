#---------------------------------------------------------------------
#
# Makefile -- Makefile for simlib(n)
#
# Targets supported:
# 
#    test     Runs the test suite.

# Configuration variables

TOP_DIR=../..
TCLSH=tclsh

include $(TOP_DIR)/MakeDefs

# Target: test
test:
	$(TCLSH) simlib.test

test_mam:
	$(TCLSH) mam.test

test_simtypes:
	$(TCLSH) simtypes.test

include $(TOP_DIR)/MakeRules
