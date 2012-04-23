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



# REPORT:SATCONTRIB
#
# Produces a Contribution to Satisfaction Report

order define REPORT:SATCONTRIB {
    title "Contribution to Satisfaction Report"
    options \
        -sendstates     PAUSED

    parm g      enum  "Group"         -enumtype civgroup
    parm c      enum  "Concern"       -enumtype {ptype c+mood} -defval "MOOD"
    parm top    text  "Number"        -defval 20
    parm start  text  "Start Time"    -defval "T0"
    parm end    text  "End Time"      -defval "NOW"
} {
    # FIRST, prepare the parameters
    prepare g      -toupper -required -type civgroup
    prepare c      -toupper -required -type {ptype c+mood}
    prepare top                       -type ipositive
    prepare start  -toupper           -type {simclock past}
    prepare end    -toupper           -type {simclock past}

    returnOnError

    # NEXT, validate the start and end times.

    if {$parms(start) eq ""} {
        set parms(start) 0
    }

    if {$parms(end) eq ""} {
        set parms(end) [simclock now]
    }


    validate end {
        if {$parms(end) < $parms(start)} {
            reject end "End time is prior to start time"
        }
    }

    returnOnError -final

    # NEXT, convert the data
    if {$parms(top) eq ""} {
        set parms(top) 20
    }

    # NEXT, produce the report
    set query "top=$parms(top)+start=$parms(start)+end=$parms(end)"
    app show my://app/contribs/sat/$parms(g)/$parms(c)?$query
}






