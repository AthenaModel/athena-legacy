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

test_gram:
	$(TCLSH) gram.test

test_gram2:
	$(TCLSH) gram2.test

test_mam:
	$(TCLSH) mam.test

test_simtypes:
	$(TCLSH) simtypes.test

test_ucurve:
	$(TCLSH) ucurve.test

test_uram:
	$(TCLSH) uram.test $(FLAGS)

include $(TOP_DIR)/MakeRules
