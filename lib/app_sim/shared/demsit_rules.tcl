#-----------------------------------------------------------------------
# TITLE:
#    demsit_rules.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n): Athena Driver Assessment, Demographic Situation Rule Sets
#
#    ::demsit_rules is a singleton object implemented as a snit::type.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# demsit_rules

snit::type demsit_rules {
    # Make it an ensemble
    pragma -hastypedestroy 0 -hasinstances 0
    
    #-------------------------------------------------------------------
    # Type Constructor
    
    typeconstructor {
        # Import needed commands

        namespace import ::marsutil::* 
        namespace import ::simlib::* 
        namespace import ::projectlib::* 
    }

    #-------------------------------------------------------------------
    # Public Typemethods

    # monitor sit
    #
    # sit     demsit object
    #
    # A demsit's status has changed; run its monitor rule set.
    
    typemethod {monitor} {sit} {
        set ruleset [$sit get stype]

        if {![dam isactive $ruleset]} {
            log warning actr \
                "monitor $ruleset: ruleset has been deactivated"
            return
        }

        bgcatch {
            # Run the monitor rule set.
            demsit_rules $ruleset $sit
        }
    }

    #===================================================================
    # Demographic Situations
    #

    #-------------------------------------------------------------------
    # Rule Set: UNEMP:  Unemployment
    #
    # Demographic Situation: unemployment is affecting a neighborhood
    # group

    # UNEMP sit
    #
    # sit       The demsit object for this situation
    #
    # This method is called when unemployment significantly affects
    # a group g in neighborhood n.

    typemethod UNEMP {sit} {
        log detail demr [list UNEMP [$sit id]]

        set g        [$sit get g]
        set n        [$sit get n]
        set ngfactor [$sit get ngfactor]
        set nfactor  [$sit get nfactor]

        dam ruleset UNEMP [$sit get driver_id]

        dam detail "Civilian Group:"  $g
        dam detail "In Neighborhood:" $n
        dam detail "NbGroup UAF:"     [format %4.2f $ngfactor]
        dam detail "Nbhood UAF:"      [format %4.2f $nfactor]

        dam rule UNEMP-1-1 {
            $ngfactor > 0.0 || $nfactor > 0.0
        } {
            # While there is an UNEMP situation affecting group g
            #     with ngfactor > 0.0
            # Then for CIV group g in the nbhood,
            if {$ngfactor > 0.0} {
                dam sat T $g QOL [mag* $ngfactor L-]
            }

            # While there is an UNEMP situation affecting group g
            #     with nfactor > 0.0
            # Then for CIV group g in the nbhood,
            if {$nfactor > 0.0} {
                dam sat T $g SFT [mag* $nfactor M-]
                dam sat T $g AUT [mag* $nfactor S-]
            }
        }
    }
}







