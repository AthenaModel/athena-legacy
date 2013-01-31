#-----------------------------------------------------------------------
# TITLE:
#    mad.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Magic Attitude Driver (MAD) Manager
#
#    This module is responsible for managing the creation, editing,
#    and deletion of MADs.
#
#-----------------------------------------------------------------------

snit::type mad {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.


    # names
    #
    # Returns the list of MAD ids

    typemethod names {} {
        rdb eval {SELECT driver_id FROM mads}
    }


    # longnames
    #
    # Returns the list of extended MAD ids

    typemethod longnames {} {
        rdb eval {SELECT driver_id || ' - ' || narrative FROM mads}
    }


    # validate id
    #
    # id  - Possibly, a MAD ID.
    #
    # Validates a MAD id

    typemethod validate {id} {
        if {![rdb exists {SELECT driver_id FROM mads WHERE driver_id=$id}]} {
            return -code error -errorcode INVALID \
                "MAD does not exist: \"$id\""
        }

        return $id
    }

    # initial names
    #
    # Returns the list of MAD ids for MADs in the initial state

    typemethod {initial names} {} {
        rdb eval {SELECT driver_id FROM gui_mads_initial}
    }


    # initial validate id
    #
    # id         Possibly, a MAD ID.
    #
    # Validates a MAD id for a MAD in the initial state

    typemethod {initial validate} {id} {
        if {![rdb exists {
            SELECT driver_id FROM gui_mads_initial WHERE driver_id=$id
        }]} {
            return -code error -errorcode INVALID \
                "MAD does not exist or is not in initial state: \"$id\""
        }

        return $id
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
    # parmdict  -  A dictionary of MAD parms
    #
    #    narrative       The MAD's description.
    #    cause          "UNIQUE", or an ecause(n) value
    #    s              A fraction
    #    p              A fraction
    #    q              A fraction
    #
    # Creates a MAD given the parms, which are presumed to be
    # valid.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            # FIRST, get the next ID.
            set id [driver create MAGIC $narrative]

            # NEXT, Put the MAD in the database
            rdb eval {
                INSERT INTO mads_t(driver_id,cause,s,p,q)
                VALUES($id,
                       $cause,
                       $s,
                       $p,
                       $q);
            }

            # NEXT, Return the undo command
            lappend undo [mytypemethod mutate delete $id]

            return [join $undo \n]
        }
    }

    # mutate delete id
    #
    # id -  A MAD ID
    #
    # Deletes the MAD.

    typemethod {mutate delete} {id} {
        # FIRST, get the undo information
        rdb eval {SELECT * FROM mads_t WHERE driver_id=$id} row1 { 
            unset row1(*) 
        }

        rdb eval {SELECT * FROM drivers WHERE driver_id=$id} row2 { 
            unset row2(*) 
        }

        # NEXT, delete it.
        rdb eval {DELETE FROM mads_t WHERE driver_id=$id}
        driver delete $id

        # NEXT, Return the undo script
        return [mytypemethod RestoreDeletedMAD \
                    [array get row1] [array get row2]]
    }

    # RestoreDeletedMAD dict1 dict2
    #
    # dict1    row dict for deleted entity in mads
    # dict2    row dict for deleted entity in drivers
    #
    # Restores the row to the database

    typemethod RestoreDeletedMAD {dict1 dict2} {
        rdb insert mads_t  $dict1
        rdb insert drivers $dict2
    }

    # mutate update parmdict
    #
    # parmdict   - A dictionary of order parms
    #
    #   driver_id  - The MAD's ID
    #   narrative  - A new description, or ""
    #   cause      - "UNIQUE", or an ecause(n) value, or ""
    #   s          - A fraction, or ""
    #   p          - A fraction, or ""
    #   q          - A fraction, or ""
    #
    # Updates the MAD given the parms, which are presumed to be
    # valid.
    #
    # Changes to cause, s, p, and q only affect new inputs entered
    # for this MAD.

    typemethod {mutate update} {parmdict} {
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM mads
                WHERE driver_id=$driver_id
            } row {
                unset row(*)
            }
            
            set row(narrative) [driver narrative get $driver_id]

            # NEXT, Update the MAD
            rdb eval {
                UPDATE mads_t
                SET cause    = nonempty($cause,    cause),
                    s        = nonempty($s,        s),
                    p        = nonempty($p,        p),
                    q        = nonempty($q,        q)
                WHERE driver_id=$driver_id
            }

            if {$narrative ne ""} {
                driver narrative set $driver_id $narrative
            }

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get row]]
        }
    }


    # mutate hrel parmdict
    #
    # parmdict    A dictionary of order parameters
    #
    #    driver_id  - The MAD ID
    #    mode       - An einputmode value
    #    f          - A Group
    #    g          - Another Group
    #    mag        - A qmag(n) value
    #
    # Makes the MAGIC-1-1 rule fire for the given input.
    
    typemethod {mutate hrel} {parmdict} {
        # FIRST, get the dict data.
        dict with parmdict {}

        # NEXT, skip empty civilian groups
        if {$f in [civgroup names]} {
            if {[demog getg $f population] == 0} {
                log normal mad "Skipping hrel; group $f is empty"
                return
            }
        }

        if {$g in [civgroup names]} {
            if {[demog getg $g population] == 0} {
                log normal mad "Skipping hrelnput; group $g is empty"
                return
            }
        }
        
        # NEXT, get the Driver Data
        rdb eval {
            SELECT narrative, cause FROM mads 
            WHERE driver_id=$driver_id
        } {}

        # NEXT, get the cause.  Passing "" will cause URAM to 
        # use the numeric driver ID as the numeric cause ID.
        if {$cause eq "UNIQUE"} {
            set cause ""
        }

        set fdict [dict create f $f g $g narrative $narrative]

        if {$mode eq "persistent"} {
            set mode P
        } else {
            set mode T
        }

        dam rule MAGIC-1-1 $driver_id $fdict -cause $cause {1} {
            dam hrel $mode $f $g $mag
        }

        # NEXT, cannot be undone.
        return
    }


    # mutate vrel parmdict
    #
    # parmdict    A dictionary of order parameters
    #
    #    driver_id  - The MAD ID
    #    mode       - An einputmode value
    #    g          - A group
    #    a          - An actor
    #    mag        - A qmag(n) value
    #
    # Makes the MAGIC-2-1 rule fire for the given input.
    
    typemethod {mutate vrel} {parmdict} {
        # FIRST, get the dict parameters
        dict with parmdict {}

        # NEXT, skip empty civilian groups
        if {$g in [civgroup names]} {
            if {[demog getg $g population] == 0} {
                log normal mad "Skipping vrel; group $g is empty"
                return
            }
        }
        
        # NEXT, get the Driver Data
        rdb eval {
            SELECT narrative, cause FROM mads 
            WHERE driver_id=$driver_id
        } {}

        # NEXT, get the cause.  Passing "" will cause URAM to 
        # use the numeric driver ID as the numeric cause ID.
        if {$cause eq "UNIQUE"} {
            set cause ""
        }

        set fdict [dict create g $g a $a narrative $narrative]
        
        if {$mode eq "persistent"} {
            set mode P
        } else {
            set mode T
        }

        dam rule MAGIC-2-1 $driver_id $fdict -cause $cause {1} {
            dam vrel $mode $g $a $mag
        }

        # NEXT, cannot be undone.
        return
    }

    # mutate sat parmdict
    #
    # parmdict  - A dictionary of order parameters
    #
    #    driver_id  - The MAD ID
    #    mode       - An einputmode value
    #    g          - Group ID
    #    c          - Concern
    #    mag        - A qmag(n) value
    #
    # Makes the MAGIC-3-1 rule fire for the given input.
    
    typemethod {mutate sat} {parmdict} {
        # FIRST, get the dict parameters.
        dict with parmdict {}
        set n [civgroup getg $g n]

        # NEXT, skip empty civilian groups
        if {$g in [civgroup names]} {
            if {[demog getg $g population] == 0} {
                log normal mad "Skipping sat; group $g is empty"
                return
            }
        }
        
        # NEXT, get the Driver Data
        rdb eval {
            SELECT narrative, cause, s, p, q FROM mads 
            WHERE driver_id=$driver_id
        } {}

        # NEXT, get the cause.  Passing "" will cause URAM to 
        # use the numeric driver ID as the numeric cause ID.
        if {$cause eq "UNIQUE"} {
            set cause ""
        }

        if {$mode eq "persistent"} {
            set mode P
        } else {
            set mode T
        }
    
        set fdict [dict create n $n g $g c $c narrative $narrative]
        set opts [list -cause $cause -s $s -p $p -q $q]
        dam rule MAGIC-3-1 $driver_id $fdict {*}$opts {1} {
            dam sat $mode $g $c $mag
        }

        # NEXT, cannot be undone.
        return
    }

    # mutate coop parmdict
    #
    # parmdict    A dictionary of order parameters
    #
    #    driver_id  - The MAD ID
    #    mode       - An einputmode value
    #    f          - Civilian Group
    #    g          - Force Group
    #    mag        - A qmag(n) value
    #
    # Makes the MAGIC-4-1 rule fire for the given input.
    
    typemethod {mutate coop} {parmdict} {
        # FIRST, get the dict parameters
        dict with parmdict {}
        set n [civgroup getg $f n]

        # NEXT, skip empty civilian groups
        if {$f in [civgroup names]} {
            if {[demog getg $f population] == 0} {
                log normal mad "Skipping coop; group $f is empty"
                return
            }
        }
        
        # NEXT, get the Driver Data
        rdb eval {
            SELECT narrative, cause, s, p, q FROM mads 
            WHERE driver_id=$driver_id
        } {}

        # NEXT, get the cause.  Passing "" will cause URAM to 
        # use the numeric driver ID as the numeric cause ID.
        if {$cause eq "UNIQUE"} {
            set cause ""
        }

        if {$mode eq "persistent"} {
            set mode P
        } else {
            set mode T
        }

        set fdict [dict create n $n f $f g $g narrative $narrative]
        set opts [list -cause $cause -s $s -p $p -q $q]
        dam rule MAGIC-4-1 $driver_id $fdict {*}$opts {1} {
            dam coop $mode $f $g $mag
        }

        # NEXT, cannot be undone.
        return
    }

    #------------------------------------------------------------------
    # Order Helpers

    proc AllGroupsBut {g} {
        return [rdb eval {
            SELECT g FROM groups
            WHERE g != $g
            ORDER BY g
        }]
    }
}

#-------------------------------------------------------------------
# Orders: MAD:*

# MAD:CREATE
#
# Creates a new MAD.

order define MAD:CREATE {
    title "Create Magic Attitude Driver"

    options -sendstates {PREP PAUSED TACTIC}

    form {
        rcc "Narrative:" -for narrative
        text narrative -width 40

        rcc "Cause:" -for cause
        enum cause -listcmd {ptype ecause+unique names} -defvalue UNIQUE

        rcc "Here Factor:" -for s
        frac s -defvalue 1.0

        rcc "Near Factor:" -for p
        frac p -defvalue 0.0

        rcc "Far Factor:" -for q
        frac q -defvalue 0.0
    }
} {
    # FIRST, prepare and validate the parameters
    prepare narrative          -required
    prepare cause     -toupper -required -type {ptype ecause+unique}
    prepare s         -num     -required -type rfraction
    prepare p         -num     -required -type rfraction
    prepare q         -num     -required -type rfraction

    returnOnError -final

    # NEXT, create the mad
    lappend undo [mad mutate create [array get parms]]

    setundo [join $undo \n]
}


# MAD:DELETE
#
# Deletes a MAD in the initial state

order define MAD:DELETE {
    title "Delete Magic Attitude Driver"
    options \
        -sendstates {PREP PAUSED}

    form {
        rcc "MAD ID:" -for driver_id
        # Can't use "mad" field type, since only unused MADs can be
        # deleted.
        key driver_id -table gui_mads_initial -keys driver_id -dispcols longid
    }
} {
    # FIRST, prepare the parameters
    prepare driver_id -toupper -required -type {mad initial}

    returnOnError -final

    # NEXT, make sure the user knows what he is getting into.

    if {[sender] eq "gui"} {
        set answer [messagebox popup \
                        -title         "Are you sure?"                  \
                        -icon          warning                          \
                        -buttons       {ok "Delete it" cancel "Cancel"} \
                        -default       cancel                           \
                        -ignoretag     MAD:DELETE                      \
                        -ignoredefault ok                               \
                        -parent        [app topwin]                     \
                        -message       [normalize {
                            Are you sure you
                            really want to delete this magic attitude
                            driver?
                        }]]

        if {$answer eq "cancel"} {
            cancel
        }
    }

    # NEXT, Delete the mad
    lappend undo [mad mutate delete $parms(driver_id)]

    setundo [join $undo \n]
}


# MAD:UPDATE
#
# Updates an existing mad's description

order define MAD:UPDATE {
    title "Update Magic Attitude Driver"
    options -sendstates {PREP PAUSED TACTIC}

    form {
        rcc "MAD ID:" -for driver_id
        mad driver_id \
            -loadcmd {orderdialog keyload driver_id *}

        rcc "Narrative:" -for narrative
        text narrative -width 40

        rcc "Cause:" -for cause
        enum cause -listcmd {ptype ecause+unique names}

        rcc "Here Factor:" -for s
        frac s

        rcc "Near Factor:" -for p
        frac p

        rcc "Far Factor:" -for q
        frac q

    }
} {
    # FIRST, prepare the parameters
    prepare driver_id -required -type mad
    prepare narrative
    prepare cause     -toupper  -type {ptype ecause+unique}
    prepare s         -num      -type rfraction
    prepare p         -num      -type rfraction
    prepare q         -num      -type rfraction

    returnOnError -final

    # NEXT, update the MAD
    lappend undo [mad mutate update [array get parms]]

    setundo [join $undo \n]
}

# MAD:HREL
#
# Enters a magic horizontal relationship input.

order define MAD:HREL {
    title "Magic Horizontal Relationship Input"
    options -sendstates {PAUSED TACTIC}

    form {
        rcc "MAD ID:" -for driver_id
        mad driver_id

        rcc "Mode:" -for mode
        enumlong mode -dictcmd {einputmode deflist} -defvalue transient

        rcc "Of Group:" -for f
        group f

        rcc "With Group:" -for g
        enum g -listcmd {mad::AllGroupsBut $f}

        rcc "Magnitude:" -for mag
        mag mag
        label "points of change"
    }
} {
    # FIRST, prepare the parameters
    prepare driver_id          -required -type mad
    prepare mode      -tolower -required -type einputmode
    prepare f         -toupper -required -type group
    prepare g         -toupper -required -type group
    prepare mag  -num -toupper -required -type qmag

    returnOnError

    validate g {
        if {$parms(g) eq $parms(f)} {
            reject g "Cannot change a group's relationship with itself."
        }
    }

    returnOnError -final

    # NEXT, modify the curve
    mad mutate hrel [array get parms]

    return
}

# MAD:VREL
#
# Enters a magic vertical relationship input.

order define MAD:VREL {
    title "Magic Vertical Relationship Input"
    options -sendstates {PAUSED TACTIC}

    form {
        rcc "MAD ID:" -for driver_id
        mad driver_id

        rcc "Mode:" -for mode
        enumlong mode -dictcmd {einputmode deflist} -defvalue transient

        rcc "Of Group:" -for g
        group g

        rcc "With Actor:" -for a
        actor a

        rcc "Magnitude:" -for mag
        mag mag
        label "points of change"
    }
} {
    # FIRST, prepare the parameters
    prepare driver_id          -required -type mad
    prepare mode      -tolower -required -type einputmode
    prepare g         -toupper -required -type group
    prepare a         -toupper -required -type actor
    prepare mag  -num -toupper -required -type qmag

    returnOnError -final

    # NEXT, modify the curve
    mad mutate vrel [array get parms]

    return
}

# MAD:SAT
#
# Enters a magic satisfaction input.

order define MAD:SAT {
    title "Magic Satisfaction Input"
    options -sendstates {PAUSED TACTIC}

    form {
        rcc "MAD ID:" -for driver_id
        mad driver_id

        rcc "Mode:" -for mode
        enumlong mode -dictcmd {einputmode deflist} -defvalue transient

        rcc "Of Group:" -for g
        civgroup g

        rcc "With Concern:" -for c
        enum c -listcmd {ptype c names}

        rcc "Magnitude:" -for mag
        mag mag
        label "points of change"
    }
} {
    # FIRST, prepare the parameters
    prepare driver_id          -required -type mad
    prepare mode      -tolower -required -type einputmode
    prepare g         -toupper -required -type civgroup
    prepare c         -toupper -required -type {ptype c}
    prepare mag  -num -toupper -required -type qmag

    returnOnError -final

    # NEXT, modify the curve
    # TBD: Need to support undo
    mad mutate sat [array get parms]

    return
}


# MAD:COOP
#
# Enters a magic cooperation input.

order define MAD:COOP {
    title "Magic Cooperation Input"
    options -sendstates {PAUSED TACTIC}

    form {
        rcc "MAD ID:" -for driver_id
        mad driver_id

        rcc "Mode:" -for mode
        enumlong mode -dictcmd {einputmode deflist} -defvalue transient

        rcc "Of Group:" -for f
        civgroup f 

        rcc "With Group:" -for g
        frcgroup g

        rcc "Magnitude:" -for mag
        mag mag
        label "points of change"
    }
} {
    # FIRST, prepare the parameters
    prepare driver_id          -required -type mad
    prepare mode      -tolower -required -type einputmode
    prepare f         -toupper -required -type civgroup
    prepare g         -toupper -required -type frcgroup
    prepare mag  -num -toupper -required -type qmag

    returnOnError -final

    # NEXT, modify the curve
    mad mutate coop [array get parms]

    return
}

