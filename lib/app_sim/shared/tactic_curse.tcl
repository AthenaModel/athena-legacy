#-----------------------------------------------------------------------
# TITLE:
#    tactic_curse.tcl
#
# AUTHOR:
#    Dave Hanks
#
# DESCRIPTION:
#    athena_sim(1): CURSE(TBD) tactic
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

tactic type define CURSE {curse once on_lock} system {
    #-------------------------------------------------------------------
    # Type Variables


    #-------------------------------------------------------------------
    # Public Methods

    # reset
    # 

    typemethod reset {} {
    }

    # assess
    #
    # Assesses the attitude effects of all pending broadcasts by
    # calling the IOM rule set for each pending broadcast.
    #
    # This command is called at the end of strategy execution, once
    # all actors have made their decisions and CAP access is clear.

    typemethod assess {} {
    }

    #-------------------------------------------------------------------
    # tactic(i) subcommands
    #
    # See the tactic(i) man page for the signature and general
    # description of each subcommand.

    typemethod narrative {tdict} {
        dict with tdict {}
        set narr [curse get $curse longname]

        set itypes [rdb eval {
            SELECT inject_type FROM curse_injects
            WHERE curse_id=$curse
        }]


        return "$narr ($curse) with inject types: [join $itypes {, }]"
    }

    typemethod check {tdict} {
    }

    typemethod execute {tdict} {
    }

    # RoleSpec curse_id
    #
    # curse_id
    #
    # Given a CURSE ID, this method figures out what each role defined
    # for that CURSE can contain in terms of particular groups and
    # actors.  The order in which this takes place is from least
    # restrictive roles to most restrictive.  Thus, a role for an HREL
    # inject can contain any group, but if that role is also used in
    # a COOP inject, then it is restricted to just those groups that
    # make sense.

    typemethod RoleSpec {curse_id} {
        # FIRST, if there's no curse specified, then nothing to
        # return
        if {$curse_id eq ""} {
            return {}
        }

        # NEXT, create the role spec dictionary and fill in with
        # default empty values
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

        # VREL, is not any more restrictive, but is the only inject
        # with an actors role
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
    prepare curse               -required -type curse
    prepare once                -required -type boolean
    prepare on_lock             -required -type boolean
    prepare priority -tolower             -type ePrioSched

    validate roles {
        if {![curse validRoles $parms(curse) $parms(roles)]} {
            reject roles "Roles $parms(roles) are not valid for $parms(curse)."
        }
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
        disp curse

        rc "" -for roles -span 2
        roles roles -rolespeccmd {::tactico::CURSE RoleSpec $curse}

        rcc "Once Only?" -for once
        yesno once

        rcc "Exec On Lock?" -for on_lock
        yesno on_lock
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type tactic
    prepare roles                -type roles
    prepare once                 -type boolean
    prepare on_lock              -type boolean

    returnOnError

    # NEXT, make sure this is the right kind of tactic
    validate tactic_id { tactic RequireType CURSE $parms(tactic_id) }

    returnOnError

    # NEXT, make sure the role(s) to group(s) mapping is good
    validate roles {
        if {![curse validRoles $parms(curse) $parms(roles)]} {
            reject roles "Roles $parms(roles) are not valid for $parms(curse)."
        }
    }

    returnOnError -final

    # NEXT, modify the tactic
    setundo [tactic mutate update [array get parms]]
}



