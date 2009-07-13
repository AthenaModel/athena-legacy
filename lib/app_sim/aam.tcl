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

    


    #-------------------------------------------------------------------
    # Queries

    # TBD

    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the simulation in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # the change cannot be undone, the mutator returns the empty string.


    # mutate attritnf parmdict
    #
    # parmdict      Dictionary of order parms
    #
    #   n           Neighborhood in which attrition occurs
    #   f           Group taking attrition, or "CIV" for civilian
    #               collateral damage.
    #   casualties  Number of casualties taken by the group.
    #   g1          Responsible force group, or ""
    #   g2          Responsible force group, or "".
    #
    # Attrits the specified group in the specified neighborhood
    # by the specified number of casualties (all of which are kills).
    #
    # FRC and ORG Attrition
    #
    # If f is a FRC or ORG group, the group's units are attrited in
    # the attrit_order of their activities, and by size; given the
    # same activity, larger units are attrited before smaller ones.
    #
    # CIV Attrition
    #
    # If f is a civilian group, the group's implicit population is
    # attrited and units are attrited proportionally.
    #
    # If f is "CIV", meaning civilian collateral damage,
    # then the casualties are allocated to the implicit population of
    # all groups in the neighborhood, and to all civilian units
    # in the neighborhood, in proportion to their population.  Also,
    # g1 and g2 will be given responsibility for the attrition.
    #
    # NOTE: the caller should be sure to call "demog analyze"
    # after all attrition is done.

    typemethod {mutate attritnf} {parmdict} {
        dict with parmdict {
            log normal aam "mutate attritnf $n $f $casualties $g1 $g2"

            # FIRST, determine what kind of attrition we're doing.
            if {$f eq "CIV"} {
                return [$type AttritNbhood $n $casualties $g1 $g2]
            } else {
                if {[group gtype $f] eq "CIV"} {
                    return [$type AttritNbgroup $n $f $casualties $g1 $g2]
                } else {
                    return [$type AttritFrcOrgUnits $n $f $casualties]
                }
            }
        }
    }

    # AttritFrcOrgUnits n f casualties
    #
    # n           Neighborhood in which attrition occurs
    # f           Group to which attrition occurs
    # casualties  The number of casualties
    #
    # Removes the specified number of casualties from the 
    # group in the neighborhood, if possible.

    typemethod AttritFrcOrgUnits {n f casualties} {
        # FIRST, prepare to undo
        set undo [list]

        # FIRST, attrit units until there are no more units with
        # personnel or all of the casualties have been taken.
        set remaining $casualties
        set gtype ""

        rdb eval {
            SELECT u,personnel,units.gtype AS gtype
            FROM units JOIN activity_gtype USING (a,gtype)
            WHERE n=$n AND g=$f AND personnel > 0
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
        let actual {$casualties - $remaining}

        if {$remaining > 0} {
            log normal aam \
                "Overkill; only $actual casualties could be taken by $f in $n."
        }

        # NEXT, save ORG attrition for attitude assessment
        if {$gtype eq "ORG"} {
            lappend undo [$type SaveOrgAttrition $n $f $casualties]
        }

        return [join $undo \n]
    }


    # SaveOrgAttrition n f casualties
    #
    # n           The neighborhood in which the attrition took place.
    # f           The CIV group receiving the attrition
    # casualties  The number of casualties
    #
    # Accumulates the attrition for later attitude assessment.

    typemethod SaveOrgAttrition {n f casualties} {
        # FIRST, prepare to accumulated undo info
        set undo [list]

        # NEXT, save nf casualties for satisfaction.
        rdb eval {
            INSERT INTO attrit_nf(n,f,casualties)
            VALUES($n,$f,$casualties);
        }

        set id [rdb last_insert_rowid]

        lappend undo [mytypemethod DeleteAttritNF $id]

        return [join $undo \n]
    }


    # AttritNbgroup n f casualties g1 g2
    #
    # n           Neighborhood in which attrition occurs
    # f           Group to which attrition occurs
    # casualties  The number of casualties
    # g1          Responsible group
    # g2          Responsible group
    #
    # Attrits the group, returning an undo script

    typemethod AttritNbgroup {n f casualties g1 g2} {
        # FIRST, prepare to undo
        set undo [list]

        # NEXT, get the group's data
        set dict [demog getng $n $f]

        if {[dict size $dict] == 0} {
            log warning demog \
                "mutate attrit -- $f is not resident in $n"
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
            lappend undo [mytypemethod SetNbgroupAttrition $n $f $attrition]

            let newAttrition {$attrition + $actual}

            $type SetNbgroupAttrition $n $f $newAttrition

            # NEXT, save the casualties for later attitude assessment.
            lappend undo [$type SaveCivAttrition $n $f $actual $g1 $g2] 

            # NEXT, apply attrition to the bodies, in order of size.
            set remaining $actual

            rdb eval {
                SELECT ''                                  AS u,
                       implicit - 1                        AS personnel,
                       $actual*(CAST (implicit AS REAL)/$population)  
                                                           AS share
                FROM demog_ng 
                WHERE n=$n AND g=$f AND implicit > 1
                UNION
                SELECT u                               AS u,
                       personnel                       AS personnel,
                       $actual*(CAST (personnel AS REAL)/$population) 
                                                       AS share
                FROM units
                WHERE n=$n AND g=$f AND n=origin AND personnel > 0
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


    # AttritNbhood n casualties g1 g2
    #
    # n           Neighborhood in which attrition occurs
    # casualties  The number of casualties
    # g1          A responsible force group
    # g2          A responsible force group
    #
    # Attrits the civilian groups and units in the neighborhood, 
    # returning an undo script.

    typemethod AttritNbhood {n casualties g1 g2} {
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
                   $actual*(CAST ((implicit-1) AS REAL)/$nbpop)  
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
            WHERE gtype='CIV' AND n=$n AND personnel > 0
            ORDER BY share DESC
        } {
            # FIRST, allocate the share to this body of people.
            let kills     {int(min($remaining, ceil($share)))}
            let remaining {$remaining - $kills}

            # NEXT, compute the attrition.
            let take {int(min($personnel, $kills))}
            let personnel {int($personnel - $take)}

            # NEXT, prepare to save the proper group's attrition, to
            # update the demographics.
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
            # FIRST, get the group and neighborhood.
            lassign $ng m f

            # NEXT, save the attrition for attitude assessment for
            # local groups
            if {$m eq $n} {
                lappend undo [$type SaveCivAttrition $n $f $attr($ng) $g1 $g2]
            }

            # NEXT, update the attrition model.
            set oldAttrition [demog getng $m $f attrition]

            lappend undo \
                [mytypemethod SetNbgroupAttrition $m $f $oldAttrition]

            let newAttrition {$oldAttrition + $attr($ng)}

            $type SetNbgroupAttrition $m $f $newAttrition
        }
            

        return [join $undo \n]
    }

    # SaveCivAttrition n f casualties g1 g2
    #
    # n           The neighborhood in which the attrition took place.
    # f           The CIV group receiving the attrition
    # casualties  The number of casualties
    # g1          A responsible force group, or ""
    # g2          A responsible force group, g2 != g1, or ""
    #
    # Accumulates the attrition for later attitude assessment.

    typemethod SaveCivAttrition {n f casualties g1 g2} {
        # FIRST, prepare to accumulated undo info
        set undo [list]

        # NEXT, save nf casualties for satisfaction.
        rdb eval {
            INSERT INTO attrit_nf(n,f,casualties)
            VALUES($n,$f,$casualties);
        }

        set id [rdb last_insert_rowid]

        lappend undo [mytypemethod DeleteAttritNF $id]

        # NEXT, save nfg casualties for cooperation
        if {$g1 ne ""} {
            rdb eval {
                INSERT INTO attrit_nfg(n,f,casualties,g)
                VALUES($n,$f,$casualties,$g1);
            }
            
            set id [rdb last_insert_rowid]
            
            lappend undo [mytypemethod DeleteAttritNFG $id]
        }

        if {$g2 ne ""} {
            rdb eval {
                INSERT INTO attrit_nfg(n,f,casualties,g)
                VALUES($n,$f,$casualties,$g2);
            }
            
            set rowId [rdb last_insert_rowid]
            
            lappend undo [mytypemethod DeleteAttritNFG $rowId]
        }

        return [join $undo \n]
    }

    # DeleteAttritNF id
    #
    # id     Row ID of a record
    #
    # Deletes the row on undo.

    typemethod DeleteAttritNF {id} {
        rdb eval {
            DELETE FROM attrit_nf WHERE id=$id
        }
    }

    # DeleteAttritNFG id
    #
    # id     Row ID of a record
    #
    # Deletes the row on undo.

    typemethod DeleteAttritNFG {id} {
        rdb eval {
            DELETE FROM attrit_nfg WHERE id=$id
        }
    }

    # SetNbgroupAttrition n f attrition
    #
    # n           Neighborhood
    # f           Group resident in n
    # attrition   New accumulated attrition value
    #
    # Sets the cumulative attrition value for the n and f

    typemethod SetNbgroupAttrition {n f attrition} {
        rdb eval {
            UPDATE demog_ng
            SET attrition = $attrition
            WHERE n=$n AND g=$f
        }
    }
    
    # mutate attritunit parmdict
    #
    # parmdict      Dictionary of order parms
    #
    #   u           Unit to be attrited.
    #   casualties  Number of casualties taken by the unit.
    #   g1          Responsible group
    #   g2          Responsible group
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
            log normal aam "mutate attritunit $u $casualties $g1 $g2"

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
                    # FIRST, attrit the group of origin
                    set oldAttrition [demog getng $origin $g attrition]

                    lappend undo \
                        [mytypemethod SetNbgroupAttrition \
                             $origin $g $oldAttrition]

                    let newAttrition {$oldAttrition + $actual}

                    $type SetNbgroupAttrition $origin $g $newAttrition

                    # NEXT, save the attrition for attitude assessment,
                    # if the unit is in its neighborhood of origin.
                    if {$origin eq $n} {
                        lappend undo \
                            [$type SaveCivAttrition $n $g $actual $g1 $g2] 
                    }
                }

                # NEXT, if this is an ORG unit, save the attrition.
                if {$gtype eq "ORG"} {
                    lappend undo \
                        [$type SaveOrgAttrition $n $g $actual] 
                }
            }
        }

        return [join $undo \n]
    }

    #-------------------------------------------------------------------
    # Order Helpers

    # RefreshGroup field parmdict
    #
    # field     The "Group" field in an A:GROUP order.
    # parmdict  The current values of the various fields.
    #
    # Sets the valid group values, if it's not set.

    typemethod RefreshGroup {field parmdict} {
        dict with parmdict {
            set groups [rdb eval {
                SELECT DISTINCT g
                FROM units
                WHERE n=$n AND gtype != 'CIV'
                UNION
                SELECT DISTINCT g
                FROM demog_ng
                WHERE n=$n
                ORDER BY g
            }]

            $field configure -values $groups
        }
    }

    # RefreshAG_Group1 field parmdict
    #
    # field     The "g1" field in any A:GROUP order.
    # parmdict  The current values of the various fields.
    #
    # g1 is valid only for CIV groups.

    typemethod RefreshAG_Group1 {field parmdict} {
        dict with parmdict {
            if {$f ne "" && [group gtype $f] eq "CIV"} {
                $field configure -values [frcgroup names]
                $field configure -state normal
            } else {
                $field configure -values {}
                $field configure -state disabled
            }
        }
    }

    # RefreshAU_Group1 field parmdict
    #
    # field     The "g1" field in A:UNIT order.
    # parmdict  The current values of the various fields.
    #
    # g1 is valid only for CIV units.

    typemethod RefreshAU_Group1 {field parmdict} {
        dict with parmdict {
            if {$u ne "" && [unit get $u gtype] eq "CIV"} {
                $field configure -values [frcgroup names]
                $field configure -state normal
            } else {
                $field configure -values {}
                $field configure -state disabled
            }
        }
    }

    # RefreshRespGroup2 field parmdict
    #
    # field     The "g2" field in any attrition order.
    # parmdict  The current values of the various fields.
    #
    # Sets the valid group values: force groups not including
    # g1.

    typemethod RefreshRespGroup2 {field parmdict} {
        dict with parmdict {
            if {$g1 eq ""} {
                $field configure -values {}
                $field configure -state disabled
            } else {
                set groups [frcgroup names]
                ldelete groups $g1
                
                $field configure -values $groups
                $field configure -state normal
            }
        }
    }
}

#-------------------------------------------------------------------
# Orders


# ATTRIT:NBHOOD
#
# Attrits all civilians in a neighborhood.

order define ::aam ATTRIT:NBHOOD {
    title "Magic Attrit Neighborhood"
    options \
        -sendstates {PREP PAUSED RUNNING}

    parm n          enum  "Neighborhood" -type nbhood -tags nbhood -refresh
    parm casualties text  "Casualties" 
    parm g1         enum  "Responsible Group" -type frcgroup -tags group \
        -refresh
    parm g2         enum  "Responsible Group" -tags group \
        -refreshcmd [list ::aam RefreshRespGroup2]
} {
    # FIRST, prepare the parameters
    prepare n          -toupper -required -type nbhood
    prepare casualties -toupper -required -type iquantity
    prepare g1         -toupper           -type frcgroup
    prepare g2         -toupper           -type frcgroup

    returnOnError

    # NEXT, g1 != g2
    if {$parms(g1) eq $parms(g2)} {
        set parms(g2) ""
    }

    # NEXT, attrit the civilians in the neighborhood
    set parms(f) "CIV"
    lappend undo [$type mutate attritnf [array get parms]]
    lappend undo [demog analyze]

    setundo [join $undo \n]
}


# ATTRIT:GROUP
#
# Attrits a group in a neighborhood.

order define ::aam ATTRIT:GROUP {
    title "Magic Attrit Group"
    options \
        -sendstates {PREP PAUSED RUNNING}

    parm n          enum  "Neighborhood"  -type nbhood  -tags nbhood -refresh
    parm f          enum  "To Group"      -tags group -refresh \
        -refreshcmd [list ::aam RefreshGroup]
    parm casualties text  "Casualties" 
    parm g1         enum  "Responsible Group" -tags group \
        -refresh \
        -refreshcmd [list ::aam RefreshAG_Group1]
    parm g2         enum  "Responsible Group" -tags group \
        -refreshcmd [list ::aam RefreshRespGroup2]
} {
    # FIRST, prepare the parameters
    prepare n          -toupper -required -type nbhood
    prepare f          -toupper -required -type group
    prepare casualties -toupper -required -type iquantity
    prepare g1         -toupper           -type frcgroup
    prepare g2         -toupper           -type frcgroup

    returnOnError

    # NEXT, get the group type
    set gtype [group gtype $parms(f)]

    # NEXT, g1 and g2 should be "" unless f is a CIV
    if {$gtype ne "CIV"} {
        validate g1 {
            reject g1 \
                "Responsible groups only matter when civilians are attrited"
        }

        validate g2 {
            reject g2 \
                "Responsible groups only matter when civilians are attrited"
        }
    }

    returnOnError

    # NEXT, g1 != g2
    if {$parms(g1) eq $parms(g2)} {
        set parms(g2) ""
    }

    # NEXT, attrit the group
    lappend undo [$type mutate attritnf [array get parms]]

    # NEXT, if it's a civilian group, update the demographics
    if {$gtype eq "CIV"} {
        lappend undo [demog analyze]
    }

    setundo [join $undo \n]
}


# ATTRIT:UNIT
#
# Attrits a single unit.

order define ::aam ATTRIT:UNIT {
    title "Magic Attrit Unit"
    options \
        -sendstates {PREP PAUSED RUNNING}

    parm u          enum  "Unit"       -type unit -tags unit -refresh
    parm casualties text  "Casualties" 
    parm g1         enum  "Responsible Group" -tags group \
        -refresh \
        -refreshcmd [list ::aam RefreshAU_Group1]
    parm g2         enum  "Responsible Group" -tags group \
        -refreshcmd [list ::aam RefreshRespGroup2]
} {
    # FIRST, prepare the parameters
    prepare u          -toupper -required -type unit
    prepare casualties -toupper -required -type iquantity
    prepare g1         -toupper           -type frcgroup
    prepare g2         -toupper           -type frcgroup

    returnOnError

    # NEXT, get the unit's group type
    set gtype [unit get $parms(u) gtype]

    # NEXT, g1 and g2 should be "" unless u is a CIV unit
    if {$gtype ne "CIV"} {
        validate g1 {
            reject g1 \
                "Responsible groups only matter when civilians are attrited"
        }

        validate g2 {
            reject g2 \
                "Responsible groups only matter when civilians are attrited"
        }
    }

    returnOnError


    # NEXT, attrit the unit
    lappend undo [$type mutate attritunit [array get parms]]

    # NEXT, if it's a civilian unit, update the demographics
    if {$gtype eq "CIV"} {
        lappend undo [demog analyze]
    }

    setundo [join $undo \n]
}


