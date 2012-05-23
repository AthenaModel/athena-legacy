#-----------------------------------------------------------------------
# TITLE:
#    hook.tcl
#
# AUTHOR:
#    Dave Hanks
#
# DESCRIPTION:
#    athena_sim(1): Semantic Hook Manager
#
#    This module is responsible for managing semantic hooks and
#    the operations on them. As such, it is a type ensemble.
#    Semantic hooks are sent as part tactics that employ information
#    operations.
#
#-----------------------------------------------------------------------

snit::type hook {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.

    # names
    #
    # Returns a list of hook short names, also known as the
    # hook ID.

    typemethod names {} {
        set names [rdb eval {
            SELECT hook_id FROM hooks ORDER BY hook_id
        }]
    }

    # validate hook_id
    #
    # hook_id - Possibly, a hook ID.
    #
    # Validates a hook ID

    typemethod validate {hook_id} {
        set ids [rdb eval {SELECT hook_id FROM hooks}]

        if {$hook_id ni $ids} {
            set valid [join $ids ", "]

            if {$valid ne ""} {
                set msg "should be one of: $valid"
            } else {
                set msg "none are defined"
            }

            return -code error -errorcode INVALID \
                "Invalid hook ID, $msg"
        }

        return $hook_id
    }

    # topic validate id
    #
    # id   - Possibly a hook/topic id pair
    #
    # Validates a hook/topic pair  

    typemethod {topic validate} {id} {
        lassign $id hook_id topic_id

        # FIRST, see if the individual IDs are okay
        set hook_id  [hook validate $hook_id]
        set topic_id [bsystem topic validate $topic_id]

        # NEXT, check that they exist together in the hook_topics 
        # table
        set ids [rdb eval {SELECT id FROM hook_topics_view}]

        if {$id ni $ids} {
            set valid [join $ids ", "]

            if {$valid ne ""} {
                set msg "should be one of: $valid"
            } else {
                set msg "none are defined"
            }

            return -code error -errorcode INVALID \
                "Invalid hook/topic pair, $msg"
        }

        return $id
    }

    # topic exists id
    #
    # id   - Possibly a hook/topic id pair
    #
    # Returns 1 if the pair exists, 0 otherwise

    typemethod {topic exists} {id} {
        lassign $id hook_id topic_id

        # FIRST, see if we have an instance of one
        set exists [rdb exists {
            SELECT * FROM hook_topics
            WHERE hook_id=$hook_id AND topic_id=$topic_id
        }]

        return $exists
    }

    # get hook_id ?parm?
    #
    # hook_id    - A hook ID 
    # parm       - A column in the hooks table
    #
    # Retrieves a row dictionary, or a particular column value, from
    # hooks.

    typemethod get {hook_id {parm ""}} {
        # FIRST, get the data
        rdb eval {SELECT * FROM hooks WHERE hook_id=$hook_id} row {
            if {$parm ne ""} {
                return $row($parm)
            } else {
                unset row(*)
                return [array get row]
            }
        }

        return ""
    }

    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the scenario in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # change cannot be undone, the mutator returns the empty string.

    # mutate create parmdict
    #
    # parmdict     A dictionary of hook parms
    #
    #    hook_id        The semantic hook's short name
    #    longname       The semantic hook's long name
    #
    # Creates a semantic hook given the parms, which are presumed to be
    # valid.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            # FIRST, Put the hook in the database
            rdb eval {
                INSERT INTO 
                hooks(hook_id,  
                      longname)
                VALUES($hook_id, 
                       $longname) 
            }

            # NEXT, Return undo command.
            return [mytypemethod mutate delete $hook_id]
        }
    }

    # mutate delete hook_id
    #
    # hook_id     A semantic hook ID
    #
    # Deletes the semantic hook.

    typemethod {mutate delete} {hook_id} {
        # FIRST, remove it from the database
        set data [rdb delete -grab hooks {hook_id=$hook_id}]

        # NEXT, return the undo script
        return [list rdb ungrab $data]
    }

    # mutate update parmdict
    #
    # parmdict     A dictionary of semantic hook parms
    #
    #    hook_id        A semantic hook short name
    #    longname       A new long name, or ""
    #
    # Updates a semantic hook given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        dict with parmdict {
            # FIRST, get the undo information
            set data [rdb grab hooks {hook_id=$hook_id}]

            # NEXT, Update the hook
            rdb eval {
                UPDATE hooks
                SET longname = nonempty($longname, longname)
                WHERE hook_id=$hook_id;
            } {}

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
    }

    # mutate topic create parmdict
    #
    # parmdict     A dictionary of hook/topic parms
    #
    #     hook_id    A hook
    #     topic_id   A mam(n) topic
    #     position   A qposition(n) value 
    #
    # Creates a hook/topic record upon which a semantic hook takes a 
    # position. Used as part of an Info Ops Message (IOM).

    typemethod {mutate topic create} {parmdict} {
        dict with parmdict {
            rdb eval {
                INSERT INTO 
                hook_topics(hook_id,
                            topic_id,
                            position)
                VALUES($hook_id,
                       $topic_id,
                       $position)
            }
            
            return \
                [mytypemethod mutate topic delete [list $hook_id $topic_id]]
        }
    }

    # mutate topic update parmdict
    #
    # parmdict    A dictionary of hook/topic parms
    #
    #    id       A hook/topic id pair that identifies the record
    #    position A qposition(n) value
    #
    # Updates the database with the supplied hook/topic pair to have the
    # provided position on the topic.

    typemethod {mutate topic update} {parmdict} {
        dict with parmdict {
            lassign $id hook_id topic_id
            set data [rdb grab \
                hook_topics {hook_id=$hook_id AND topic_id=$topic_id}]

            rdb eval {
                UPDATE hook_topics
                SET position = nonempty($position, position)
                WHERE hook_id=$hook_id AND topic_id=$topic_id
            }

            return [list rdb ungrab $data]
        }
    }

    # mutate topic delete id
    # 
    # id    The unique identifier for the hook/topic pair
    #
    # Removes the record from the database that contains the supplied
    # hook/topic pair

    typemethod {mutate topic delete} {id} {
        lassign $id hook_id topic_id

        set data [rdb delete \
            -grab hook_topics {hook_id=$hook_id AND topic_id=$topic_id}]

        return [list rdb ungrab $data]
    }

    typemethod refreshTopicCREATE {dlg fields fdict} {
        # Placeholder
    }
}

#-----------------------------------------------------------------------
# Orders: HOOK:*

# HOOK:CREATE
#
# Creates new semantic hooks.

order define HOOK:CREATE {
    title "Create Semantic Hook"

    options \
        -sendstates PREP

    parm hook_id      text  "Hook ID"
    parm longname     text  "Long Name"
} {
    # FIRST, prepare and validate the parameters
    prepare hook_id  -toupper -unused -required -type ident  
    prepare longname -normalize       -required 

    returnOnError -final

    # NEXT, If longname is "", defaults to ID.
    if {$parms(longname) eq ""} {
        set parms(longname) $parms(hook_id)
    }

    # NEXT, create the semantic hook
    setundo [hook mutate create [array get parms]]
}

# HOOK:DELETE
#
# Deletes semantic hooks

order define HOOK:DELETE {
    title "Delete Semantic Hook"
    options -sendstates PREP

    parm hook_id  key  "Hook ID" -table hooks -keys hook_id
} {
    # FIRST, prepare the parameters
    prepare hook_id -toupper -required -type hook

    returnOnError -final

    # NEXT, make sure the user knows what he is getting into.

    if {[sender] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     HOOK:DELETE                      \
                        -ignoredefault ok                               \
                        -parent        [app topwin]                     \
                        -message       [normalize {
                            Are you sure you
                            really want to delete this semantic hook 
                            and all hook topics that depend on it?
                        }]]

        if {$answer eq "cancel"} {
            cancel
        }
    }

    setundo [hook mutate delete $parms(hook_id)]
}


# HOOK:UPDATE
#
# Updates existing semantic hooks.

order define HOOK:UPDATE {
    title "Update Semantic Hook"
    options \
        -sendstates PREP                             \
        -refreshcmd {orderdialog refreshForKey hook_id *}

    parm hook_id      key    "Select Hook"    -table hooks -keys hook_id
    parm longname     text   "Long Name"
} {
    # FIRST, prepare the parameters
    prepare hook_id      -toupper   -required -type hook
    prepare longname     -normalize

    returnOnError -final

    # NEXT, modify the hook
    setundo [hook mutate update [array get parms]]
}

# HOOK:TOPIC:CREATE
#
# Creates a new semantic hook/topic pair

order define HOOK:TOPIC:CREATE {
    title "Create Semantic Hook Topic"

    options \
        -sendstates PREP \
        -refreshcmd {hook refreshTopicCREATE}

    parm hook_id    key  "Hook ID"   -table hooks -keys hook_id -context yes
    parm topic_id   enum "Topic ID"  -table mam_topic -keys tid
    parm position   text "Position"
} {
    prepare hook_id  -toupper -required -type hook
    prepare topic_id -toupper -required -type {bsystem topic}
    prepare position -toupper -required -type qposition 

    returnOnError 

    if {[hook topic exists [list $parms(hook_id) $parms(topic_id)]]} {
        reject id "Hook/Topic pair already exists"
    }

    returnOnError -final

    setundo [hook mutate topic create [array get parms]]
}

# HOOK:TOPIC:DELETE
#
# Removes a semantic hook topic from the database

order define HOOK:TOPIC:DELETE {
    title "Delete Semantic Hook Topic"

    options \
        -sendstates PREP
        
    parm id  key  "Hook/Topic"  -table gui_hook_topics   \
                                -keys {hook_id topic_id} \
                                -labels {"Of" "On"}
} {
    prepare id   -toupper -required -type {hook topic}

    returnOnError -final

    setundo [hook mutate topic delete $parms(id)]
}

# HOOK:TOPIC:UPDATE
#
# Updates an existing hook/topic pair

order define HOOK:TOPIC:UPDATE {
    title "Update Semantic Hook Topic"

    options \
        -sendstates PREP \
        -refreshcmd {::orderdialog refreshForKey id *}

    parm id key "Hook/Topic" -table gui_hook_topics    \
                             -keys  {hook_id topic_id} \
                             -labels {"Of" "On"}
    parm position text "Position"
} {
    prepare id       -toupper -required -type {hook topic}
    prepare position                    -type qposition

    returnOnError -final

    setundo [hook mutate topic update [array get parms]]
}

# HOOK:TOPIC:UPDATE:MULTI
#
# Updates multiple hook/topic pairs

order define HOOK:TOPIC:UPDATE:MULTI {
    title "Update Semantic Hook Topic (Multi)"

    options \
        -sendstates PREP \
        -refreshcmd {orderdialog refreshForMulti ids *}

        parm ids multi "IDs"   -table gui_hook_topics 

        parm position text "Position" 
} {
    prepare ids      -toupper -required -listof {hook topic}
    prepare position -toupper           -type   qposition

    returnOnError -final

    set undo [list]

    foreach parms(id) $parms(ids) {
        lappend undo [hook mutate topic update [array get parms]]

        setundo [join $undo \n]
    }
}



