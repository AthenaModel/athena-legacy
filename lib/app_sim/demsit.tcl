#-----------------------------------------------------------------------
# FILE: demsit.tcl
#
#   Athena Demographic Situation module
#
# PACKAGE:
#   app_sim(n) -- athena_sim(1) implementation package
#
# PROJECT:
#   Athena S&RO Simulation
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Module: demsit
#
# athena_sim(1) Demographic Situation module
#
# This module defines a singleton, "demsit", which is used to
# manage the collection of demographic situation objects, or demsits.
# Demsits are situations; see situation(sim) for additional details.
#
# Entities defined in this file.
#
# <demsit>      - The demsit ensemble
# <demsitType>  - The instance type for the demsit objects.
#
# A single snit::type could do both jobs--but at the expense
# of accidentally creating a demsit object if an incorrect demsit
# method name is used.
#
# - Demsits are created, updated, and deleted by the "demsit assess" 
#   command, which detects new demsits, deletes demsits, and 
#   calls the demsit rule sets as appropriate.  Demsit assessment is
#   driven by the demographic statistics computed by demog(sim).
#
# - This module calls the demsit rule sets when it detects 
#   relevant state transitions during [demsit assess].
#
# Event Notifications:
#
#    The ::demsit module sends the following notifier(n) events.
#
#    <Entity> op s - When called, the _op_ will be one of 'create', 
#                    'update' or 'delete', and _s_ will be the ID of 
#                    the situation.
#-----------------------------------------------------------------------

snit::type demsit {
    # Make it an ensemble
    pragma -hasinstances 0

   
    #-------------------------------------------------------------------
    # Initialization method

    # table
    #
    # Return the name of the RDB table for this type.

    typemethod table {} {
        return "demsits_t"
    }


    # assess
    #
    # This method should be called periodically, just before the
    # GRAM advance.  It looks for new, vanished, and
    # changed situations, performs the related housekeeping, and calls
    # the demsit rule sets as appropriate.

    typemethod assess {} {
        # FIRST, look for new UNEMP situations.
        rdb eval {
            SELECT * FROM demog_context
            WHERE s = 0
            AND   (ngfactor > 0.0 OR nfactor > 0.0)
        } row {
            # FIRST, Create the situation
            set s [situation create $type       \
                       stype    "UNEMP"         \
                       n        $row(n)         \
                       g        $row(g)         \
                       state    ACTIVE]

            rdb eval {
                INSERT INTO demsits_t(s,ngfactor,nfactor)
                VALUES($s,$row(ngfactor),$row(nfactor))
            }

            log detail demsit "$s: UNEMP created for $row(n),$row(g)"

            # NEXT, remember that it's new this time around.
            set new($s) 1

            # NEXT, get a demsit object to manipulate the data.
            set sit [situation get $s]

            # NEXT, create a GRAM driver for this situation
            $sit set driver [aram driver add \
                                 -dtype    "UNEMP"          \
                                 -name     "Sit $s"         \
                                 -oneliner [$sit oneliner]]

            # NEXT, link it to the demog_ng object.
            rdb eval {
                UPDATE demog_ng
                SET s = $s
                WHERE n=$row(n) AND g=$row(g)
            }

            # NEXT, assess the satisfaction implications of this new
            # situation.
            demsit_rules monitor $sit

            # NEXT, inform all clients about the new object.
            # Always do this after running the rules,
            # because the object will be changed if a rule fired.
            notifier send $type <Entity> create $s
        }

        # NEXT, call the relevant rule sets for all pre-existing
        # live demsits.
        rdb eval {
            SELECT s                              AS s,
                   demog_context.ngfactor         AS ngfactor,
                   demog_context.nfactor          AS nfactor
            FROM demsits JOIN demog_context USING (s)
            WHERE state != 'ENDED'
        } {
            log detail demsit "$s: reviewing"

            # FIRST, If we just created this one, continue.
            if {[info exists new($s)]} {
                log detail demsit "$s: brand new, skipping"
                continue
            }

            # NEXT, get its object.
            set sit [situation get $s]

            # NEXT, If the coverage has changed, check the state.
            if {$ngfactor != [$sit get ngfactor] ||
                $nfactor  != [$sit get nfactor]
            } {
                # FIRST, save the factors, and set the state if appropriate.
                $sit set ngfactor $ngfactor
                $sit set nfactor  $nfactor

                if {$ngfactor > 0 || $nfactor > 0} {
                    $sit set state ACTIVE
                    $sit set change UPDATED
                } else {
                    # The situation ends when there is no significant
                    # unemployment in the neighborhood.
                    $sit set state ENDED
                    $sit set change ENDED
                    
                    rdb eval {
                        UPDATE demog_ng
                        SET s = 0
                        WHERE s = $s;
                    }
                    
                    log normal demsit "$s: end"
                }

                # NEXT, the situation has changed in some way; note the time.
                $sit set tc [simclock now]

                # NEXT, inform all clients about the update
                notifier send $type <Entity> update $s
            }

            # NEXT, call the monitor rule set.
            demsit_rules monitor $sit
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
            error "no such demographic situation: \"$s\""
        }

        return $sit
    }
}

#-----------------------------------------------------------------------
# Type: demsitType
#
# The instance type for demographic situations.
#
#-----------------------------------------------------------------------

snit::type demsitType {
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
        set base [situationType ${selfns}::base ::demsit $s]

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



