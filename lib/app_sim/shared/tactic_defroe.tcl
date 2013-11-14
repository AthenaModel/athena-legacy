#-----------------------------------------------------------------------
# TITLE:
#    tactic_defroe.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Mark II Tactic, DEFROE
#
#    Every uniformed force group has a defending ROE of 
#    FIRE_BACK_IF_PRESSED by default.  The default is overridden by 
#    the DEFROE tactic, which inserts an entry into the defroe_ng table
#    on execution.  The override lasts until the next strategy execution 
#    tock.
#
#    The tactic never executes on lock.
# 
#-----------------------------------------------------------------------

# FIRST, create the class.
tactic define DEFROE "Defensive ROE" {actor} {
    #-------------------------------------------------------------------
    # Type Methods

    # reset
    #
    # Resets all defending ROEs at the beginning of the tock.

    typemethod reset {} {
        rdb eval { DELETE FROM defroe_ng }
    }
    

    #-------------------------------------------------------------------
    # Instance Variables

    # Editable Parameters
    variable g           ;# The defending uniformed force group, owned
                          # by the agent.
    variable n           ;# The neighborhood in which g is defending.
    variable roe         ;# The ROE, edefroeuf


    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Initialize as a tactic bean.
        next

        # NEXT, Initialize state variables
        set g   ""
        set n   ""
        set roe FIRE_BACK_IF_PRESSED

        # NEXT, Initial state is invalid (no g, n)
        my set state invalid

        # Save the options
        my configure {*}$args
    }

    #-------------------------------------------------------------------
    # Operations

    # No ObligateResources method is required; the ROE uses no resources.

    method SanityCheck {errdict} {
        # Check g
        if {$g eq ""} {
            dict set errdict g "No group selected."
        } elseif {$g ni [group ownedby [my agent]]} {
            dict set errdict g \
                "Force group \"$g\" is not owned by [my agent]."
        } elseif {$g ni [frcgroup uniformed names]} {
            dict set errdict g \
                "Force group \"$g\" is not a uniformed force group."
        }

        # Check n
        if {[llength $n] == 0} {
            dict set errdict n \
                "No neighborhood selected."
        } elseif {$n ni [nbhood names]} {
            dict set errdict n \
                "Non-existent neighborhood: \"$n\""
        }

        return [next $errdict]
    }

    method narrative {} {
        set s(g) [link make group  $g]
        set s(n) [link make nbhood $n]

        return "Group $s(g) defends in $s(n) with ROE $roe"
    }

    method execute {} {
        rdb eval {
            INSERT OR REPLACE INTO defroe_ng(n, g, roe)
            VALUES($n, $g, $roe);
        }

        sigevent log 2 tactic "
            DEFROE: Group {group:$g} defends in {nbhood:$n} 
            with ROE $roe.
        " [my agent] $n $g
    }
}

#-----------------------------------------------------------------------
# TACTIC:* orders

# TACTIC:DEFROE
#
# Updates existing DEFROE tactic.

order define TACTIC:DEFROE {
    title "Tactic: Defensive ROE"
    options -sendstates {PREP PAUSED}

    form {
        rcc "Tactic ID" -for tactic_id
        text tactic_id -context yes \
            -loadcmd {beanload}

        rcc "Group:" -for g
        enum g -listcmd {tactic groupsOwnedAndUniformed $tactic_id}

        rcc "Neighborhood:" -for n
        nbhood n

        rcc "Defending ROE:" -for roe
        enumlong roe -dictcmd {edefroeuf deflist}
    }
} {
    # FIRST, prepare the parameters
    prepare tactic_id  -required -type tactic::DEFROE
    prepare g          -toupper  -type ident
    prepare n          -toupper  -type ident
    prepare roe        -toupper  -type edefroeuf
 
    returnOnError -final

    # NEXT, update the tactic, saving the undo script, and clearing
    # historical state data.
    set tactic [tactic get $parms(tactic_id)]
    set undo [$tactic update_ {g n roe} [array get parms]]

    # NEXT, save the undo script
    setundo $undo
}





