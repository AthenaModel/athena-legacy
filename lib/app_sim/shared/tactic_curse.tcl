#-----------------------------------------------------------------------
# TITLE:
#    tactic_curse.tcl
#
# AUTHOR:
#    Dave Hanks
#
# DESCRIPTION:
#    athena_sim(1): Complex User-defined Role-based Situation and
#                   Events (CURSE) tactic
#
#    This module implements the CURSE tactic. 
#
# PARAMETER MAPPING:
#
#    curse   <= curse
#    roles   <= roles
#    on_lock <= on_lock
#    once    <= once
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# Tactic: CURSE

tactic type define CURSE {curse roles once on_lock} system {
    #-------------------------------------------------------------------
    # Type Variables

    # modeChar: The mode character used by [curse]
    typevariable modeChar -array {
        persistent P
        transient  T
    }

    #-------------------------------------------------------------------
    # Public Methods

    #-------------------------------------------------------------------
    # tactic(i) subcommands
    #
    # See the tactic(i) man page for the signature and general
    # description of each subcommand.

    typemethod narrative {tdict} {
        dict with tdict {}

        set narr "[curse get $curse longname] ($curse). "

        foreach {role entities} $roles {
            append narr "$role = "
            append narr [join $entities ", "]
            append narr ". "
        }

        return $narr
    }

    typemethod check {tdict} {
        # FIRST, bring all attributes into scope
        dict with tdict {}

        set errors [list]

        # NEXT, the curse this tactic uses may have been deleted, disabled,
        # or invalid
        set exists [rdb exists {
                          SELECT curse_id FROM curses
                          WHERE curse_id = $curse
                      }]

        if {!$exists} {
            lappend errors "Curse $curse no longer exists."
        } else {
            # NEXT, it exists, is it "normal"?
            set state [rdb onecolumn {
                          SELECT state FROM curses
                          WHERE curse_id = $curse
                      }]

            if {$state ne "normal"} {
                lappend errors "Curse $curse is $state."
            }
        }

        # NEXT, it exists and is "normal", are the roles good?
        if {$exists && $state eq "normal"} {
            # NEXT, roles this tactic uses may have been deleted
            foreach role [dict keys $roles] {
                if {$role ni [curse rolenames $curse]} {
                    lappend errors "Role $role no longer exists."
                }
            }
        }

        return [join $errors ", "]
    }

    typemethod execute {tdict} {
        # FIRST, bring all attributes into scope
        dict with tdict {}

        set parms(curse_id) $curse

        # NEXT, go through each inject associated with this CURSE
        # firing rules as we go
        rdb eval {
            SELECT * FROM curse_injects
            WHERE curse_id=$curse
        } idata {
            switch -exact -- $idata(inject_type) {
                HREL {
                    # Change to horizontal relationships of group(s) in
                    # f with group(s) in g
                    set parms(f)    [dict get $roles $idata(f)]
                    set parms(g)    [dict get $roles $idata(g)]
                    set parms(mode) $modeChar($idata(mode))
                    set parms(mag)  $idata(mag)

                    tactic::CURSE hrel [array get parms]
                }

                VREL {
                    # Change to verticl relationships of group(s) in
                    # g with actor(s) in a
                    set parms(g)    [dict get $roles $idata(g)]
                    set parms(a)    [dict get $roles $idata(a)]
                    set parms(mode) $modeChar($idata(mode))
                    set parms(mag)  $idata(mag)

                    tactic::CURSE vrel [array get parms]
                }

                COOP {
                    # Change to cooperation of CIV group(s) in f
                    # with FRC group(s) in g
                    set parms(f)    [dict get $roles $idata(f)]
                    set parms(g)    [dict get $roles $idata(g)]
                    set parms(mode) $modeChar($idata(mode))
                    set parms(mag)  $idata(mag)

                    tactic::CURSE coop [array get parms]
                }

                SAT {
                    # Change of satisfaction of CIV group(s) in g
                    # with concern c
                    set parms(g)    [dict get $roles $idata(g)]
                    set parms(c)    $idata(c)
                    set parms(mode) $modeChar($idata(mode))
                    set parms(mag)  $idata(mag)

                    tactic::CURSE sat [array get parms]
                }

                default {
                    #Should never happen
                    error "Unrecognized inject type: $idata(inject_type)"
                }
            }
        }

        return 1
    }

    # checkRolemap rolemap curse
    #
    # rolemap   - a mapping of roles to entities
    # curse     - ID of a CURSE for which the checking is done
    #
    # This method looks at a mapping of entities to roles and checks
    # that given the inject in which the role exists whether the mapping
    # of the entities to that role makes sense. For instance, in a COOP
    # inject, the 'f' role must be all CIV groups. If a group is not
    # mapped properly to a role a validation error occurs.

    typemethod checkRolemap {rolemap curse} {
        # FIRST, extract all the roles from the injects in the supplied
        # CURSE, building up a map of role/entity types.
        rdb eval {
            SELECT * FROM curse_injects
            WHERE curse_id=$curse
        } idata {
            switch -exact -- $idata(inject_type) {
                HREL {
                    # f, any groups; g, any groups
                    set validmap($idata(f)) GRP
                    set validmap($idata(g)) GRP
                }

                VREL {
                    # g, any groups; a, any actors
                    set validmap($idata(g)) GRP
                    set validmap($idata(a)) ACT
                }

                COOP {
                    # f, CIV groups; g, FRC groups
                    set validmap($idata(f)) CIV
                    set validmap($idata(g)) FRC
                }

                SAT {
                    # g, CIV groups
                    set validmap($idata(g)) CIV
                }

                default {
                    # Should never happen
                    error "Unrecognized inject type: $idata(inject_type)"
                }
            }
        }
        
        # NEXT, traverse the mapping of groups to roles checking for
        # validation errors along the way
        foreach {role entities} $rolemap {
            # NEXT, validate that the role exists for this CURSE
            inject role validate $curse $role

            switch -exact -- $validmap($role) {
                GRP {
                    # Must be a valid group
                    foreach entity $entities {
                        ::group validate $entity
                    }
                }

                CIV {
                    # Must be a valid CIV group
                    foreach entity $entities {
                        ::civgroup validate $entity
                    }
                }
              
                FRC {
                    # Must be a valid FRC group
                    foreach entity $entities {
                        ::frcgroup validate $entity
                    }
                }
                
                ACT {
                    # Must be a valid actor
                    foreach entity $entities {
                        ::actor validate $entity
                    }
                } 
            }
        } 

        # NEXT, if no validation errors the rolemap checks out
        return $rolemap
    }

    # hrel parmdict
    #
    # Causes an assessment of horizontal relationship among
    # group(s).
    #
    # parmdict:
    #   curse_id   - ID of the CURSE causing the change
    #   mode       - P (persistent) or T (transient)
    #   mag        - qmag(n) value of the change
    #   f          - One or more groups
    #   g          - One or more groups

    typemethod hrel {parmdict} {
        dict with parmdict {}

        set fdict [dict create \
            dtype    CURSE     \
            curse_id $curse_id \
            atype    hrel      \
            mode     $mode     \
            mag      $mag      \
            f        $f        \
            g        $g        ]

            driver::CURSE assess $fdict

        return
    }

    # vrel parmdict
    #
    # Causes an assessment vertical relationship among
    # group(s).
    #
    # parmdict:
    #   curse_id   - ID of the CURSE causing the change
    #   mode       - P (persistent) or T (transient)
    #   mag        - qmag(n) value of the change
    #   g          - One or more groups
    #   a          - One or more actors

    typemethod vrel {parmdict} {
        dict with parmdict {}

        set fdict [dict create  \
            dtype    CURSE      \
            curse_id $curse_id  \
            atype    vrel       \
            mode     $mode      \
            mag      $mag       \
            g        $g         \
            a        $a         ]

            driver::CURSE assess $fdict

        return
    }

    # sat parmdict
    #
    # Causes an assessment of satsifaction change of
    # group(s) with a concern
    #
    # parmdict:
    #   curse_id   - ID of the CURSE causing the change
    #   mode       - P (persistent) or T (transient)
    #   mag        - qmag(n) value of the change
    #   g          - One or more groups
    #   c          - AUT, SFT, CUL or QOL

    typemethod sat {parmdict} {
        dict with parmdict {}

        set fdict [dict create \
            dtype    CURSE     \
            curse_id $curse_id \
            atype    sat       \
            mode     $mode     \
            mag      $mag      \
            c        $c        \
            g        $g        ]

        driver::CURSE assess $fdict

        return
    }

    # coop parmdict
    #
    # Causes an assessment of cooperation change of 
    # CIV group(s) with FRC groups(s)
    #
    # parmdict:
    #   curse_id   - ID of the CURSE causing the change
    #   mode       - P (persistent) or T (transient)
    #   mag        - qmag(n) value of the change
    #   f          - One or more CIV groups
    #   g          - One or more FRC groups

    typemethod coop {parmdict} {
        dict with parmdict {}

        set fdict [dict create \
            dtype    CURSE     \
            curse_id $curse_id \
            atype    coop      \
            mode     $mode     \
            mag      $mag      \
            f        $f        \
            g        $g        ]

        driver::CURSE assess $fdict

        return
    }

    # RoleSpec curse_id
    #
    # curse_id
    #
    # Given a CURSE ID, this method figures out what each role defined
    # for that CURSE can contain in terms of particular groups and
    # actors.  The order in which this takes place, which matters, is 
    # from least restrictive roles to most restrictive.  For example, 
    # a role for an HREL inject can contain any group, but if that role 
    # is also used in a COOP inject, then it is restricted more.

    typemethod RoleSpec {curse_id} {
        # FIRST, if there's no curse specified, then nothing to
        # return
        if {$curse_id eq ""} {
            return {}
        }

        # NEXT, create the role spec dictionary
        set roleSpec [dict create]

        # NEXT, build up the rolespec based upon the injects associated
        # with this curse
        # HREL is the least restrictive, any group can belong to the
        # roles defined
        rdb eval {
            SELECT * FROM curse_injects 
            WHERE curse_id=$curse_id
            AND inject_type='HREL'
        } row {
            dict set roleSpec $row(f) [::group names]
            dict set roleSpec $row(g) [::group names]
        }

        # VREL is not any more restrictive group wise
        rdb eval {
            SELECT * FROM curse_injects
            WHERE curse_id=$curse_id
            AND inject_type='VREL'
        } row {
            dict set roleSpec $row(g) [::group names]
            dict set roleSpec $row(a) [::actor names]
        }

        # SAT restricts the group role to *only* civilians. If an HREL or
        # VREL inject has this role, then those injects will only be able
        # to contain civilian groups
        rdb eval {
            SELECT * FROM curse_injects
            WHERE curse_id=$curse_id
            AND inject_type='SAT'
        } row {
            dict set roleSpec $row(g) [::civgroup names]
        }

        # COOP restricts one role to civilians only and the other role to
        # forces only. Like SAT, if these roles appear in HREL or VREL, then
        # they will be restricted to the same groups
        rdb eval {
            SELECT * FROM curse_injects
            WHERE curse_id=$curse_id
            AND inject_type='COOP'
        } row {
            dict set roleSpec $row(f) [::civgroup names]
            dict set roleSpec $row(g) [::frcgroup names]
        }

        return $roleSpec
    }
}

# TACTIC:CURSE:CREATE
#
# Creates a new CURSE tactic.

order define TACTIC:CURSE:CREATE {
    title "Create Tactic: Cause a CURSE"

    options \
        -sendstates {PREP PAUSED}

    form {
        rcc "Owner:" -for owner
        text owner -context yes

        rcc "CURSE:" -for curse
        curse curse 

        rc "" -for roles -span 2
        roles roles -rolespeccmd {::tactic::CURSE RoleSpec $curse}

        rcc "Once Only?" -for once
        yesno once -defvalue 0

        rcc "Exec On Lock?" -for on_lock
        yesno on_lock -defvalue 0

        rcc "Priority:" -for priority
        enumlong priority -dictcmd {ePrioSched deflist} -defvalue bottom
    }
} {
    # FIRST, prepare and validate the parameters
    prepare owner    -toupper   -required -type {agent system}
    prepare curse    -toupper   -required -type {curse normal}
    prepare roles    -toupper   -required -type rolemap
    prepare once                -required -type boolean
    prepare on_lock             -required -type boolean
    prepare priority -tolower             -type ePrioSched

    returnOnError 

    validate roles {
        tactic::CURSE checkRolemap $parms(roles) $parms(curse)
    }

    returnOnError -final

    # NEXT, put tactic_type in the parmdict
    set parms(tactic_type) CURSE

    # NEXT, create the tactic
    setundo [tactic mutate create [array get parms]]
}

# TACTIC:CURSE:UPDATE
#
# Updates existing CURSE tactic.

order define TACTIC:CURSE:UPDATE {
    title "Update Tactic: CURSE"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        key tactic_id -context yes -table tactics_CURSE -keys tactic_id \
            -loadcmd {orderdialog keyload tactic_id *}

        rcc "Owner" -for owner
        disp owner

        rcc "CURSE" -for curse
        curse curse

        rc "" -for roles -span 2
        roles roles -rolespeccmd {::tactic::CURSE RoleSpec $curse}

        rcc "Once Only?" -for once
        yesno once

        rcc "Exec On Lock?" -for on_lock
        yesno on_lock
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type tactic
    prepare curse      -toupper  -type {curse normal}
    prepare roles      -toupper  -type rolemap
    prepare once                 -type boolean
    prepare on_lock              -type boolean

    returnOnError

    # NEXT, cross check
    validate roles {
        set curse [rdb onecolumn {
                      SELECT curse FROM tactics_CURSE 
                      WHERE tactic_id=$parms(tactic_id)
                  }]

        tactic::CURSE checkRolemap $parms(roles) $curse
    }

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType CURSE $parms(tactic_id) }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}



