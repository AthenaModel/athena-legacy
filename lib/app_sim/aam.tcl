#-----------------------------------------------------------------------
# TITLE:
#    aam.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Athena Attrition Model
#
#    This module is responsible for computing and applying attritions
#    to units and neighborhood groups.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Module Singleton

snit::type aam {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Initialization

    # init
    #
    # Initializes the module before the simulation first starts to run.

    typemethod init {} {
        # NEXT, AAM is up.
        log normal aam "Initialized"
    }

    #-------------------------------------------------------------------
    # Analysis

    # TBD: Attrition at regular attrition intervals


    #-------------------------------------------------------------------
    # Queries

    # TBD -- will there be any?

    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the simulation in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # the change cannot be undone, the mutator returns the empty string.


    # mutate attrit parmdict
    #
    # parmdict      Dictionary of order parms
    #
    #   n           Neighborhood in which attrition occurs
    #   g           Group taking attrition, or "CIV" for civilian
    #               collateral damage.
    #   casualties  Number of casualties taken by the group.
    #
    # Attrits the specified group in the specified neighborhood
    # by the specified number of casualties (all of which are kills).
    #
    # FRC and ORG Attrition
    #
    # If g is a FRC or ORG group, the group's units are attrited in
    # the attrit_order of their activities, and by size; given the
    # same activity, larger units are attrited before smaller ones.
    #
    # CIV Attrition
    #
    # If g is a civilian group, the group's implicit population is
    # attrited.  If g is "CIV", meaning civilian collateral damage,
    # then the casualties are allocated to groups in proportion to
    # their population, and their implicit population is attrited.
    #
    # TBD: Talk to Bob; we should really attrit civilian units as
    # well, especially for magic attrition.  Units first, in attrit_order,
    # then implicit population?

    typemethod {mutate attrit} {parmdict} {
        # FIRST, prepare for undo
        set undo [list]

        dict with parmdict {
            log normal aam "mutate attrit $n $g $casualties"

            # FIRST, determine what kind of attrition we're doing.
            # Civilian attrition is handled by the demographics model.
            if {$g eq "CIV"} {
                lappend undo [$type AttritNbhood $n $casualties]
                # TBD: This shouldn't be here.  The attrition cycle
                # should call this once after computing attrition,
                # and the orders should call it after applying
                # attrition.
                lappend undo [demog analyze]
            } else {
                if {[group gtype $g] eq "CIV"} {
                    lappend undo [$type AttritNbgroup $n $g $casualties]
                    # TBD: This shouldn't be here.  The attrition cycle
                    # should call this once after computing attrition,
                    # and the orders should call it after applying
                    # attrition.
                    lappend undo [demog analyze]
                } else {
                    lappend undo [$type AttritFrcOrgUnits $n $g $casualties]
                }
            }
        }
    }

    # AttritFrcOrgUnits n g casualties
    #
    # n           Neighborhood in which attrition occurs
    # g           Group to which attrition occurs
    # casualties  The number of casualties
    #
    # Removes the specified number of casualties from the 
    # group in the neighborhood, if possible.

    typemethod AttritFrcOrgUnits {n g casualties} {
        # FIRST, prepare to undo
        set undo [list]

        # FIRST, attrit units until there are no more units with
        # personnel or all of the casualties have been taken.
        rdb eval {
            SELECT u,personnel
            FROM units JOIN activity_gtype USING (a,gtype)
            WHERE n=$n AND g=$g AND personnel > 0
            ORDER BY attrit_order ASC, personnel DESC
        } {
            # FIRST, determine how many of the casualties the
            # unit can take.
            let take {min($personnel, $casualties)}
            let personnel {$personnel - $take}
            let casualties {$casualties - $take}

            # NEXT, apply the casualties to the unit
            log normal aam \
                "Unit $u takes $take casualties, leaving $personnel personnel"
            
            lappend undo [unit mutate personnel $u $personnel]

            # NEXT, if there are no more casualties, we're done
            if {$casualties == 0} {
                break
            }
        }

        # NEXT, if casualties is not zero, we attrited more than were
        # available.
        if {$casualties > 0} {
            log normal aam \
            "Overkill; $casualties casualties could not be taken by $g in $n."
        }

        return [join $undo \n]
    }


    # AttritNbgroup n g casualties
    #
    # n           Neighborhood in which attrition occurs
    # g           Group to which attrition occurs
    # casualties  The number of casualties
    #
    # Attrits the group, returning an undo script

    typemethod AttritNbgroup {n g casualties} {
        # FIRST, prepare to undo
        set undo [list]

        # NEXT, get the group's data
        set dict [demog getng $n $g]

        if {[dict size $dict] == 0} {
            log warning demog \
                "mutate attrit -- $g is not resident in $n"
            return "# Nothing to undo"
        }

        # NEXT, attrit the group.
        dict with dict {
            # FIRST, How many casualties can we actually take?  We have
            # to leave at least one person in the implicit population,
            # but the units can all go to zero.
            #
            # Note that "population" is in fact the implicit population
            # plus the non-displaced personnel.
            let actual {min($casualties, $population - 1)}

            if {$actual == 0} {
                log normal aam \
                    "Overkill; no casualties can be inflicted."
            } elseif {$actual < $casualties} {
                log normal aam \
                    "Overkill; only $actual casualties can be inflicted."
            }


            # NEXT, apply the actual casualties to the group, saving the
            # undo command.
            lappend undo [mytypemethod SetNbgroupAttrition $n $g $attrition]

            let newAttrition {$attrition + $actual}

            $type SetNbgroupAttrition $n $g $newAttrition


            # NEXT, apply attrition to the bodies, in order of size.
            set remaining $actual

            rdb eval {
                SELECT ''                                  AS u,
                       ''                                  AS personnel,
                       $actual*(CAST (implicit AS REAL)/$population)  
                                                           AS share
                FROM demog_ng 
                WHERE n=$n AND g=$g AND implicit > 1
                UNION
                SELECT u                               AS u,
                       personnel                       AS personnel,
                       $actual*(CAST (personnel AS REAL)/$population) 
                                                       AS share
                FROM units
                WHERE origin=$n AND g=$g AND personnel > 0
                ORDER BY share DESC
            } {
                # FIRST, allocate the share to this body of people.
                let kills     {min($remaining, ceil($share))}
                let remaining {$remaining - $kills}

                # NEXT, if it's the implicit personnel, we're
                # done.
                if {$u eq ""} {
                    continue
                }

                # NEXT, it's a unit; attrit it.
                let take {min($personnel, $kills)}
                let personnel {$personnel - $take}


                # NEXT, apply the casualties to the unit
                log normal aam \
                "Unit $u takes $take casualties, leaving $personnel personnel"
            
                lappend undo [unit mutate personnel $u $personnel]

                # NEXT, we might have finished early
                if {$remaining == 0} {
                    break
                }
            }
        }

        return [join $undo \n]
    }


    # SetNbgroupAttrition n g attrition
    #
    # n           Neighborhood
    # g           Group resident in n
    # attrition   New accumulated attrition value
    #
    # Sets the cumulative attrition value for the n and g

    typemethod SetNbgroupAttrition {n g attrition} {
        rdb eval {
            UPDATE demog_ng
            SET attrition = $attrition
            WHERE n=$n AND g=$g
        }
    }
    
}

#-------------------------------------------------------------------
# Orders


