#-----------------------------------------------------------------------
# TITLE:
#    iom.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Info Operations Message (IOM) manager
#
#    This module is responsible for managing messages and the operations
#    upon them.  As such, it is a type ensemble.
#
#-----------------------------------------------------------------------

snit::type iom {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.

    # names
    #
    # Returns the list of IOM IDs

    typemethod names {} {
        set names [rdb eval {
            SELECT iom_id FROM ioms 
        }]
    }

    # validate iom_id
    #
    # iom_id   - Possibly, an IOM ID
    #
    # Validates an IOM ID

    typemethod validate {iom_id} {
        if {![rdb exists {
            SELECT * FROM ioms WHERE iom_id = $iom_id
        }]} {
            set names [join [iom names] ", "]

            if {$names ne ""} {
                set msg "should be one of: $names"
            } else {
                set msg "none are defined"
            }

            return -code error -errorcode INVALID \
                "Invalid IOM, $msg"
        }

        return $iom_id
    }

    # exists iom_id
    #
    # iom_id - A message ID.
    #
    # Returns 1 if there's such a message, and 0 otherwise.

    typemethod exists {iom_id} {
        rdb exists {
            SELECT * FROM ioms WHERE iom_id=$iom_id
        }
    }

    # get id ?parm?
    #
    # iom_id   - An iom_id
    # parm     - An ioms column name
    #
    # Retrieves a row dictionary, or a particular column value, from
    # ioms.

    typemethod get {iom_id {parm ""}} {
        # FIRST, get the data
        rdb eval {
            SELECT * FROM ioms 
            WHERE iom_id=$iom_id
        } row {
            if {$parm eq ""} {
                unset row(*)
                return [array get row]
            } else {
                return $row($parm)
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
    # parmdict  - A dictionary of IOM parms
    #
    #    iom_id   - The IOM's ID
    #    longname - The IOM's long name
    #    hook_id  - The hook_id, or ""
    #
    # Creates an IOM given the parms, which are presumed to be
    # valid.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            # FIRST, Put the IOM in the database
            rdb eval {
                INSERT INTO 
                ioms(iom_id, 
                     longname,
                     hook_id)
                VALUES($iom_id, 
                       $longname,
                       nullif($hook_id,'')); 
            }

            # NEXT, Return the undo command
            return [list rdb delete ioms "iom_id='$iom_id'"]
        }
    }

    # mutate delete iom_id
    #
    # iom_id   - An IOM ID
    #
    # Deletes the message, including all references.

    typemethod {mutate delete} {iom_id} {
        # FIRST, Delete the IOM, grabbing the undo information
        set data [rdb delete -grab ioms {iom_id=$iom_id}]
        
        # NEXT, Return the undo script
        return [list rdb ungrab $data]
    }

    # mutate update parmdict
    #
    # parmdict   - A dictionary of IOM parms
    #
    #    iom_id   - An IOM ID
    #    longname - A new long name, or ""
    #    hook_id  - A new hook_id, or ""
    #
    # Updates an IOM given the parms, which are presumed to be
    # valid.  An empty hook_id remains NULL.

    typemethod {mutate update} {parmdict} {
        dict with parmdict {
            # FIRST, grab the data that might change.
            set data [rdb grab ioms {iom_id=$iom_id}]

            # NEXT, Update the record
            rdb eval {
                UPDATE ioms
                SET longname = nonempty($longname, longname),
                    hook_id  = nullif(nonempty($hook_id, hook_id), '')
                WHERE iom_id=$iom_id;
            } 

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
    }
}    

#-------------------------------------------------------------------
# Orders: IOM:*

# IOM:CREATE
#
# Creates a new IOM

order define IOM:CREATE {
    title "Create Info Ops Message"
    
    options \
        -sendstates PREP

    parm iom_id      text  "Message ID"
    parm longname    text  "Description"      -width 60
    parm hook_id     text  "Semantic Hook"
    # TBD: should be enum with -enumtype hook.
} {
    # FIRST, prepare and validate the parameters
    prepare iom_id      -toupper   -required -unused -type ident
    prepare longname    -normalize
    # prepare hook_id     -toupper                     -type hook

    # TBD: There are no hooks yet.  We'll add this in when there are.

    returnOnError -final

    # NEXT, If longname is "", defaults to ID.
    if {$parms(longname) eq ""} {
        set parms(longname) $parms(iom_id)
    }

    # NEXT, create the message.
    lappend undo [iom mutate create [array get parms]]

    setundo [join $undo \n]
}

# IOM:DELETE
#
# Deletes an IOM and its payloads.

order define IOM:DELETE {
    title "Delete Info Ops Message"
    options -sendstates PREP

    parm iom_id  key "Message ID" -table ioms -keys iom_id
} {
    # FIRST, prepare the parameters
    prepare iom_id -toupper -required -type iom

    returnOnError -final

    # NEXT, make sure the user knows what he is getting into.

    if {[sender] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     IOM:DELETE                    \
                        -ignoredefault ok                               \
                        -parent        [app topwin]                     \
                        -message       [normalize {
                            Are you sure you really want to delete this 
                            Info Ops Message, along with all of its payloads?
                        }]]

        if {$answer eq "cancel"} {
            cancel
        }
    }

    # NEXT, Delete the record and dependent entities
    lappend undo [iom mutate delete $parms(iom_id)]

    setundo [join $undo \n]
}


# IOM:UPDATE
#
# Updates an existing IOM.

order define IOM:UPDATE {
    title "Update Info Ops Message"
    options -sendstates PREP \
        -refreshcmd {orderdialog refreshForKey iom_id *}

    parm iom_id    key   "Select Message"  -table ioms -keys iom_id 
    parm longname  text  "Description"     -width 60
    parm hook_id   text  "Semantic Hook"
    # TBD: should be enum with -enumtype hook.
} {
    # FIRST, prepare the parameters
    prepare iom_id      -toupper   -required -type iom
    prepare longname    -normalize
    # prepare hook_id     -toupper           -type hook

    # TBD: There are no hooks yet.  We'll add this in when there are.

    returnOnError -final

    # NEXT, modify the message.
    setundo [iom mutate update [array get parms]]
}


