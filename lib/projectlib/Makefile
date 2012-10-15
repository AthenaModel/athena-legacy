#---------------------------------------------------------------------
#
# Makefile -- Makefile for projectlib(n)
#
# Targets supported:
# 
#    test     Runs the test suite.

# Configuration variables

TOP_DIR=../..

TCLSH=tclsh8.5

include $(TOP_DIR)/MakeDefs

# Target: test
test:
	$(TCLSH) projectlib.test

test_week:
	$(TCLSH) week.test

test_weekclock:
	$(TCLSH) weekclock.test

include $(TOP_DIR)/MakeRules


