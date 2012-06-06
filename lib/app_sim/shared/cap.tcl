#-----------------------------------------------------------------------
# TITLE:
#    cap.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Communications Asset Package (CAP) manager.
#
#    This module is responsible for managing CAPs and the operations
#    upon them.  As such, it is a type ensemble.
#
#-----------------------------------------------------------------------

snit::type cap {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.


    # names
    #
    # Returns the list of CAP names

    typemethod names {} {
        set names [rdb eval {
            SELECT k FROM caps 
        }]
    }


    # longnames
    #
    # Returns the list of CAP long names

    typemethod longnames {} {
        return [rdb eval {
            SELECT k || ': ' || longname FROM caps
        }]
    }

    # validate k
    #
    # k   - Possibly, a CAP short name.
    #
    # Validates a CAP short name

    typemethod validate {k} {
        if {![rdb exists {SELECT k FROM caps WHERE k=$k}]} {
            set names [join [cap names] ", "]

            if {$names ne ""} {
                set msg "should be one of: $names"
            } else {
                set msg "none are defined"
            }

            return -code error -errorcode INVALID \
                "Invalid CAP, $msg"
        }

        return $k
    }

    # exists k
    #
    # k - A CAP ID.
    #
    # Returns 1 if there's such a CAP, and 0 otherwise.

    typemethod exists {k} {
        rdb exists {
            SELECT * FROM caps WHERE k=$k
        }
    }

    # get id ?parm?
    #
    # k     - An k
    # parm  - An caps column name
    #
    # Retrieves a row dictionary, or a particular column value, from
    # caps.

    typemethod get {k {parm ""}} {
        # FIRST, get the data
        rdb eval {
            SELECT * FROM caps 
            WHERE k=$k
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

    # hasaccess k a
    #
    # k  - A CAP ID
    # a  - An actor ID
    #
    # Returns 1 if a has access to k, and 0 otherwise.  At the moment,
    # the actor has access only if it is the owner.

    typemethod hasaccess {k a} {
        expr {$a eq [$type get $k owner]}
    }
    
    # nbcov validate id
    #
    # id     A cap_kn ID, [list $k $n]
    #
    # Throws INVALID if id doesn't name a cap_kn_view record.

    typemethod {nbcov validate} {id} {
        lassign $id k n

        set k [cap validate $k]
        set n [nbhood validate $n]

        return [list $k $n]
    }

    # nbcov exists id
    #
    # id     A cap_kn ID, [list $k $n]
    #
    # Returns 1 if there's a record, and 0 otherwise.

    typemethod {nbcov exists} {id} {
        lassign $id k n

        rdb exists {
            SELECT * FROM cap_kn WHERE k=$k AND n=$n
        }
    }

    
    # pen validate id
    #
    # id     A cap_kg ID, [list $k $g]
    #
    # Throws INVALID if id doesn't name a cap_kg_view record.

    typemethod {pen validate} {id} {
        lassign $id k g

        set k [cap validate $k]
        set g [civgroup validate $g]

        return [list $k $g]
    }

    # pen exists id
    #
    # id     A cap_kg ID, [list $k $g]
    #
    # Returns 1 if there's a record, and 0 otherwise.

    typemethod {pen exists} {id} {
        lassign $id k g

        rdb exists {
            SELECT * FROM cap_kg WHERE k=$k AND g=$g
        }
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
    # parmdict  - A dictionary of CAP parms
    #
    #    k            - The CAP's ID
    #    longname     - The CAP's long name
    #    owner        - The CAP's owning actor
    #    capacity     - The CAP's capacity, 0.0 to 1.0
    #    cost         - The CAP's cost in $/message/week.
    #    nlist        - Neighborhoods with non-zero coverage.
    #    glist       - Civilian groups with non-zero penetration.
    #
    # Creates a CAP given the parms, which are presumed to be
    # valid.  Creating a CAP requires adding entries to the caps, 
    # cap_kn, and cap_kg tables.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            # FIRST, Put the CAP in the database
            rdb eval {
                INSERT INTO caps(k, longname, owner, capacity, cost)
                VALUES($k, 
                       $longname, 
                       nullif($owner,''), 
                       $capacity, 
                       $cost);
            }

            # NEXT, add the covered neighborhoods.  Coverage defaults to
            # 1.0.
            foreach n $nlist {
                rdb eval {
                    INSERT INTO cap_kn(k,n) VALUES($k,$n);
                }
            }

            # NEXT, add the group penetrations.  Penetration defaults to
            # 1.0.
            foreach g $glist {
                rdb eval {
                    INSERT INTO cap_kg(k,g) VALUES($k,$g);
                }
            }

            # NEXT, Return the undo command
            return [mytypemethod mutate delete $k]
        }
    }

    # mutate delete k
    #
    # k   - A CAP short name
    #
    # Deletes the CAP, including all references.

    typemethod {mutate delete} {k} {
        # FIRST, Delete the CAP, grabbing the undo information
        set data [rdb delete -grab caps {k=$k}]
        
        # NEXT, Return the undo script
        return [list rdb ungrab $data]
    }

    # mutate update parmdict
    #
    # parmdict   - A dictionary of CAP parms
    #
    #    k            - A CAP short name
    #    longname     - A new long name, or ""
    #    owner        - A new owning actor, or ""
    #    capacity     - A new capacity, or ""
    #    cost         - A new cost, or ""
    #
    # Updates a cap given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        dict with parmdict {
            # FIRST, grab the CAP data that might change.
            set data [rdb grab caps {k=$k}]

            # NEXT, Update the CAP
            rdb eval {
                UPDATE caps
                SET longname   = nonempty($longname,     longname),
                    owner      = nonempty($owner,        owner),
                    capacity   = nonempty($capacity,     capacity),
                    cost       = nonempty($cost,         cost)
                WHERE k=$k;
            } 

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
    }

    # mutate nbcov create parmdict
    #
    # parmdict  - A dictionary of cap_kn parms
    #
    #    id     - list {k n}
    #    nbcov  - The overridden neighborhood coverage
    #
    # Creates an nbcov record given the parms, which are presumed to be
    # valid.

    typemethod {mutate nbcov create} {parmdict} {
        dict with parmdict {
            lassign $id k n

            # FIRST, default nbcov to 1.0
            if {$nbcov eq ""} {
                set nbcov 1.0
            }

            # NEXT, Put the record into the database
            rdb eval {
                INSERT INTO 
                cap_kn(k,n,nbcov)
                VALUES($k, $n, $nbcov);
            }

            # NEXT, Return the undo command
            return [list rdb delete cap_kn "k='$k' AND n='$n'"]
        }
    }

    # mutate nbcov delete id
    #
    # id   - list {k n}
    #
    # Deletes the override.

    typemethod {mutate nbcov delete} {id} {
        lassign $id k n

        # FIRST, delete the records, grabbing the undo information
        set data [rdb delete -grab cap_kn {k=$k AND n=$n}]

        # NEXT, Return the undo script
        return [list rdb ungrab $data]
    }


    # mutate nbcov update parmdict
    #
    # parmdict   - A dictionary of cap_kn parms
    #
    #    id           - list {k n}
    #    nbcov        - A new neighborhood coverage, or ""
    #
    # Updates a cap_kn given the parms, which are presumed to be
    # valid.

    typemethod {mutate nbcov update} {parmdict} {
        dict with parmdict {
            lassign $id k n

            # FIRST, grab the data that might change.
            set data [rdb grab cap_kn {k=$k AND n=$n}]

            # NEXT, Update the cap_kn
            rdb eval {
                UPDATE cap_kn
                SET nbcov = nonempty($nbcov, nbcov)
                WHERE k=$k AND n=$n
            } 

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
    }

    # mutate pen create parmdict
    #
    # parmdict  - A dictionary of cap_kg parms
    #
    #    id     - list {k g}
    #    pen    - The overridden group penetration
    #
    # Creates a pen record given the parms, which are presumed to be
    # valid.

    typemethod {mutate pen create} {parmdict} {
        dict with parmdict {
            lassign $id k g

            # FIRST, default pen to 1.0
            if {$pen eq ""} {
                set pen 1.0
            }

            # NEXT, Put the record into the database
            rdb eval {
                INSERT INTO 
                cap_kg(k,g,pen)
                VALUES($k, $g, $pen);
            }

            # NEXT, Return the undo command
            return [list rdb delete cap_kg "k='$k' AND g='$g'"]
        }
    }

    # mutate pen delete id
    #
    # id   - list {k g}
    #
    # Deletes the override.

    typemethod {mutate pen delete} {id} {
        lassign $id k g

        # FIRST, delete the records, grabbing the undo information
        set data [rdb delete -grab cap_kg {k=$k AND g=$g}]

        # NEXT, Return the undo script
        return [list rdb ungrab $data]
    }

    # mutate pen update parmdict
    #
    # parmdict   - A dictionary of cap_kg parms
    #
    #    id    - list {k g}
    #    pen   - A new group coverage, or ""
    #
    # Updates a cap_kg given the parms, which are presumed to be
    # valid.

    typemethod {mutate pen update} {parmdict} {
        dict with parmdict {
            lassign $id k g

            # FIRST, grab the data that might change.
            set data [rdb grab cap_kg {k=$k AND g=$g}]

            # NEXT, Update the cap_kg
            rdb eval {
                UPDATE cap_kg
                SET pen = nonempty($pen, pen)
                WHERE k=$k AND g=$g;
            } 

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
    }
    
    # RefreshCREATE fields fdict
    #
    # dlg       The order dialog
    # fields    The fields that changed.
    # fdict     The current values of the various fields.
    #
    # Refreshes the CAP:CREATE dialog fields when field values
    # change.

    typemethod RefreshCREATE {dlg fields fdict} {
        dict with fdict {
            if {"k" in $fields} {
                set gdict [rdb eval {
                    SELECT g,g FROM civgroups
                    ORDER BY g
                }]
                
                $dlg field configure glist -itemdict $gdict

                set ndict [rdb eval {
                    SELECT n,n FROM nbhoods
                    ORDER BY n
                }]
                
                $dlg field configure nlist -itemdict $ndict
            }
        }
    }
}    

#-------------------------------------------------------------------
# Orders: CAP:*

# CAP:CREATE
#
# Creates new CAPs.

order define CAP:CREATE {
    title "Create Comm. Asset Package"
    
    options \
        -sendstates PREP \
        -refreshcmd {cap RefreshCREATE}

    parm k           text  "CAP"
    parm longname    text  "Long Name"
    parm owner       enum  "Owning Actor"         -enumtype actor
    parm capacity    frac  "Capacity"             -defval   1.0
    parm cost        text  "Cost, $/message/week" -defval   0
    parm nlist       nlist "Neighborhoods"        
    parm glist       glist "Civ. Groups"
} {
    # FIRST, prepare and validate the parameters
    prepare k           -toupper   -required -unused -type ident
    prepare longname    -normalize
    prepare owner       -toupper   -required -type actor
    prepare capacity               -required -type rfraction
    prepare cost        -toupper   -required -type money
    prepare nlist       -toupper   -required -listof nbhood
    prepare glist       -toupper   -required -listof civgroup

    returnOnError -final

    # NEXT, If longname is "", defaults to ID.
    if {$parms(longname) eq ""} {
        set parms(longname) $parms(k)
    }

    # NEXT, create the CAP and dependent entities
    lappend undo [cap mutate create [array get parms]]

    setundo [join $undo \n]
}

# CAP:DELETE

order define CAP:DELETE {
    title "Delete Comm. Asset Package"
    options -sendstates PREP

    parm k  key "CAP" -table gui_caps -keys k
} {
    # FIRST, prepare the parameters
    prepare k -toupper -required -type cap

    returnOnError -final

    # NEXT, make sure the user knows what he is getting into.

    if {[sender] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     CAP:DELETE                    \
                        -ignoredefault ok                               \
                        -parent        [app topwin]                     \
                        -message       [normalize {
                            Are you sure you
                            really want to delete this CAP, along
                            with all of the entities that depend upon it?
                        }]]

        if {$answer eq "cancel"} {
            cancel
        }
    }

    # NEXT, Delete the CAP and dependent entities
    lappend undo [cap mutate delete $parms(k)]

    setundo [join $undo \n]
}


# CAP:UPDATE
#
# Updates existing CAPs.

order define CAP:UPDATE {
    title "Update Comm. Asset Package"
    options -sendstates PREP \
        -refreshcmd {orderdialog refreshForKey k *}

    parm k           key   "Select CAP"            -table    gui_caps \
                                                   -keys     k
    parm longname    text  "Long Name"
    parm owner       enum  "Owning Actor"          -enumtype actor
    parm capacity    frac  "Capacity"
    parm cost        text  "Cost, $/message/week"
} {
    # FIRST, prepare the parameters
    prepare k           -toupper   -required -type cap
    prepare longname    -normalize
    prepare owner       -toupper             -type actor
    prepare capacity                         -type rfraction
    prepare cost        -toupper             -type money

    returnOnError -final

    # NEXT, modify the CAP.
    set undo [list]
    lappend undo [cap mutate update [array get parms]]

    setundo [join $undo \n]
}

# CAP:UPDATE:MULTI
#
# Updates multiple CAPs.

order define CAP:UPDATE:MULTI {
    title "Update Multiple CAPs"
    options \
        -sendstates PREP                                  \
        -refreshcmd {orderdialog refreshForMulti ids *}

    parm ids         multi "CAPs"                 -table    gui_caps \
                                                  -key      k
    parm owner       enum  "Owning Actor"         -enumtype actor
    parm capacity    frac  "Capacity"
    parm cost        text  "Cost, $/message/week"
} {
    # FIRST, prepare the parameters
    prepare ids         -toupper  -required -listof cap
    prepare owner       -toupper            -type   actor
    prepare capacity                        -type   rfraction
    prepare cost        -toupper            -type   money

    returnOnError -final

    # NEXT, clear the other parameters expected by the mutator
    prepare longname

    # NEXT, modify the CAP
    set undo [list]

    foreach parms(k) $parms(ids) {
        lappend undo [cap mutate update [array get parms]]
    }

    setundo [join $undo \n]
}

# CAP:CAPACITY
#
# Updates the capacity of an existing CAP.

order define CAP:CAPACITY {
    title "Set CAP Capacity"
    options -sendstates {PREP PAUSED TACTIC} \
        -refreshcmd {orderdialog refreshForKey k *}

    parm k           key   "Select CAP"  -table gui_caps -keys k
    parm capacity    frac  "Capacity"
} {
    # FIRST, prepare the parameters
    prepare k           -toupper   -required -type cap
    prepare capacity                         -type rfraction

    returnOnError -final

    # NEXT, prepare the others, so that the mutator will be happy.
    prepare longname
    prepare owner
    prepare cost

    # NEXT, modify the CAP.
    set undo [list]
    lappend undo [cap mutate update [array get parms]]

    setundo [join $undo \n]
}

# CAP:CAPACITY:MULTI
#
# Updates capacity for multiple CAPs.

order define CAP:CAPACITY:MULTI {
    title "Set Multiple CAP Capacities"
    options \
        -sendstates {PREP PAUSED TACTIC} \
        -refreshcmd {orderdialog refreshForMulti ids *}

    parm ids       multi "CAPs"      -table gui_caps -key k
    parm capacity  frac  "Capacity"
} {
    # FIRST, prepare the parameters
    prepare ids         -toupper  -required -listof cap
    prepare capacity                        -type   rfraction

    returnOnError -final

    # NEXT, clear the other parameters expected by the mutator
    prepare longname

    # NEXT, modify the CAP
    set undo [list]

    foreach parms(k) $parms(ids) {
        lappend undo [cap mutate update [array get parms]]
    }

    setundo [join $undo \n]
}


# CAP:NBCOV:SET
#
# Sets nbcov for k,n

order define CAP:NBCOV:SET {
    title "Set CAP Neighborhood Coverage"
    options \
        -sendstates {PREP PAUSED TACTIC} \
        -refreshcmd {orderdialog refreshForKey id *}

    parm id    key   "CAP/Nbhood"     -table  gui_cap_kn    \
                                      -keys   {k n}         \
                                      -labels {Of In}
    parm nbcov frac  "Coverage"
} {
    # FIRST, prepare the parameters
    prepare id       -toupper  -required -type {cap nbcov}
    prepare nbcov    -toupper            -type rfraction

    returnOnError -final

    # NEXT, modify the curve
    if {[cap nbcov exists $parms(id)]} {
        if {$parms(nbcov) > 0.0} {
            setundo [cap mutate nbcov update [array get parms]]
        } else {
            setundo [cap mutate nbcov delete $parms(id)]
        }
    } else {
        setundo [cap mutate nbcov create [array get parms]]
    }
}


# CAP:NBCOV:SET:MULTI
#
# Updates nbcov for multiple k,n

order define CAP:NBCOV:SET:MULTI {
    title "Set Multiple CAP Neighborhood Coverages"
    options \
        -sendstates {PREP PAUSED TACTIC} \
        -refreshcmd {orderdialog refreshForMulti ids *}

    parm ids   multi "IDs"           -table gui_cap_kn \
                                     -key   id
    parm nbcov frac  "Coverage"
} {
    # FIRST, prepare the parameters
    prepare ids      -toupper  -required -listof {cap nbcov}
    prepare nbcov    -toupper            -type rfraction

    returnOnError -final

    # NEXT, modify the records
    set undo [list]

    foreach parms(id) $parms(ids) {
        if {[cap nbcov exists $parms(id)]} {
            if {$parms(nbcov) > 0.0} {
                lappend undo [cap mutate nbcov update [array get parms]]
            } else {
                lappend undo [cap mutate nbcov delete $parms(id)]
            }
        } else {
            lappend undo [cap mutate nbcov create [array get parms]]
        }
    }

    setundo [join $undo \n]
}

# CAP:PEN:SET
#
# Sets pen for k,n

order define CAP:PEN:SET {
    title "Set CAP Group Penetration"
    options \
        -sendstates {PREP PAUSED TACTIC} \
        -refreshcmd {orderdialog refreshForKey id *}

    parm id  key   "CAP/Group"        -table  gui_capcov    \
                                      -keys   {k g}         \
                                      -labels {Of Into}
    parm pen frac  "Penetration"
} {
    # FIRST, prepare the parameters
    prepare id     -toupper  -required -type {cap pen}
    prepare pen    -toupper            -type rfraction

    returnOnError -final

    # NEXT, modify the curve
    if {[cap pen exists $parms(id)]} {
        if {$parms(pen) > 0.0} {
            setundo [cap mutate pen update [array get parms]]
        } else {
            setundo [cap mutate pen delete $parms(id)]
        }
    } else {
        setundo [cap mutate pen create [array get parms]]
    }
}


# CAP:PEN:SET:MULTI
#
# Updates pen for multiple k,g

order define CAP:PEN:SET:MULTI {
    title "Set Multiple CAP Group Penetrations"
    options \
        -sendstates {PREP PAUSED TACTIC} \
        -refreshcmd {orderdialog refreshForMulti ids *}

    parm ids multi "IDs"           -table gui_capcov \
                                   -key   id
    parm pen frac  "Penetration"
} {
    # FIRST, prepare the parameters
    prepare ids  -toupper  -required -listof {cap pen}
    prepare pen  -toupper            -type rfraction

    returnOnError -final

    # NEXT, modify the records
    set undo [list]

    foreach parms(id) $parms(ids) {
        if {[cap pen exists $parms(id)]} {
            if {$parms(pen) > 0.0} {
                lappend undo [cap mutate pen update [array get parms]]
            } else {
                lappend undo [cap mutate pen delete $parms(id)]
            }
        } else {
            lappend undo [cap mutate pen create [array get parms]]
        }
    }

    setundo [join $undo \n]
}

