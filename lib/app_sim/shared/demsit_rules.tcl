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

    # assess
    #
    # Assesses any existing demographic situations, which it finds for
    # itself.
    
    typemethod assess {} {
        # FIRST, UNEMPloyment situations
        rdb eval {
            SELECT n, g, ngfactor, nfactor
            FROM demog_context
            WHERE population > 0
            AND (ngfactor > 0.0 OR nfactor > 0.0)
        } row {
            unset -nocomplain row(*)
            
            set sit [array get row]
            dict with sit {}
            
            if {![dam isactive UNEMP]} {
                log warning actr \
                    "monitor UNEMP: ruleset has been deactivated"
                return
            }

            dict set sit driver_id \
                [driver create UNEMP "$g UNEMP in $n" $g]
            
            bgcatch {
                demsit_rules UNEMP $sit
            }
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
    # sit       The demsit dict for this situation
    #
    # This method is called when unemployment significantly affects
    # a group g in neighborhood n.

    typemethod UNEMP {sit} {
        # FIRST unpack the dict data
        dict with sit {}
        log detail demr [list UNEMP $driver_id]

        dam ruleset UNEMP $driver_id

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







