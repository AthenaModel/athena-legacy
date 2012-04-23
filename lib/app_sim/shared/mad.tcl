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
    # dict2    row dict for deleted entity in gram_drivers
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


    # mutate satadjust parmdict
    #
    # parmdict    A dictionary of order parameters
    #
    #    id               list {g c}
    #    driver_id        MAD ID
    #    delta            Delta to the baseline, a floating point value.
    #
    # Adjusts a satisfaction curve's baseline by a delta given the parms, 
    # which are presumed to be valid.

    typemethod {mutate satadjust} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            lassign $id g c
            set n [civgroup getg $g n]

            # FIRST, get the narrative text
            set narrative [driver narrative get $driver_id]

            # NEXT, Adjust the baseline
            aram edit mark
            aram sat badjust $driver_id $g $c $delta
            driver inputs incr $driver_id

            # NEXT, send ADJUST-1-1 report
            set text [edamrule longname ADJUST-1-1]
            append text "\n\n"

            set fmt "%-22s %s\n"

            append text [format $fmt "Magic Attitude Driver:" $driver_id]
            append text [format $fmt "Description:"           $narrative]
            append text [format $fmt "Neighborhood:"          $n]
            append text [format $fmt "Group:"                 $g]
            append text [format $fmt "Concern:"               $c]

            set deltaText [format "%.3f" $delta]
            append text [format $fmt "Delta:"                 $deltaText]

            set reportid \
                [firings save \
                     -rtype   DAM                                          \
                     -subtype ADJUST                                       \
                     -meta1   ADJUST-1-1                                   \
                     -title   "ADJUST-1-1: [edamrule longname ADJUST-1-1]" \
                     -text    $text]

            # NEXT, notify application
            notifier send ::mad <Sat> update $id

            # NEXT, Return the undo command
            return [mytypemethod UndoAdjust $driver_id $reportid <Sat> $id]
        }
    }

    # mutate satinput parmdict
    #
    # parmdict  - A dictionary of order parameters
    #
    #    driver_id  - The MAD ID
    #    mode       - An einputmode value
    #    g          - Group ID
    #    c          - Concern
    #    mag        - A qmag(n) value
    #
    # Makes the MAGIC-1-1 rule fire for the given input.
    
    typemethod {mutate satinput} {parmdict} {
        dict with parmdict {
            set n [civgroup getg $g n]

            # FIRST, get the Driver Data
            rdb eval {
                SELECT narrative, cause, s, p, q FROM mads 
                WHERE driver_id=$driver_id
            } {}

            # NEXT, get the cause.  Passing "" will cause URAM to 
            # use the numeric driver ID as the numeric cause ID.
            if {$cause eq "UNIQUE"} {
                set cause ""
            }

            dam ruleset MAGIC $driver_id \
                -cause $cause         \
                -s     $s             \
                -p     $p             \
                -q     $q

            dam detail "Magic Attitude Driver:" $driver_id
            dam detail "Narrative:"             $narrative
            dam detail "In Neighborhood:"       $n

            if {$mode eq "persistent"} {
                set mode P
            } else {
                set mode T
            }

            dam rule MAGIC-1-1 {1} {
                dam sat $mode $g $c $mag
            }
        }

        # NEXT, cannot be undone.
        return
    }

    # mutate coopadjust parmdict
    #
    # parmdict    A dictionary of order parameters
    #
    #    id               list {f g}
    #    driver_id        MAD ID
    #    delta            Delta to the baseline, a floating point value.
    #
    # Adjusts a cooperation curve's baseline by a delta given the parms, 
    # which are presumed to be valid.

    typemethod {mutate coopadjust} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            lassign $id f g
            set n [civgroup getg $f n]

            # FIRST, get the narrative text
            set narrative [driver narrative get $driver_id]

            # NEXT, Adjust the baseline
            aram edit mark
            aram coop badjust $driver_id $f $g $delta
            driver inputs incr $driver_id

            # NEXT, send ADJUST-2-1 report
            set text [edamrule longname ADJUST-2-1]
            append text "\n\n"

            set fmt "%-22s %s\n"

            append text [format $fmt "Magic Attitude Driver:" $driver_id]
            append text [format $fmt "Narrative:"             $narrative]
            append text [format $fmt "Neighborhood:"          $n]
            append text [format $fmt "Civ Group:"             $f]
            append text [format $fmt "Frc Group:"             $g]

            set deltaText [format "%.3f" $delta]
            append text [format $fmt "Delta:"                 $deltaText]

            set reportid \
                [firings save \
                     -rtype   DAM                                          \
                     -subtype ADJUST                                       \
                     -meta1   ADJUST-2-1                                   \
                     -title   "ADJUST-2-1: [edamrule longname ADJUST-2-1]" \
                     -text    $text]

            # NEXT, notify application
            notifier send ::mad <Coop> update $id

            # NEXT, Return the undo command
            return [mytypemethod UndoAdjust $driver_id $reportid <Coop> $id]
        }
    }

    # mutate coopinput parmdict
    #
    # parmdict    A dictionary of order parameters
    #
    #    driver_id  - The MAD ID
    #    mode       - An einputmode value
    #    f          - Civilian Group
    #    g          - Force Group
    #    mag        - A qmag(n) value
    #
    # Makes the MAGIC-2-1 rule fire for the given input.
    
    typemethod {mutate coopinput} {parmdict} {
        dict with parmdict {
            set n [civgroup getg $f n]

            # FIRST, get the Driver Data
            rdb eval {
                SELECT narrative, cause, s, p, q FROM mads 
                WHERE driver_id=$driver_id
            } {}

            # NEXT, get the cause.  Passing "" will cause URAM to 
            # use the numeric driver ID as the numeric cause ID.
            if {$cause eq "UNIQUE"} {
                set cause ""
            }

            dam ruleset MAGIC $driver_id \
                -cause $cause            \
                -s     $s                \
                -p     $p                \
                -q     $q

            dam detail "Magic Attitude Driver:" $driver_id
            dam detail "Narrative:"             $narrative
            dam detail "In Neighborhood:"       $n

            if {$mode eq "persistent"} {
                set mode P
            } else {
                set mode T
            }

            dam rule MAGIC-2-1 {1} {
                dam coop $mode $f $g $mag
            }
        }

        # NEXT, cannot be undone.
        return
    }


    #-------------------------------------------------------------------
    # Helpers Methods and Procs

    # UndoAdjust driver_id reportid event id
    #
    # driver_id  - The driver_id for the adjustment
    # reportid   - The ID of the rule firing report.
    # event      - Notifier event ID
    # id         - Record ID, e.g., {$g $c}
    #
    # Undoes an attitude adjustment.

    typemethod UndoAdjust {driver_id reportid event id} {
        aram edit undo
        firings delete $reportid
        driver inputs incr $driver_id -1

        notifier send ::mad $event update $id
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

    parm narrative text  "Narrative" 
    parm cause     enum  "Cause"         -enumtype {ptype ecause+unique} \
                                         -defval   UNIQUE
    parm s         frac  "Here Factor"   -defval   1.0
    parm p         frac  "Near Factor"   -defval   0.0
    parm q         frac  "Far Factor"    -defval   0.0

} {
    # FIRST, prepare and validate the parameters
    prepare narrative          -required
    prepare cause     -toupper -required -type {ptype ecause+unique}
    prepare s                  -required -type rfraction
    prepare p                  -required -type rfraction
    prepare q                  -required -type rfraction

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


    parm driver_id key "MAD ID" -table    gui_mads_initial \
                                -keys     driver_id        \
                                -dispcols longid
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
    options \
        -sendstates  {PREP PAUSED TACTIC}      \
        -refreshcmd {orderdialog refreshForKey driver_id *}

    parm driver_id key   "MAD ID"        -table    gui_mads  \
                                         -keys     driver_id \
                                         -dispcols longid
    parm narrative text  "Narrative"
    parm cause     enum  "Cause"         -enumtype {ptype ecause+unique}
    parm s         frac  "Here Factor"
    parm p         frac  "Near Factor"
    parm q         frac  "Far Factor" 
} {
    # FIRST, prepare the parameters
    prepare driver_id -required -type mad
    prepare narrative
    prepare cause     -toupper  -type {ptype ecause+unique}
    prepare s                   -type rfraction
    prepare p                   -type rfraction
    prepare q                   -type rfraction

    returnOnError -final

    # NEXT, update the MAD
    lappend undo [mad mutate update [array get parms]]

    setundo [join $undo \n]
}

# MAD:SAT:ADJUST
#
# Adjusts a satisfaction curve's baseline by some delta.

order define MAD:SAT:ADJUST {
    title "Magic Adjust Satisfaction Baseline"
    options \
        -sendstates     {PAUSED TACTIC}         \
        -schedulestates {PREP PAUSED TACTIC}

    parm id        key   "Curve"     -table    gui_sat_gc      \
                                     -keys     {g c}           \
                                     -labels   {"Grp" "Con"}
    parm driver_id key   "MAD ID"    -table    gui_mads        \
                                     -keys     driver_id       \
                                     -dispcols longid
    parm delta     text  "Delta"
} {
    # FIRST, prepare the parameters
    prepare id         -toupper -required -type sat
    prepare driver_id           -required -type mad
    prepare delta      -toupper -required -type snit::double

    returnOnError -final

    # NEXT, modify the curve
    setundo [mad mutate satadjust [array get parms]]
}

# MAD:SAT:INPUT
#
# Enters a magic satisfaction input.

order define MAD:SAT:INPUT {
    title "Magic Satisfaction Input"
    options \
        -sendstates     {TACTIC}             \
        -schedulestates {PREP PAUSED TACTIC}

    parm driver_id key   "MAD ID"              -table       gui_mads   \
                                               -keys        driver_id  \
                                               -dispcols    longid
    parm mode      enum  "Mode"                -enumtype    einputmode \
                                               -displaylong yes        \
                                               -defval      transient
    parm g         enum  "Group"               -enumtype    civgroup
    parm c         enum  "Concern"             -enumtype    {ptype c}
    parm mag       text  "Magnitude"
} {
    # FIRST, prepare the parameters
    prepare driver_id          -required -type mad
    prepare mode      -tolower -required -type einputmode
    prepare g         -toupper -required -type civgroup
    prepare c         -toupper -required -type {ptype c}
    prepare mag       -toupper -required -type qmag -xform [list qmag value]

    returnOnError -final

    # NEXT, modify the curve
    # TBD: Need to support undo
    mad mutate satinput [array get parms]

    return
}


# MAD:COOP:ADJUST
#
# Adjusts a cooperation curve's baseline by some delta.

order define MAD:COOP:ADJUST {
    title "Magic Adjust Cooperation Baseline"
    options \
        -sendstates     {PAUSED TACTIC}         \
        -schedulestates {PREP PAUSED TACTIC}

    parm id        key   "Curve"     -table    gui_coop_fg     \
                                     -keys     {f g}           \
                                     -labels   {"Of" "With"}
    parm driver_id key   "MAD ID"    -table    gui_mads        \
                                     -keys     driver_id       \
                                     -dispcols longid
    parm delta     text  "Delta"
} {
    # FIRST, prepare the parameters
    prepare id        -toupper -required -type coop
    prepare driver_id          -required -type mad
    prepare delta     -toupper -required -type snit::double

    returnOnError -final

    # NEXT, modify the curve
    setundo [mad mutate coopadjust [array get parms]]
}

# MAD:COOP:INPUT
#
# Enters a magic cooperation input.

order define MAD:COOP:INPUT {
    title "Magic Cooperation Input"
    options \
        -sendstates     {TACTIC}             \
        -schedulestates {PREP PAUSED TACTIC}

    parm driver_id key   "MAD ID"              -table       gui_mads   \
                                               -keys        driver_id  \
                                               -dispcols    longid
    parm mode      enum  "Mode"                -enumtype    einputmode \
                                               -displaylong yes        \
                                               -defval      transient
    parm f         enum  "Of Group"            -enumtype civgroup
    parm g         enum  "With Group"          -enumtype frcgroup
    parm mag       text  "Magnitude"
} {
    # FIRST, prepare the parameters
    prepare driver_id          -required -type mad
    prepare mode      -tolower -required -type einputmode
    prepare f         -toupper -required -type civgroup
    prepare g         -toupper -required -type frcgroup
    prepare mag       -toupper -required -type qmag -xform [list qmag value]

    returnOnError -final

    # NEXT, modify the curve
    mad mutate coopinput [array get parms]

    return
}

