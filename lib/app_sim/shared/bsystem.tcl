#-----------------------------------------------------------------------
# TITLE:
#    bsystem.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n) Belief Systems
#
#    This module creates the mam(n) instance that contains and 
#    computes Athena's belief systems, and also contains the relevant
#    orders.  Note that there are no mutators defined in this module;
#    the mam(n) add, configure, and delete subcommands serve this
#    purpose.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# bsystem ensemble

snit::type bsystem {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Components

    typecomponent mam       ;# The mam(n) instance.
    typecomponent updater   ;# The lazy updater

    #-------------------------------------------------------------------
    # Type Variables

    # info array
    #
    # autocalc - Flag; if 1, recalculate affinites on each order.
    
    typevariable info -array {
        autocalc 1
    }



    #-------------------------------------------------------------------
    # Singleton Initializer

    # init
    #
    # Initializes the simulation proper, to the extent that this can
    # be done at application initialization.  True initialization
    # happens when scenario preparation is locked, when 
    # the simulation state moves from PREP to PAUSED.

    typemethod init {} {
        log normal bsystem "init"

        # FIRST, create a MAM; arrange for it to clear undo info
        # before the scenario is saved.
        set mam [mam ${type}::mam \
                     -rdb ::rdb]

        # NEXT, create a lazyupdater to recompute affinities
        set updater [lazyupdater ${type}::updater \
                         -command [list $mam compute] \
                         -delay   1]

        notifier bind ::scenario <Saving> ::bsystem [list $mam edit reset]

        log normal bsystem "init complete"
    }

    # start
    #
    # Ensures that affinities have been computed on scenario lock.

    typemethod start {} {
        $mam compute
    }

    # lazycompute 
    #
    # Schedules a lazy recomputation of affinities unless autocalc
    # is turned off.
    
    typemethod lazycompute {} {
        if {$info(autocalc)} {
            $updater update
        }
    }

    # compute
    #
    # Forces a recalc.

    typemethod compute {} {
        $mam compute
    }

    #-------------------------------------------------------------------
    # Public Typemethods

    delegate typemethod {entity *} to mam using {%c entity %m}
    delegate typemethod {topic *}  to mam using {%c topic %m}
    delegate typemethod {belief *} to mam using {%c belief %m}
    delegate typemethod *          to mam

    # autocalc
    #
    # Returns the value of the autocalc flag.

    typemethod autocalc {} {
        return $info(autocalc)
    }

    # autocalc_var
    #
    # Returns the name of the auto-calc flag variable.  Setting this
    # flag will change the auto-calc behavior for future orders.

    typemethod autocalc_var {} {
        return ${type}::info(autocalc)
    }

    # entity validate eid
    #
    # eid - An entity ID
    #
    # Validates the entity ID.

    typemethod {entity validate} {eid} {
        set ids [$mam entity names]

        if {$eid ni $ids} {
            if {[llength $ids] == 0} {
                return -code error -errorcode INVALID \
                    "Invalid entity, none are defined"
            } else {
                return -code error -errorcode INVALID \
                    "Invalid entity, should be one of: [join $ids {, }]"
            }
        }

        return $eid
    }

    # topic validate tid
    #
    # tid - A topic ID
    #
    # Validates the topic ID.

    typemethod {topic validate} {tid} {
        set ids [$mam topic names]

        if {$tid ni $ids} {
            if {[llength $ids] == 0} {
                return -code error -errorcode INVALID \
                    "Invalid topic, none are defined"
            } else {
                return -code error -errorcode INVALID \
                    "Invalid topic, should be one of: [join $ids {, }]"
            }
        }

        return $tid
    }

    # belief validate id
    #
    # id - An {eid tid} pair
    #
    # Validates the belief ID.

    typemethod {belief validate} {id} {
        lassign $id eid tid

        set ids [$mam entity names]

        if {$eid ni $ids} {
            if {[llength $ids] == 0} {
                return -code error -errorcode INVALID \
                    "Invalid entity, none are defined"
            } else {
                return -code error -errorcode INVALID \
                    "Invalid entity, should be one of: [join $ids {, }]"
            }
        }

        $type topic validate $tid

        return $id
    }

    #-------------------------------------------------------------------
    # Order Helpers

    # ParmsToOptions names 
    #
    # names - A list of parameter names
    #
    # Returns an option/value list for the named parameters given the
    # caller's "parms" array.  The option names are constructed by
    # adding a "-" prefix to each parameter name.

    proc ParmsToOptions {names} {
        upvar 1 parms parms

        foreach parm $names {
            if {$parms($parm) ne ""} {
                lappend result -$parm $parms($parm)
            }
        }

        return $result
    }

    # MamUndo
    #
    # Undoes the last operation, and re-computed.
    
    proc MamUndo {} {
        $mam edit undo
        $mam compute
    }
}

#-----------------------------------------------------------------------
# BSystem Orders

# BSYSTEM:PLAYBOX:UPDATE
#
# Updates playbox-wide parameters
#
# TBD: It would be nice to populate the gamma parameter from the RDB,
# but there's no good way to do it using a -loadcmd.  We need an
# order option, -entercmd, that can modify the parmdict given with
# [order enter].


order define BSYSTEM:PLAYBOX:UPDATE {
    title "Update Playbox-wide Belief System Parameters"

    options -sendstates PREP

    form {
        # NOTE: dialog is not used
        rcc "Playbox Commonality:" -for gamma
        text gamma
    }
} {
    # FIRST, prepare and validate the parameters
    prepare gamma  -required -type ::simlib::rmagnitude

    returnOnError -final

    # NEXT, save the parameter value.
    bsystem playbox configure \
        -gamma $parms(gamma)
    bsystem lazycompute

    setundo [list ::bsystem::MamUndo]
}

# BSYSTEM:ENTITY:UPDATE
#
# Updates entity parameters

order define BSYSTEM:ENTITY:UPDATE {
    title "Update Belief System Entity"

    options -sendstates PREP

    form {
        # NOTE: Form is not used.
        rcc "Entity:" -for eid
        key eid -table mam_entity -keys eid

        rcc "Commonality Fraction:" -for commonality
        text commonality 
    }
} {
    # FIRST, prepare and validate the parameters
    prepare eid          -toupper -required -type {bsystem entity}
    prepare commonality           -required -type ::simlib::rfraction

    returnOnError -final

    # NEXT, save the parameter value.
    bsystem entity configure $parms(eid) \
        -commonality $parms(commonality)
    bsystem lazycompute

    setundo [list ::bsystem::MamUndo]
}


# BSYSTEM:TOPIC:CREATE
#
# Creates a new belief system topic.

order define BSYSTEM:TOPIC:CREATE {
    title "Create Belief System Topic"

    options \
        -sendstates PREP

    form {
        rcc "Topic ID:" -for tid
        text tid
        
        rcc "Title:" -for title
        text title -width 40

        rcc "Affinity?" -for affinity
        yesno affinity -defvalue yes
    }
} {
    # FIRST, prepare and validate the parameters
    prepare tid       -toupper   -unused -required -type ident
    prepare title     -normalize         -required
    prepare affinity  -toupper           -required -type boolean

    returnOnError -final

    # NEXT, create the topic
    bsystem topic add $parms(tid)    \
        -title     $parms(title)     \
        -affinity  $parms(affinity)
    bsystem lazycompute

    setundo [list ::bsystem::MamUndo]
}

# BSYSTEM:TOPIC:DELETE
#
# Deletes a belief system topic.

order define BSYSTEM:TOPIC:DELETE {
    title "Delete Belief System Topic"
    options \
        -sendstates PREP

    form { 
        # TBD: Form isn't used.
        rcc "Topic:" -for tid
        key tid -table mam_topic -keys tid
    }
} {
    # FIRST, prepare the parameters
    prepare tid -required -type {bsystem topic}

    returnOnError -final

    # NEXT, make sure the user knows what he is getting into.

    if {[sender] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     BSYSTEM:TOPIC:DELETE             \
                        -ignoredefault ok                               \
                        -parent        [app topwin]                     \
                        -message       [normalize {
                            Are you sure you really want to delete this 
                            topic and all of the beliefs that depend 
                            upon it?
                        }]]

        if {$answer eq "cancel"} {
            cancel
        }
    }

    # NEXT, Delete the topic.
    bsystem topic delete $parms(tid)
    bsystem lazycompute

    setundo [list ::bsystem::MamUndo]
}

# BSYSTEM:TOPIC:UPDATE
#
# Updates an existing topic

order define BSYSTEM:TOPIC:UPDATE {
    title "Update Belief System Topic"
    options -sendstates PREP

    form {
        rcc "Topic:" -for tid
        key tid -table mam_topic -keys tid \
            -loadcmd {orderdialog keyload id *}
       
        rcc "Title:" -for title
        text title -width 40
        
        rcc "Affinity?" -for affinity
        yesno affinity
    }
} {
    # FIRST, prepare the parameters
    prepare tid       -toupper    -required -type {bsystem topic}
    prepare title     -normalize  
    prepare affinity  -toupper              -type boolean

    returnOnError -final

    # NEXT, modify the group.
    set opts [bsystem::ParmsToOptions {title affinity}]

    bsystem topic configure $parms(tid) {*}$opts
    bsystem lazycompute

    setundo [list ::bsystem::MamUndo]
}


# BSYSTEM:BELIEF:UPDATE
#
# Updates an existing belief.

order define BSYSTEM:BELIEF:UPDATE {
    title "Update Belief"
    options -sendstates PREP

    form {
        # NOTE: dialog is not used.
        rcc "Select Belief:" -for id
        key id -table gui_mam_belief -keys {eid tid} \
            -loadcmd {orderdialog keyload id *}

        rcc "Position:" -for position
        text position

        rcc "Emphasis is On:" -for emphasis
        text emphasis

    }
} {
    # FIRST, prepare the parameters
    prepare id        -toupper -required -type {bsystem belief}
    prepare position  -type qposition  -xform {qposition value}
    prepare emphasis  -type qemphasis  -xform {qemphasis value}

    returnOnError -final

    # NEXT, modify the group.
    set opts [bsystem::ParmsToOptions {position emphasis}]

    bsystem belief configure {*}$parms(id) {*}$opts
    bsystem lazycompute

    setundo [list ::bsystem::MamUndo]
}



