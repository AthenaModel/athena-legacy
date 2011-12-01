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

        if {![parmdb get dam.$ruleset.active]} {
            log warning actr \
                "monitor $ruleset: ruleset has been deactivated"
            return
        }

        bgcatch {
            # Run the monitor rule set.
            demsit_rules $ruleset $sit
        }
    }

    #-------------------------------------------------------------------
    # Rule Set Tools

    # detail label value
    #
    # Adds a detail to the input details
   
    proc detail {label value} {
        dam details [format "%-21s %s\n" $label $value]
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
    #
    # TBD: Need thresholds!

    typemethod UNEMP {sit} {
        log detail demr [list UNEMP [$sit id]]

        set g        [$sit get g]
        set n        [$sit get n]
        set ngfactor [$sit get ngfactor]
        set nfactor  [$sit get nfactor]

        dam ruleset UNEMP [$sit get driver]                        \
            -sit       $sit                                        \
            -f         $g                                          \
            -n         $n

        detail "NbGroup UAF:" [format %4.2f $ngfactor]
        detail "Nbhood UAF:"  [format %4.2f $nfactor]

        dam rule UNEMP-1-1 {
            $ngfactor > 0.0 || $nfactor > 0.0
        } {
            dam guard [format "%.2f %.2f" $ngfactor $nfactor]

            # While there is an UNEMP situation affecting group g
            #     with ngfactor > 0.0
            # Then for CIV group g in the nbhood,
            if {$ngfactor > 0.0} {
                dam sat slope QOL [mag* $ngfactor XXS-]
            }

            # While there is an UNEMP situation affecting group g
            #     with nfactor > 0.0
            # Then for CIV group g in the nbhood,
            if {$nfactor > 0.0} {
                dam sat slope SFT [mag* $nfactor XXS-]
                dam sat slope AUT [mag* $nfactor XXS-]
            }
        }

        dam rule UNEMP-2-1 {
            $ngfactor == 0.0 && $nfactor == 0.0
        } {
            dam guard

            # While there is a UNEMP situation affecting group g
            #     with ngfactor and nfactor both zero
            # Then for CIV group g in the nbhood there should be no
            # satisfaction implications.
            dam sat clear AUT SFT CUL QOL
        }
    }

    #-------------------------------------------------------------------
    # Utility Procs
    
    # mag* multiplier mag
    #
    # multiplier    A numeric multiplier
    # mag           A qmag value
    #
    # Returns the numeric value of mag times the multiplier.

    proc mag* {multiplier mag} {
        set result [expr {$multiplier * [qmag value $mag]}]

        if {$result == -0.0} {
            set result 0.0
        }

        return $result
    }

}







