#-----------------------------------------------------------------------
# TITLE:
#    nbstat.tcl
#
# AUTHOR:
#    Will Duquette
#    Dave Hanks
#
# DESCRIPTION:
#    athena_sim(1) Simulation Module: Neighborhood Status
#
#    This module computes the status of each neighborhood and of
#    the groups and units within it.  Most of the work is done by
#    the security(sim) and activity(sim) submodules.
#
#    Note: the "init" method can be called as needed to reinitialize
#    the starting set of data.  This is typically done as part of
#    a reconciliation.
#
#    ::nbstat is a singleton object implemented as a snit::type.  To
#    initialize it, call "::nbstat init".  It can be re-initialized
#    on demand.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# nbstat

snit::type nbstat {
    # Make it an ensemble
    pragma -hastypedestroy 0 -hasinstances 0
    
    #-------------------------------------------------------------------
    # Initialization method

    typemethod init {} {
        # FIRST, check requirements
        require {[info commands ::log]  ne ""} "log is not defined."
        require {[info commands ::rdb]  ne ""} "rdb is not defined."

        # NEXT, initialize the sub-modules; this will cause each to
        # do an analysis.
        security init
        activity init

        # NEXT, Nbstat is up.
        log normal nbstat "Initialized"
    }

    #-------------------------------------------------------------------
    # analyze

    # analyze
    #
    # Analyzes neighborhood status, as of the present
    # time, given the current contents of the RDB.

    typemethod analyze {} {
        # FIRST, call the submodules
        security analyze
        activity analyze
    }
}








