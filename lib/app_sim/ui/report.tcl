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










