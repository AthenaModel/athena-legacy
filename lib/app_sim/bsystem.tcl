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

    typecomponent mam    ;# The mam(n) instance.

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

        # FIRIST, create a MAM; arrange for it to clear undo info
        # before the scenario is saved.
        set mam [mam ${type}::mam \
                     -rdb ::rdb]

        notifier bind ::scenario <Saving> ::bsystem [list $mam edit reset]

        log normal bsystem "init complete"
    }

    #-------------------------------------------------------------------
    # Public Typemethods

    delegate typemethod *          to mam
    delegate typemethod {topic *}  to mam using {%c topic %m}
    delegate typemethod {belief *} to mam using {%c belief %m}

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

# BSYSTEM:TOPIC:CREATE
#
# Creates a new belief system topic.

order define BSYSTEM:TOPIC:CREATE {
    title "Create Belief System Topic"

    options \
        -sendstates PREP

    parm tid       text   "Topic ID"
    parm title     text   "Title"
    parm relevance enum   "Relevant?"  -enumtype eyesno \
                                       -defval   YES
} {
    # FIRST, prepare and validate the parameters
    prepare tid       -toupper   -unused -required -type ident
    prepare title     -normalize         -required
    prepare relevance -toupper           -required -type boolean

    returnOnError -final

    # NEXT, create the topic
    bsystem topic add $parms(tid)    \
        -title     $parms(title)     \
        -relevance $parms(relevance)
    bsystem compute

    setundo [list ::bsystem::MamUndo]
}

# BSYSTEM:TOPIC:DELETE
#
# Deletes a belief system topic.

order define BSYSTEM:TOPIC:DELETE {
    title "Delete Belief System Topic"
    options \
        -sendstates PREP

    parm tid   key  "Topic" -table mam_topic -keys tid
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
    bsystem compute

    setundo [list ::bsystem::MamUndo]
}

# BSYSTEM:TOPIC:UPDATE
#
# Updates an existing topic

order define BSYSTEM:TOPIC:UPDATE {
    title "Update Belief System Topic"
    options -sendstates PREP \
        -refreshcmd {orderdialog refreshForKey tid *}

    parm tid       key   "Select Topic" -table gui_mam_topic -keys tid
    parm title     text  "Title"
    parm relevance enum  "Relevant?"    -enumtype eyesno
} {
    # FIRST, prepare the parameters
    prepare tid       -toupper    -required -type {bsystem topic}
    prepare title     -normalize  
    prepare relevance -toupper              -type boolean

    returnOnError -final

    # NEXT, modify the group.
    set opts [bsystem::ParmsToOptions {title relevance}]

    bsystem topic configure $parms(tid) {*}$opts
    bsystem compute

    setundo [list ::bsystem::MamUndo]
}


# BSYSTEM:BELIEF:UPDATE
#
# Updates an existing belief.

order define BSYSTEM:BELIEF:UPDATE {
    title "Update Belief"
    options -sendstates PREP \
        -refreshcmd {orderdialog refreshForKey bid *}

    parm id        key   "Select Belief" -table gui_mam_belief \
                                         -keys  {eid tid}
    parm position  text  "Position"
    parm tolerance text  "Tolerance"
} {
    # FIRST, prepare the parameters
    prepare id        -toupper -required -type {bsystem belief}
    prepare position  -type qposition  -xform {qposition value}
    prepare tolerance -type qtolerance -xform {qtolerance value}

    returnOnError -final

    # NEXT, modify the group.
    set opts [bsystem::ParmsToOptions {position tolerance}]

    bsystem belief configure {*}$parms(id) {*}$opts
    bsystem compute

    setundo [list ::bsystem::MamUndo]
}



