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


    # mutate attritng parmdict
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
    # attrited and units are attrited proportionally.
    #
    # If g is "CIV", meaning civilian collateral damage,
    # then the casualties are allocated to the implicit population of
    # all groups in the neighborhood, and to all civilian units
    # in the neighborhood, in proportion to their population.
    #
    # NOTE: the caller should be sure to call "demog analyze"
    # after all attrition is done.

    typemethod {mutate attritng} {parmdict} {
        dict with parmdict {
            log normal aam "mutate attritng $n $g $casualties"

            # FIRST, determine what kind of attrition we're doing.
            if {$g eq "CIV"} {
                return [$type AttritNbhood $n $casualties]
            } else {
                if {[group gtype $g] eq "CIV"} {
                    return [$type AttritNbgroup $n $g $casualties]
                } else {
                    return [$type AttritFrcOrgUnits $n $g $casualties]
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
        set remaining $casualties

        rdb eval {
            SELECT u,personnel
            FROM units JOIN activity_gtype USING (a,gtype)
            WHERE n=$n AND g=$g AND personnel > 0
            ORDER BY attrit_order ASC, personnel DESC
        } {
            # FIRST, determine how many of the casualties the
            # unit can take.
            let take {min($personnel, $remaining)}
            let personnel {$personnel - $take}
            let remaining {$remaining - $take}

            # NEXT, apply the casualties to the unit
            log normal aam \
                "Unit $u takes $take casualties, leaving $personnel personnel"
            
            lappend undo [unit mutate personnel $u $personnel]

            # NEXT, if there are no more casualties, we're done
            if {$remaining == 0} {
                break
            }
        }

        # NEXT, if casualties is not zero, we attrited more than were
        # available.
        if {$remaining > 0} {
            let actual {$casualties - $remaining}

            log normal aam \
                "Overkill; only $actual casualties could be taken by $g in $n."
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
                return
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
                       implicit - 1                        AS personnel,
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
                WHERE n=$n AND g=$g AND n=origin AND personnel > 0
                ORDER BY share DESC
            } {
                # FIRST, allocate the share to this body of people.
                let kills     {int(min($remaining, ceil($share), $personnel))}
                let remaining {$remaining - $kills}

                # NEXT, if it's the implicit personnel, we're
                # done.
                if {$u eq ""} {
                    continue
                }

                # NEXT, it's a unit; attrit it.
                let personnel {int($personnel - $kills)}


                # NEXT, apply the casualties to the unit
                log normal aam \
                "Unit $u takes $kills casualties, leaving $personnel personnel"
            
                lappend undo [unit mutate personnel $u $personnel]

                # NEXT, we might have finished early
                if {$remaining == 0} {
                    break
                }
            }
        }

        return [join $undo \n]
    }


    # AttritNbhood n casualties
    #
    # n           Neighborhood in which attrition occurs
    # casualties  The number of casualties
    #
    # Attrits the civilian groups and units in the neighborhood, 
    # returning an undo script.

    typemethod AttritNbhood {n casualties} {
        # FIRST, prepare to undo
        set undo [list]

        # NEXT, get the neighborhood's population
        set nbpop [demog getn $n population]

        # NEXT, we have to leave at least one person in each
        # group's implicit personnel.  How many resident
        # groups are there?
        set numResident [llength [nbgroup gIn $n]]

        # NEXT, compute the actual number of casualties.
        let actual {min($casualties, $nbpop - $numResident)}

        if {$actual == 0} {
            log normal aam \
                "Overkill; no casualties can be inflicted."
            return
        } elseif {$actual < $casualties} {
            log normal aam \
                "Overkill; only $actual casualties can be inflicted."
        }
        
        # NEXT, apply attrition to the bodies, in order of size.
        set remaining $actual

        rdb eval {
            SELECT ''                                  AS u,
                   g                                   AS g,
                   implicit - 1                        AS personnel,
                   $n                                  AS origin,
                   $actual*(CAST (implicit AS REAL)/$nbpop)  
                                                       AS share
            FROM demog_ng 
            WHERE n=$n AND implicit > 1
            UNION
            SELECT u                                   AS u,
                   g                                   AS g,
                   personnel                           AS personnel,
                   origin                              AS origin,
                   $actual*(CAST (personnel AS REAL)/$nbpop) 
                                                       AS share
            FROM units
            WHERE n=$n AND personnel > 0
            ORDER BY share DESC
        } {
            # FIRST, allocate the share to this body of people.
            let kills     {int(min($remaining, ceil($share)))}
            let remaining {$remaining - $kills}

            # NEXT, compute the attrition.
            let take {int(min($personnel, $kills))}
            let personnel {int($personnel - $take)}

            # NEXT, prepare to save the proper group's attrition.
            incr attr([list $origin $g]) $kills

            # NEXT, if it's not a unit were done in this loop.
            if {$u eq ""} {
                continue
            }

            # NEXT, apply the casualties to the unit
            log normal aam \
                "Unit $u takes $take casualties, leaving $personnel personnel"
            
            lappend undo [unit mutate personnel $u $personnel]

            # NEXT, we might have finished early
            if {$remaining == 0} {
                break
            }
        }

        # NEXT, apply the accumulated attrition to each group in the
        # neighborhood, saving the undo command.
        foreach ng [array names attr] {
            lassign $ng n g
            set oldAttrition [demog getng $n $g attrition]

            lappend undo \
                [mytypemethod SetNbgroupAttrition $n $g $oldAttrition]

            let newAttrition {$oldAttrition + $attr($ng)}

            $type SetNbgroupAttrition $n $g $newAttrition
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
    
    # mutate attritunit parmdict
    #
    # parmdict      Dictionary of order parms
    #
    #   u           Unit to be attrited.
    #   casualties  Number of casualties taken by the unit.
    #
    # Attrits the specified unit by the specified number of 
    # casualties (all of which are kills).
    #
    # CIV Attrition
    #
    # If u is a CIV unit, the attrition is counted against the
    # unit's neighborhood group.  In this case, the caller should 
    # be sure to call "demog analyze".

    typemethod {mutate attritunit} {parmdict} {
        dict with parmdict {
            log normal aam "mutate attritunit $u $casualties"

            # FIRST, prepare to undo
            set undo [list]

            # NEXT, retrieve the unit.
            set unit [unit get $u]

            dict with unit {
                # FIRST, get the actual number of casualties the
                # unit can take.
                let actual {min($casualties,$personnel)}

                if {$actual == 0} {
                    log normal aam \
                        "Overkill; no casualties can be inflicted."
                    return
                } elseif {$actual < $casualties} {
                    log normal aam \
                        "Overkill; only $actual casualties can be inflicted."
                }

                # NEXT, attrit the unit
                let personnel {$personnel - $actual}

                log normal aam \
              "Unit $u takes $actual casualties, leaving $personnel personnel"
            
                lappend undo [unit mutate personnel $u $personnel]

                # NEXT, if this is a CIV unit, attrit the unit's
                # group of origin.
                if {$gtype eq "CIV"} {
                    set oldAttrition [demog getng $origin $g attrition]

                    lappend undo \
                        [mytypemethod SetNbgroupAttrition \
                             $origin $g $oldAttrition]

                    let newAttrition {$oldAttrition + $actual}

                    $type SetNbgroupAttrition $origin $g $newAttrition
                }
            }
        }

        return [join $undo \n]
    }
}

#-------------------------------------------------------------------
# Orders


