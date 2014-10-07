#---------------------------------------------------------------------
#
# Makefile -- Makefile for app_doc(n)
#
# Targets supported:
# 
#    test     Runs the test suite.
#    clean    Cleans up afterwards

# Configuration variables

TOP_DIR=../..
TCLSH=tclsh8.5

include $(TOP_DIR)/MakeDefs

# Target: test
test:
	$(DOC_TOOL) sample.ehtml

clean:
	rm sample.html

include $(TOP_DIR)/MakeRules
