#-----------------------------------------------------------------------
# TITLE:
#	mat3d.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       Mars: marsutil(n) Tcl Utilities
#
#	3-D Matrix commands.  
#
#       Matrix elements are retrieved and set using the lindex and lset 
#       commands.  An n1*n2*n3 matrix is indexed 0..n1-1, 0..n2-1,
#       0..n3-1.  Note that a 3-D matrix is really just a list of
#       "sheets", each of which is a normal 2-D matrix.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Exported commands

namespace eval ::marsutil:: {
    namespace export mat3d
}

#-----------------------------------------------------------------------
# Matrix Ensemble

snit::type ::marsutil::mat3d {
    # Make it an ensemble
    pragma -hastypeinfo 0 -hastypedestroy 0 -hasinstances 0

    typeconstructor {
        namespace import ::marsutil::* 
        namespace import ::marsutil::*
    }

    #-------------------------------------------------------------------
    # Ensemble subcommands

    # new s m n ?initval?
    #
    # s        Number of sheets
    # m        Number of rows per sheet
    # n        Number of columns per row
    # initval  Initial value (defaults to "")
    #
    # Creates a new 3-D matrix of s sheets by m rows by n columns; 
    # each cell is filled with initval, which defaults to the empty 
    # string.  Note that each sheet is a 2-D matrix and each row of each
    # matrix is a vector.
    typemethod new {s m n {initval {}}} {
        assert {$s >= 1 && $m >= 1 && $n >= 1}

        set mat3d {}

        for {set k 0} {$k < $s} {incr k} {
            lappend mat3d [mat new $m $n $initval]
        }
        
        return $mat3d
    }

    # sheets mat
    #
    # mat     A 3-D matrix
    #
    # Returns the number of sheets in the matrix.
    typemethod sheets {mat} {
        llength $mat
    }

    # rows mat
    #
    # mat     A 3-D matrix
    #
    # Returns the number of rows in the matrix.
    typemethod rows {mat} {
        llength [lindex $mat 0]
    }

    # cols mat
    #
    # mat     A 3-D matrix
    #
    # Returns the number of columns in the matrix.
    typemethod cols {mat} {
        llength [lindex $mat 0 0]
    }

    # equal a b
    #
    # a     A 3-D matrix
    # b     A 3-D matrix
    #
    # Returns 1 if the matrices are element-wise equal, and 0 otherwise.
    # The comparison is numeric.

    typemethod equal {a b} {
        foreach asheet $a bsheet $b {
            if {![mat equal $asheet $bsheet]} {
                return 0
            }
        }

        return 1
    }

    # add a b
    #
    # a     A 3-D matrix
    # b     A 3-D matrix
    #
    # Returns a 3-D matrix of the same size, the element-wise sum of 
    # a and b. 

    typemethod add {a b} {
        set result {}

        foreach asheet $a bsheet $b {
            lappend result [mat add $asheet $bsheet]
        }

        return $result
    }

    # sub a b
    #
    # a     A 3-D matrix
    # b     A 3-D matrix
    #
    # Returns a 3-D matrix of the same size, the element-wise difference
    # of a and b. 

    typemethod sub {a b} {
        set result {}

        foreach asheet $a bsheet $b {
            lappend result [mat sub $asheet $bsheet]
        }

        return $result
    }

    # scalarmul a k
    #
    # a     A 3-D matrix
    # k     A scalar constant
    #
    # Returns a 3-D matrix of the same size, in which each element is
    # the product of k and the matching element of a.

    typemethod scalarmul {a k} {
        set result {}

        foreach asheet $a {
            lappend result [mat scalarmul $asheet $k]
        }

        return $result
    }

    # format a fmtstring
    #
    # a            A 3-D matrix
    # fmtstring    A format(n) format string
    #
    # Returns a 3-D matrix of the same size, in which each element
    # element has been formatted using fmtstring.
    # the product of k and the matching element of a.

    typemethod format {a fmtstring} {
        set result {}

        foreach asheet $a {
            lappend result [mat format $asheet $fmtstring]
        }

        return $result
    }

    # pprint a ?slabels? ?rlabels? ?clabels?
    #
    # a            A 3-D matrix
    # slabels      A vector of sheet labels
    # rlabels      A vector of row labels
    # clabels      A vector of column labels
    #
    # Returns a pretty-printed text string of the content of
    # the matrix.  [mat pprint] is used to print the sheets.
    # If given, the elements of slabels defaults to "Sheet $i:".

    typemethod pprint {a {slabels ""} {rlabels ""} {clabels ""}} {
        # FIRST, get the sheet labels
        set slabels [GetLabels $a $slabels]

        # NEXT, format each sheet with a header
        set result {}

        foreach asheet $a label $slabels {
            if {[string length $result] > 0} {
                append result "\n"
            }

            append result "$label\n"

            append result [mat pprint $asheet $rlabels $clabels]
        }

        return $result
    }

    # pprintf a format ?slabels? ?rlabels? ?clabels?
    #
    # a            A 3-D matrix
    # format       A format(n) format string
    # slabels      A vector of sheet labels
    # rlabels      A vector of row labels
    # clabels      A vector of column labels
    #
    # Returns a pretty-printed text string of the content of
    # the matrix.  [mat pprintf] is used to print the sheets.
    # If given, the elements of slabels defaults to "Sheet $i:".

    typemethod pprintf {a format {slabels ""} {rlabels ""} {clabels ""}} {
        # FIRST, get the sheet labels
        set slabels [GetLabels $a $slabels]

        # NEXT, format each sheet with a header
        set result {}

        foreach asheet $a label $slabels {
            if {[string length $result] > 0} {
                append result "\n"
            }

            append result "$label\n"

            append result [mat pprintf $asheet $format $rlabels $clabels]
        }

        return $result
    }

    # pprintq a qual ?slabels? ?rlabels? ?clabels?
    #
    # a            A 3-D matrix
    # qual         A quality(n) object
    # slabels      A vector of sheet labels
    # rlabels      A vector of row labels
    # clabels      A vector of column labels
    #
    # Returns a pretty-printed text string of the content of
    # the matrix.  [mat pprintq] is used to print the sheets.
    # If given, the elements of slabels defaults to "Sheet $i:".

    typemethod pprintq {a qual {slabels ""} {rlabels ""} {clabels ""}} {
        # FIRST, get the sheet labels
        set slabels [GetLabels $a $slabels]

        # NEXT, format each sheet with a header
        set result {}

        foreach asheet $a label $slabels {
            if {[string length $result] > 0} {
                append result "\n"
            }

            append result "$label\n"

            append result [mat pprintq $asheet $qual $rlabels $clabels]
        }

        return $result
    }

    # GetSheetLabels a slabels
    #
    # a         A 3-D matrix
    # slabels   A vector of sheet labels, or {}
    #
    # Validates or creates sheet labels for a

    proc GetLabels {a slabels} {

        if {[llength $slabels] > 0} {
            assert {[vec size $slabels] == [mat3d sheets $a]}
        } else {
            set s [mat3d sheets $a]

            for {set k 0} {$k < $s} {incr k} {
                lappend slabels "Sheet $k:"
            }
        }
        
        return $slabels
    }
}





