#-----------------------------------------------------------------------
# TITLE:
#    condition_control.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): CONTROL Condition Type Definition
#
#    See condition(i) for the condition interface requirements.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Condition: CONTROL(a,nlist)
#
# a     <= a
# list1 <= nlist
#
# Does actor a control all of the neighborhoods in nlist?

condition type define CONTROL {a list1} {
    typemethod narrative {cdict} {
        dict with cdict {
            if {[llength $list1] == 1} {
                return "Actor $a controls neighborhood [lindex $list1 0]."
            } else {
                return "Actor $a controls neighborhoods [join $list1 {, }]."
            }
        }
    }

    typemethod check {cdict} {
        set result [list]
        dict with cdict {
            if {$a ni [actor names]} {
                lappend result "Actor $a no longer exists."
            }

            foreach n $list1 {
                if {$n ni [nbhood names]} {
                    lappend result "Neighborhood $n no longer exists."
                }
            }
        }

        return [join $result " "]
    }

    typemethod eval {cdict} {
        dict with cdict {
            # Get the number of neighborhoods in the list that the
            # actor does NOT control.
            set count [rdb onecolumn "
                SELECT count(n)
                FROM control_n
                WHERE n IN ('[join $list1 ',']')
                AND (controller IS NULL OR controller != \$a)
            "]

            return [expr {$count == 0}]
        }
    }
}


# CONDITION:CONTROL:CREATE
#
# Creates a new CONTROL condition.

order define CONDITION:CONTROL:CREATE {
    title "Create Condition: Control"

    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic/Goal ID:" -for cc_id
        condcc cc_id

        rcc "" 
        label { This condition is met when }

        rcc "Actor:" -for a
        actor a
        label "controls"

        rcc "Neighborhoods:" -for list1
        nlist list1
    }
} {
    # FIRST, prepare and validate the parameters
    prepare cc_id                -required -type   cond_collection
    prepare a          -toupper  -required -type   actor
    prepare list1      -toupper  -required -listof nbhood

    returnOnError -final

    # NEXT, put condition_type in the parmdict
    set parms(condition_type) CONTROL

    # NEXT, create the condition
    setundo [condition mutate create [array get parms]]
}

# CONDITION:CONTROL:UPDATE
#
# Updates existing CONTROL condition.

order define CONDITION:CONTROL:UPDATE {
    title "Update Condition: Control"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Condition ID:" -for condition_id
        cond condition_id

        rcc "" 
        label { This condition is met when }

        rcc "Actor:" -for a
        actor a
        label "controls"

        rcc "Neighborhoods:" -for list1
        nlist list1
    }
} {
    # FIRST, prepare the parameters
    prepare condition_id  -required           -type condition
    prepare a                       -toupper  -type actor
    prepare list1                   -toupper  -listof nbhood

    returnOnError

    # NEXT, make sure this is the right kind of condition
    validate condition_id { 
        condition RequireType CONTROL $parms(condition_id)  
    }

    returnOnError -final

    # NEXT, modify the condition
    setundo [condition mutate update [array get parms]]
}




