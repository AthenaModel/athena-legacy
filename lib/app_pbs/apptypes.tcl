#-----------------------------------------------------------------------
# TITLE:
#    apptypes.tcl
#
# AUTHOR:
#    Dave Hanks
#
# DESCRIPTION:
#    Application Data Types
#
#    This module defines simple data types are application-specific and
#    hence don't fit in projtypes(n).
#
#-----------------------------------------------------------------------

# eqnames
# The names of the queues on the PBS system
enum eqnames {
    shortq    "3 hours max"
    mediumq   "12 hours max"
    longq     "48 hours max"
    verylongq "192 hours max"
}



