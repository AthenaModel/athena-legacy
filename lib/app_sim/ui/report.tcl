#-----------------------------------------------------------------------
# TITLE:
#    report.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Report Manager
#
#    This module contains the orders that produce customized reports
#    in the Detail browser.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# report

snit::type ::report {
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        enum edriverstate { 
            all       "All Drivers"
            active    "Active Drivers"
            empty     "Empty Drivers"
        }

        enum eparmstate { 
            ALL       "All Parameters"
            CHANGED   "Changed Parameters"
        }
    }
}


#-----------------------------------------------------------------------
# Orders



# REPORT:DRIVER
#
# Produces an Attitude Driver Report.

order define REPORT:DRIVER {
    title "Attitude Driver Report"
    options \
        -sendstates     PAUSED

    parm state enum  "Driver State"  -enumtype {::report::edriverstate} \
                                     -defval    active
} {
    # FIRST, prepare the parameters
    prepare state  -toupper -required -type {::report::edriverstate}

    returnOnError -final

    # NEXT, produce the report
    set url my://app/drivers

    if {$parms(state) ne "all"} {
        append url "/$parms(state)"
    }

    app show $url
}


# REPORT:PARMDB
#
# Produces a parmdb(5) report.

order define REPORT:PARMDB {
    title "Model Parameters Report"
    options \
        -sendstates     {PREP PAUSED}

    parm state    enum "Parameter State" -enumtype ::report::eparmstate \
                                         -defval   ALL
    parm wildcard text "Wild Card"
} {
    # FIRST, prepare the parameters
    prepare state     -required -type ::report::eparmstate
    prepare wildcard

    returnOnError -final

    # NEXT, produce the report
    if {$parms(state) eq "ALL"} {
        set url "my://app/parmdb"
    } else {
        set url "my://app/parmdb/changed"
    }

    if {$parms(wildcard) ne ""} {
        append url "?$parms(wildcard)"
    }

    app show $url
}








