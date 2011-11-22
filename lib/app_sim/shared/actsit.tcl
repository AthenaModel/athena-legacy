#-----------------------------------------------------------------------
# TITLE:
#    actsit.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1) Activity Situation module
#
#    This module defines a singleton, "actsit", which is used to
#    manage the collection of activity situation objects, or actsits.
#    Actsits are situations; see situation(sim) for additional details.
#
#    Entities defined in this file:
#
#    actsit      -- The actsit ensemble
#    actsitType  -- The type for the actsit objects.
#
#    A single snit::type could do both jobs--but at the expense
#    of accidentally creating an actsit object if an incorrect actsit
#    method name is used.
#
#    * Actsits are created, updated, and deleted by the "actsit assess" 
#      command, which detects new actsits, deletes vanished actsits, and 
#      calls the actsit rule sets as appropriate.  Actsit analysis is
#      driven by the neighborhood status computed by nbstat(sim).
#
#    * This module calls the actsit rule sets when it detects 
#      relevant state transitions during [actsit assess].
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# actsit singleton

snit::type actsit {
    # Make it an ensemble
    pragma -hasinstances 0

   
    #-------------------------------------------------------------------
    # Initialization method

    # table
    #
    # Return the name of the RDB table for this type.

    typemethod table {} {
        return "actsits_t"
    }


    # assess
    #
    # This method should be called periodically, just before the
    # GRAM advance.  It looks for new, vanished, and
    # changed situations, performs the related housekeeping, and calls
    # the actsit rule sets as appropriate.

    typemethod assess {} {
        # FIRST, look for new activity situations.
        rdb eval {
            SELECT * FROM activity_nga
            WHERE s = 0
            AND   coverage > 0.0
        } row {
            # FIRST, Create the situation
            set s [situation create $type       \
                       stype    $row(stype)     \
                       n        $row(n)         \
                       g        $row(g)         \
                       coverage $row(coverage)  \
                       state    ACTIVE]

            rdb eval {
                INSERT INTO actsits_t(s,a)
                VALUES($s,$row(a))
            }

            log detail actsit "$s: created for $row(n),$row(g),$row(a)"

            # NEXT, remember that it's new this time around.
            set new($s) 1

            # NEXT, get an actsit object to manipulate the data.
            set sit [situation get $s]

            # NEXT, create a GRAM driver for this situation
            $sit set driver [aram driver add \
                                 -dtype    $row(stype) \
                                 -name     "Sit $s"    \
                                 -oneliner [$sit oneliner]]

            # NEXT, link it to the activity_nga object.
            rdb eval {
                UPDATE activity_nga
                SET s = $s
                WHERE n=$row(n) AND g=$row(g) AND a=$row(a)
            }

            # NEXT, assess the satisfaction implications of this new
            # situation.
            actsit_rules monitor $sit
        }

        # NEXT, call the relevant rule sets for all pre-existing
        # live actsits.
        rdb eval {
            SELECT s                              AS s,
                   activity_nga.coverage          AS coverage,
                   activity_nga.nominal           AS nominal
            FROM actsits JOIN activity_nga USING (s)
        } {
            log detail actsit "$s: reviewing"

            # FIRST, If we just created this one, continue.
            if {[info exists new($s)]} {
                log detail actsit "$s: brand new, skipping"
                continue
            }

            # NEXT, get its object.
            set sit [situation get $s]

            # NEXT, If the coverage has changed, check the state.
            if {$coverage ne [$sit get coverage]} {
                # FIRST, save the coverage, and set the state if appropriate.
                $sit set coverage $coverage

                if {$coverage > 0} {
                    $sit set state ACTIVE
                    $sit set change UPDATED
                } elseif {$nominal == 0} {
                    # The situation ends when the coverage is 0 and there
                    # are no personnel assigned to the activity.
                    $sit set state ENDED
                    $sit set change ENDED
                    
                    log normal actsit "$s: end"
                } else {
                    $sit set state INACTIVE
                    $sit set change UPDATED
                }

                # NEXT, the situation has changed in some way; note the time.
                $sit set tc [simclock now]
            }

            # NEXT, call the monitor rule set.
            actsit_rules monitor $sit
        }
    }

    # get s -all|-live
    #
    # s               The situation ID
    #
    # -all   Default.  All situations are included
    # -live  Only live situations are included.
    #
    # Returns the object associated with the ID.  A record must already
    # exist in the RDB.

    typemethod get {s {opt -all}} {
        set sit [situation get $s $opt]

        if {$sit ne "" && [$sit kind] ne $type} {
            error "no such activity situation: \"$s\""
        }

        return $sit
    }
}

#-----------------------------------------------------------------------
# actsitType

snit::type actsitType {
    #-------------------------------------------------------------------
    # Components

    component base   ;# situationType instance


    #-------------------------------------------------------------------
    # Instance Variables

    # base and derived info arrays, aliased to the matching
    # situationType arrays.
    variable binfo
    variable dinfo

    #-------------------------------------------------------------------
    # Constructor

    constructor {s} {
        # FIRST, create the base situation object; this will retrieve
        # the data from disk.
        set base [situationType ${selfns}::base ::actsit $s]

        # NEXT, alias our arrays to the base arrays.
        upvar 0 [$base info vars binfo] ${selfns}::binfo
        upvar 0 [$base info vars dinfo] ${selfns}::dinfo
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to base


    # oneliner
    #
    # Returns a one-line description of the situation
    # NOTE: Overrides base method
    
    method oneliner {} {
        return "$binfo(g) $binfo(stype) in $binfo(n)"
    }
}



