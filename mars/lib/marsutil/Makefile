#---------------------------------------------------------------------
#
# Makefile -- Makefile for marsutil(n)
#
# Targets supported:
# 
#    test     Runs the test suite.

# Configuration variables

TOP_DIR=../..

TCLSH=tclsh
FLAGS=

include $(TOP_DIR)/MakeDefs

# Target: test
test:
	$(TCLSH) marsutil.test $(FLAGS)

test_cellmodel:
	$(TCLSH) cellmodel.test $(FLAGS)

test_dynaform:
	$(TCLSH) dynaform.test $(FLAGS)

test_marsmisc:
	$(TCLSH) marsmisc.test $(FLAGS)

test_order:
	$(TCLSH) order.test $(FLAGS)

test_simclock:
	$(TCLSH) simclock.test $(FLAGS)

test_sqldocument:
	$(TCLSH) sqldocument.test $(FLAGS)

test_sqlib:
	$(TCLSH) sqlib.test $(FLAGS)

test_undostack:
	$(TCLSH) undostack.test $(FLAGS)

include $(TOP_DIR)/MakeRules
