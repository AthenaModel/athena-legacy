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
    # Initialization

    typemethod init {} {
        log detail mad "Initialized"
    }

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.


    # names
    #
    # Returns the list of MAD ids

    typemethod names {} {
        rdb eval {SELECT id FROM mads}
    }


    # longnames
    #
    # Returns the list of extended MAD ids

    typemethod longnames {} {
        rdb eval {SELECT id || ' - ' || oneliner AS longid FROM mads}
    }


    # validate id
    #
    # id         Possibly, a MAD ID.
    #
    # Validates a MAD id

    typemethod validate {id} {
        if {![rdb exists {SELECT id FROM mads WHERE id=$id}]} {
            return -code error -errorcode INVALID \
                "MAD does not exist: \"$id\""
        }

        return $id
    }

    # initial names
    #
    # Returns the list of MAD ids for MADs in the initial state

    typemethod {initial names} {} {
        rdb eval {SELECT id FROM gui_mads_initial}
    }


    # initial validate id
    #
    # id         Possibly, a MAD ID.
    #
    # Validates a MAD id for a MAD in the initial state

    typemethod {initial validate} {id} {
        if {![rdb exists {SELECT id FROM gui_mads_initial WHERE id=$id}]} {
            return -code error -errorcode INVALID \
                "MAD does not exist or is not in initial state: \"$id\""
        }

        return $id
    }

    #-------------------------------------------------------------------
    # Public Typemethods

    # getdrivers
    #
    # This routine is called when the sim leaves the PREP state; it
    # assigns driver IDs to all existing MADs.

    typemethod getdrivers {} {
        foreach id [$type names] {
            $type mutate getdriver $id
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
    # parmdict     A dictionary of MAD parms
    #
    #    oneliner       The MAD's description.
    #
    # Creates a MAD given the parms, which are presumed to be
    # valid.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            # FIRST, get the next ID.
            set id [rdb onecolumn {
                SELECT COALESCE(max(id)+1, 1) FROM mads
            }]

            # FIRST, Put the MAD in the database
            rdb eval {
                INSERT INTO mads(id,oneliner)
                VALUES($id,
                       $oneliner);
            }

            # NEXT, notify the app.
            notifier send ::mad <Entity> create $id

            # NEXT, if we are not in PREP, get the GRAM driver
            set undo [list]

            if {[sim state] ne "PREP"} {
                lappend undo [$type mutate getdriver $id]
            }

            # NEXT, Return the undo command
            lappend undo [mytypemethod mutate delete $id]

            return [join $undo \n]
        }
    }

    # mutate delete id
    #
    # id     A MAD ID
    #
    # Deletes the MAD.

    typemethod {mutate delete} {id} {
        # FIRST, get the undo information
        rdb eval {SELECT * FROM mads WHERE id=$id} row1 { unset row1(*) }

        # NEXT, delete it.
        rdb eval {DELETE FROM mads WHERE id=$id}

        # NEXT, delete the GRAM driver, if any
        if {$row1(driver) != -1} {
            rdb eval {
                SELECT * FROM gram_driver WHERE driver=$row1(driver)
            } row2 { unset row2(*) }

            aram cancel $row1(driver) -delete
        }

        # NEXT, notify the app
        notifier send ::mad <Entity> delete $id

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
        rdb insert mads $dict1

        if {$dict2 ne ""} {
            rdb insert gram_driver $dict2
        }

        notifier send ::mad <Entity> create [dict get $dict1 id]
    }

    # mutate update parmdict
    #
    # parmdict     A dictionary of order parms
    #
    #   id           The MAD's ID
    #   oneliner     A new description
    #
    # Updates the MAD given the parms, which are presumed to be
    # valid.

    typemethod {mutate update} {parmdict} {
        dict with parmdict {
            # FIRST, get the undo information
            rdb eval {
                SELECT * FROM mads
                WHERE id=$id
            } row {
                unset row(*)
            }
            
            # NEXT, Update the MAD
            rdb eval {
                UPDATE mads
                SET oneliner = $oneliner
                WHERE id=$id
            }

            # NEXT, if there's a GRAM driver, update it as well.
            set undo [list]

            if {$row(driver) != -1} {
                set oldtext [aram driver cget $row(driver) -oneliner]
                aram driver configure $row(driver) -oneliner $oneliner
            }

            # NEXT, notify the app.
            notifier send ::mad <Entity> update $id
            
            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get row]]
        }
    }

    # mutate getdriver mad
    #
    # mad         A MAD ID
    #
    # Assignes a driver ID for the given MAD, and returns an 
    # undo script.

    typemethod {mutate getdriver} {mad} {
        # FIRST, get the MAD data.
        rdb eval {SELECT * FROM mads WHERE id=$mad} row {}

        # NEXT, create a new GRAM driver
        set driver [aram driver add \
                        -name     "MAD $mad"      \
                        -dtype    "MAGIC"         \
                        -oneliner $row(oneliner)]

        # NEXT, save the driver ID
        rdb eval {
            UPDATE mads SET driver=$driver WHERE id=$mad;
        }

        notifier send ::mad <Entity> update $mad

        return [mytypemethod UndoGetDriver $mad $driver]
    }

    # UndoGetDriver mad driver
    #
    # mad        The mad ID
    # driver     A gram(n) driver ID
    #
    # Cancels the driver, deleting it from the RDB, and resets
    # the MAD.

    typemethod UndoGetDriver {mad driver} {
        # FIRST, cancel it in GRAM
        aram cancel $driver -delete

        # NEXT, clear it in the mads table
        rdb eval {
            UPDATE mads SET driver=-1 WHERE id=$mad
        }
        
        notifier send ::mad <Entity> update $mad
    }


    # mutate terminate id
    #
    # id              MAD ID
    #
    # Terminates all magic cooperation and satisfaction slopes for
    # the given MAD.

    typemethod {mutate terminate} {id} {
        # FIRST, get the GRAM driver ID.
        rdb eval {
            SELECT driver, oneliner FROM mads WHERE id=$id
        } {}

        # NEXT, Terminate the slope inputs.
        aram terminate $driver [simclock now]

        # NEXT, send MAGIC-3-1 report
        set text [edamrule longname MAGIC-3-1]
        append text "\n\n"

        set fmt "%-22s %s\n"

        append text [format $fmt "Magic Attitude Driver:" $id]
        append text [format $fmt "Description:"           $oneliner]
        append text [format $fmt "GRAM Driver ID:"        $driver]

        append text "\n"

        append text "All satisfaction and cooperation slope inputs have\n"
        append text "been terminated.  Termination of indirect effects in\n"
        append text "other neighborhoods is delayed as usual.\n"

        set reportid \
            [report save \
                 -type    DAM                                       \
                 -subtype MAGIC                                     \
                 -meta1   ADJUST-3-1                                \
                 -title   "MAGIC-3-1: [edamrule longname MAGIC-3-1]" \
                 -text    $text]

        # NEXT, cannot be undone.
        return
    }


    # mutate satadjust parmdict
    #
    # parmdict    A dictionary of order parameters
    #
    #    n                Neighborhood ID
    #    g                Group ID
    #    c                Concern
    #    mad              MAD ID
    #    delta            Delta to the level, a qmag(n) value.
    #
    # Adjusts a satisfaction level by a delta given the parms, 
    # which are presumed to be valid.

    typemethod {mutate satadjust} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            # FIRST, get the undo information
            set oldSat [aram sat.ngc $n $g $c]

            # NEXT, get the GRAM driver ID.
            rdb eval {
                SELECT driver, oneliner FROM mads WHERE id=$mad
            } {}

            # NEXT, Adjust the level
            set inputId [aram sat adjust $driver $n $g $c $delta]

            # NEXT, send ADJUST-1-1 report
            set text [edamrule longname ADJUST-1-1]
            append text "\n\n"

            set fmt "%-22s %s\n"

            append text [format $fmt "Magic Attitude Driver:" $mad]
            append text [format $fmt "Description:"           $oneliner]
            append text [format $fmt "GRAM Driver ID:"        $driver]
            append text [format $fmt "Input ID:"           "$driver.$inputId"]
            append text [format $fmt "Neighborhood:"          $n]
            append text [format $fmt "Group:"                 $g]
            append text [format $fmt "Concern:"               $c]

            set deltaText [format "%.3f (%s)" $delta [qmag name $delta]]
            append text [format $fmt "Delta:"        $deltaText]

            set reportid \
                [report save \
                     -type    DAM                                          \
                     -subtype ADJUST                                       \
                     -meta1   ADJUST-1-1                                   \
                     -title   "ADJUST-1-1: [edamrule longname ADJUST-1-1]" \
                     -text    $text]

            # NEXT, notify the app.
            # Note: need to update ::sat since current sat has changed,
            # and need to update ::mad since number of inputs for this
            # MAD has changed.
            notifier send ::sat <Entity> update [list $n $g $c]
            notifier send ::mad <Entity> update $mad

            # NEXT, Return the undo command
            return [mytypemethod RestoreSat $mad $driver $n $g $c $oldSat \
                       $reportid]
        }
    }

    # mutate satset parmdict
    #
    # parmdict    A dictionary of order parameters
    #
    #    n                Neighborhood ID
    #    g                Group ID
    #    c                Concern
    #    mad              MAD ID
    #    sat              New qsat(n) value
    #
    # Sets a satisfaction level to a particular value given the parms, 
    # which are presumed to be valid.

    typemethod {mutate satset} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            # FIRST, get the undo information
            set oldSat [aram sat.ngc $n $g $c]

            # NEXT, get the GRAM driver ID.
            rdb eval {
                SELECT driver, oneliner FROM mads WHERE id=$mad
            } {}

            # NEXT, Set the level
            set inputId [aram sat set $driver $n $g $c $sat]

            # NEXT, send ADJUST-1-2 report
            set text [edamrule longname ADJUST-1-2]
            append text "\n\n"

            set fmt "%-22s %s\n"

            append text [format $fmt "Magic Attitude Driver:" $mad]
            append text [format $fmt "Description:"           $oneliner]
            append text [format $fmt "GRAM Driver ID:"        $driver]
            append text [format $fmt "Input ID:"           "$driver.$inputId"]
            append text [format $fmt "Neighborhood:"          $n]
            append text [format $fmt "Group:"                 $g]
            append text [format $fmt "Concern:"               $c]

            set satText [format "%.3f (%s)" $sat [qsat name $sat]]
            append text [format $fmt "New Value:"    $satText]

            set reportid \
                [report save \
                     -type    DAM                                          \
                     -subtype ADJUST                                       \
                     -meta1   ADJUST-1-2                                   \
                     -title   "ADJUST-1-2: [edamrule longname ADJUST-1-2]"  \
                     -text    $text]

            # NEXT, notify the app.
            # Note: need to update ::sat since current sat has changed,
            # and need to update ::mad since number of inputs for this
            # MAD has changed.
            notifier send ::sat <Entity> update [list $n $g $c]
            notifier send ::mad <Entity> update $mad

            # NEXT, Return the undo command
            return [mytypemethod RestoreSat $mad $driver $n $g $c $oldSat \
                       $reportid]
        }
    }

    # RestoreSat mad driver n g c sat reportid
    #
    # Restores a satisfaction level to its previous value on undo.

    typemethod RestoreSat {mad driver n g c sat reportid} {
        aram sat set $driver $n $g $c $sat -undo
        reporter delete $reportid
        notifier send ::sat <Entity> update [list $n $g $c]
        notifier send ::mad <Entity> update $mad
    }

    # mutate satlevel parmdict
    #
    # parmdict    A dictionary of order parameters
    #
    #    n                Neighborhood ID
    #    g                Group ID
    #    c                Concern
    #    mad              MAD ID
    #    level            A qmag(n) value
    #    days             An rdays(n) value
    #    cause            "DRIVER", or an ecause(n) value
    #    p                A fraction
    #    q                A fraction
    #
    # Makes the MAGIC-1-1 rule fire for the given input.
    
    typemethod {mutate satlevel} {parmdict} {
        dict with parmdict {
            # FIRST, get the GRAM driver ID
            rdb eval {SELECT driver,oneliner FROM mads WHERE id=$mad} {}

            # NEXT, get the cause.
            if {$cause eq "DRIVER"} {
                set cause [format "MAD%04d" $mad]
            }

            dam ruleset MAGIC $driver \
                -n     $n             \
                -f     $g             \
                -cause $cause         \
                -p     $p             \
                -q     $q

            detail "Magic Attitude Driver:" $mad
            detail "Description:"           $oneliner
            detail "GRAM Driver ID:"        $driver

            dam rule MAGIC-1-1 {1} {
                dam sat level $c $limit $days
            }
        }

        # NEXT, cannot be undone.
        return
    }


    # mutate satslope parmdict
    #
    # parmdict    A dictionary of order parameters
    #
    #    n                Neighborhood ID
    #    g                Group ID
    #    c                Concern
    #    mad              MAD ID
    #    slope            A qmag(n) value
    #    cause            "DRIVER", or an ecause(n) value
    #    p                A fraction
    #    q                A fraction
    #
    # Makes the MAGIC-1-2 rule fire for the given input.
    
    typemethod {mutate satslope} {parmdict} {
        dict with parmdict {
            # FIRST, get the GRAM driver ID
            rdb eval {SELECT driver,oneliner FROM mads WHERE id=$mad} {}

            # NEXT, get the cause.
            if {$cause eq "DRIVER"} {
                set cause [format "MAD%04d" $mad]
            }

            dam ruleset MAGIC $driver \
                -n     $n             \
                -f     $g             \
                -cause $cause         \
                -p     $p             \
                -q     $q

            detail "Magic Attitude Driver:" $mad
            detail "Description:"           $oneliner
            detail "GRAM Driver ID:"        $driver

            dam rule MAGIC-1-2 {1} {
                dam sat slope $c $slope
            }
        }

        # NEXT, cannot be undone.
        return
    }


    # mutate coopadjust parmdict
    #
    # parmdict    A dictionary of order parameters
    #
    #    n                Neighborhood ID
    #    f                CIV group ID
    #    g                FRC group ID
    #    mad              MAD ID
    #    delta            Delta to the level, a qmag(n) value.
    #
    # Adjusts a cooperation level by a delta given the parms, 
    # which are presumed to be valid.

    typemethod {mutate coopadjust} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            # FIRST, get the undo information
            set oldCoop [aram coop.nfg $n $f $g]

            # NEXT, get the GRAM driver ID.
            rdb eval {
                SELECT driver, oneliner FROM mads WHERE id=$mad
            } {}

            # NEXT, Adjust the level
            set inputId [aram coop adjust $driver $n $f $g $delta]

            # NEXT, send ADJUST-2-1 report
            set text [edamrule longname ADJUST-2-1]
            append text "\n\n"

            set fmt "%-22s %s\n"

            append text [format $fmt "Magic Attitude Driver:" $mad]
            append text [format $fmt "Description:"           $oneliner]
            append text [format $fmt "GRAM Driver ID:"        $driver]
            append text [format $fmt "Input ID:"           "$driver.$inputId"]
            append text [format $fmt "Neighborhood:"          $n]
            append text [format $fmt "Civ Group:"             $f]
            append text [format $fmt "Frc Group:"             $g]

            set deltaText [format "%.3f (%s)" $delta [qmag name $delta]]
            append text [format $fmt "Delta:"        $deltaText]

            set reportid \
                [report save \
                     -type    DAM                                          \
                     -subtype ADJUST                                       \
                     -meta1   ADJUST-2-1                                   \
                     -title   "ADJUST-2-1: [edamrule longname ADJUST-2-1]" \
                     -text    $text]

            # NEXT, notify the app.
            # Note: need to update ::sat since current sat has changed,
            # and need to update ::mad since number of inputs for this
            # MAD has changed.
            notifier send ::coop <Entity> update [list $n $f $g]
            notifier send ::mad <Entity> update $mad

            # NEXT, Return the undo command
            return [mytypemethod RestoreCoop $mad $driver $n $f $g $oldCoop \
                       $reportid]
        }
    }


    # mutate coopset parmdict
    #
    # parmdict    A dictionary of order parameters
    #
    #    n                Neighborhood ID
    #    f                CIV group ID
    #    g                FRC group ID
    #    mad              MAD ID
    #    coop             New level, a qcooperation(n) value.
    #
    # Sets a cooperation level to a new value given the parms, 
    # which are presumed to be valid.

    typemethod {mutate coopset} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            # FIRST, get the undo information
            set oldCoop [aram coop.nfg $n $f $g]

            # NEXT, get the GRAM driver ID.
            rdb eval {
                SELECT driver, oneliner FROM mads WHERE id=$mad
            } {}

            # NEXT, Set the level
            set inputId [aram coop set $driver $n $f $g $coop]

            # NEXT, send ADJUST-2-2 report
            set text [edamrule longname ADJUST-2-2]
            append text "\n\n"

            set fmt "%-22s %s\n"

            append text [format $fmt "Magic Attitude Driver:" $mad]
            append text [format $fmt "Description:"           $oneliner]
            append text [format $fmt "GRAM Driver ID:"        $driver]
            append text [format $fmt "Input ID:"           "$driver.$inputId"]
            append text [format $fmt "Neighborhood:"          $n]
            append text [format $fmt "Civ Group:"             $f]
            append text [format $fmt "Frc Group:"             $g]

            set coopText [format "%.3f (%s)" $coop [qcooperation name $coop]]
            append text [format $fmt "New Value:"    $coopText]

            set reportid \
                [report save \
                     -type    DAM                                          \
                     -subtype ADJUST                                       \
                     -meta1   ADJUST-2-2                                   \
                     -title   "ADJUST-2-2: [edamrule longname ADJUST-2-2]" \
                     -text    $text]

            # NEXT, notify the app.
            # Note: need to update ::sat since current sat has changed,
            # and need to update ::mad since number of inputs for this
            # MAD has changed.
            notifier send ::coop <Entity> update [list $n $f $g]
            notifier send ::mad <Entity> update $mad

            # NEXT, Return the undo command
            return [mytypemethod RestoreCoop $mad $driver $n $f $g $oldCoop \
                       $reportid]
        }
    }

    # RestoreCoop mad driver n f g coop reportid
    #
    # Restores a cooperation level to its previous value on undo.

    typemethod RestoreCoop {mad driver n f g coop reportid} {
        aram coop set $driver $n $f $g $coop -undo
        reporter delete $reportid
        notifier send ::coop <Entity> update [list $n $f $g]
        notifier send ::mad <Entity> update $mad
    }

    # mutate cooplevel parmdict
    #
    # parmdict    A dictionary of order parameters
    #
    #    n                Neighborhood ID
    #    f                Civilian Group ID
    #    g                Force Group ID
    #    mad              MAD ID
    #    level            A qmag(n) value
    #    days             An rdays(n) value
    #    cause            "DRIVER", or an ecause(n) value
    #    p                A fraction
    #    q                A fraction
    #
    # Makes the MAGIC-2-1 rule fire for the given input.
    
    typemethod {mutate cooplevel} {parmdict} {
        dict with parmdict {
            # FIRST, get the GRAM driver ID
            rdb eval {SELECT driver,oneliner FROM mads WHERE id=$mad} {}

            # NEXT, get the cause.
            if {$cause eq "DRIVER"} {
                set cause [format "MAD%04d" $mad]
            }

            dam ruleset MAGIC $driver \
                -n     $n             \
                -f     $f             \
                -doer  $g             \
                -cause $cause         \
                -p     $p             \
                -q     $q

            detail "Magic Attitude Driver:" $mad
            detail "Description:"           $oneliner
            detail "GRAM Driver ID:"        $driver

            dam rule MAGIC-2-1 {1} {
                dam coop level -- $limit $days
            }
        }

        # NEXT, cannot be undone.
        return
    }


    # mutate coopslope parmdict
    #
    # parmdict    A dictionary of order parameters
    #
    #    n                Neighborhood ID
    #    f                Civilian Group ID
    #    g                Force Group ID
    #    mad              MAD ID
    #    slope            A qmag(n) value
    #    cause            "DRIVER", or an ecause(n) value
    #    p                A fraction
    #    q                A fraction
    #
    # Makes the MAGIC-2-2 rule fire for the given input.
    
    typemethod {mutate coopslope} {parmdict} {
        dict with parmdict {
            # FIRST, get the GRAM driver ID
            rdb eval {SELECT driver,oneliner FROM mads WHERE id=$mad} {}

            # NEXT, get the cause.
            if {$cause eq "DRIVER"} {
                set cause [format "MAD%04d" $mad]
            }

            dam ruleset MAGIC $driver \
                -n     $n             \
                -f     $f             \
                -doer  $g             \
                -cause $cause         \
                -p     $p             \
                -q     $q

            detail "Magic Attitude Driver:" $mad
            detail "Description:"           $oneliner
            detail "GRAM Driver ID:"        $driver

            dam rule MAGIC-2-2 {1} {
                dam coop slope -- $slope
            }
        }

        # NEXT, cannot be undone.
        return
    }


    #-------------------------------------------------------------------
    # Order Helpers

    # detail label value
    #
    # Adds a detail to the rule input details
   
    proc detail {label value} {
        dam details [format "%-22s %s\n" $label $value]
    }

    # RefreshConcern field parmdict
    #
    # field     The "c" field in MAD:SAT:LEVEL or MAD:SAT:SLOPE
    # parmdict  The current values of the various fields
    #
    # Sets the valid concern values given "g".

    typemethod RefreshConcern {field parmdict} {
        dict with parmdict {
            set gtype [group gtype $g]
            
            switch -exact -- $gtype {
                CIV     {set values [ptype civc names]}
                ORG     {set values [ptype orgc names]}
                default {set values [list]}
            }

            $field configure -values $values

            if {[llength $values] > 0} {
                $field configure -state normal
            } else {
                $field configure -state disabled
            }
        }
    }
}

#-------------------------------------------------------------------
# Orders: MAD:*

# MAD:CREATE
#
# Creates a new MAD.

order define ::mad MAD:CREATE {
    title "Create Magic Attitude Driver"

    options -sendstates {PREP PAUSED}

    parm oneliner text  "Description" 
} {
    # FIRST, prepare and validate the parameters
    prepare oneliner   -required

    returnOnError -final

    # NEXT, create the mad
    lappend undo [$type mutate create [array get parms]]

    setundo [join $undo \n]
}


# MAD:DELETE
#
# Deletes a MAD in the initial state

order define ::mad MAD:DELETE {
    title "Delete Magic Attitude Driver"
    options \
        -table      gui_mads_initial \
        -sendstates {PREP PAUSED}


    parm id key "MAD ID" -tags mad -display longid
} {
    # FIRST, prepare the parameters
    prepare id -toupper -required -type {mad initial}

    returnOnError -final

    # NEXT, make sure the user knows what he is getting into.

    if {[interface] eq "gui"} {
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
    lappend undo [$type mutate delete $parms(id)]

    setundo [join $undo \n]
}


# MAD:UPDATE
#
# Updates an existing mad's description

order define ::mad MAD:UPDATE {
    title "Update Magic Attitude Driver"
    options \
        -table       gui_mads  \
        -sendstates  {PREP PAUSED}

    parm id       key   "MAD ID" -tags mad -display longid
    parm oneliner text  "Description"
} {
    # FIRST, prepare the parameters
    prepare id         -required -type mad
    prepare oneliner   -required

    returnOnError -final

    # NEXT, update the MAD
    lappend undo [$type mutate update [array get parms]]

    setundo [join $undo \n]
}

# MAD:TERMINATE
#
# Terminates all magic slope inputs for a MAD.

order define ::mad MAD:TERMINATE {
    title "Terminate Magic Slope Inputs"
    options \
        -alwaysunsaved                 \
        -sendstates     {}             \
        -schedulestates {PREP PAUSED}  \
        -table          gui_mads       \
        -tags           id

    parm id       key  "MAD ID"   -tags mad -display longid
} {
    # FIRST, prepare the parameters
    prepare id            -required -type mad

    returnOnError -final

    # NEXT, modify the curve
    $type mutate terminate $parms(id)

    return
}

# MAD:SAT:ADJUST
#
# Adjusts a satisfaction curve by some delta.

order define ::mad MAD:SAT:ADJUST {
    title "Magic Adjust Satisfaction Level"
    options \
        -alwaysunsaved                 \
        -sendstates     PAUSED         \
        -schedulestates {PREP PAUSED}  \
        -table          gui_sat_ngc    \
        -tags           ngc

    parm n         key   "Neighborhood"  -tags nbhood
    parm g         key   "Group"         -tags group
    parm c         key   "Concern"       -tags concern
    parm mad       enum  "MAD ID"        -tags mad -type mad -displaylong
    parm delta     text  "Delta"
} {
    # FIRST, prepare the parameters
    prepare n     -toupper -required -type nbhood
    prepare g     -toupper -required -type [list sat group]
    prepare c     -toupper -required -type econcern
    prepare mad            -required -type mad
    prepare delta -toupper -required -type qmag -xform [list qmag value]

    returnOnError

    # NEXT, do cross-validation
    validate c {
        sat validate [list $parms(n) $parms(g) $parms(c)]
    }

    returnOnError -final

    # NEXT, modify the curve
    setundo [$type mutate satadjust [array get parms]]
}


# MAD:SAT:SET
#
# Sets a satisfaction curve to some value.

order define ::mad MAD:SAT:SET {
    title "Magic Set Satisfaction Level"
    options \
        -alwaysunsaved                 \
        -sendstates     PAUSED         \
        -schedulestates {PREP PAUSED}  \
        -table          gui_sat_ngc    \
        -tags           ngc

    parm n         key   "Neighborhood"  -tags nbhood
    parm g         key   "Group"         -tags group
    parm c         key   "Concern"       -tags concern
    parm mad       enum  "MAD ID"        -tags mad -type mad -displaylong
    parm sat       text  "New Value"
} {
    # FIRST, prepare the parameters
    prepare n     -toupper -required -type nbhood
    prepare g     -toupper -required -type [list sat group]
    prepare c     -toupper -required -type econcern
    prepare mad            -required -type mad
    prepare sat   -toupper -required -type qsat -xform [list qsat value]

    returnOnError

    # NEXT, do cross-validation
    validate c {
        sat validate [list $parms(n) $parms(g) $parms(c)]
    }

    returnOnError -final

    # NEXT, modify the curve
    setundo [$type mutate satset [array get parms]]
}


# MAD:SAT:LEVEL
#
# Enters a magic satisfaction level input.

order define ::mad MAD:SAT:LEVEL {
    title "Magic Satisfaction Level Input"
    options \
        -alwaysunsaved                 \
        -sendstates     {}             \
        -schedulestates {PREP PAUSED}

    parm n         enum  "Neighborhood"  -tags nbhood  -type nbhood
    parm g         enum  "Group"         -tags group   -type {ptype satg}
    parm c         enum  "Concern"       -tags concern \
        -refreshcmd [list ::mad RefreshConcern]
    parm mad       enum  "MAD ID"        -tags mad -type mad -displaylong
    parm limit     text  "Limit"
    parm days      text  "Realization Time" -defval 2.0
    parm cause     enum  "Cause"         -type {ptype ecause+driver}
    parm p         text  "Near Factor"                -defval 0.0
    parm q         text  "Far Factor"                 -defval 0.0
    
} {
    # FIRST, prepare the parameters
    prepare n     -toupper -required -type nbhood
    prepare g     -toupper -required -type {ptype satg}
    prepare c     -toupper -required -type {ptype c}
    prepare mad            -required -type mad
    prepare limit -toupper -required -type qmag -xform [list qmag value]
    prepare days           -required -type rdays
    prepare cause -toupper -required -type {ptype ecause+driver}
    prepare p              -required -type rfraction
    prepare q              -required -type rfraction

    returnOnError

    # NEXT, do cross-validation
    validate c {
        set gtype [group gtype $parms(g)]
        
        switch -exact -- $gtype {
            CIV     { ptype civc validate $parms(c) }
            ORG     { ptype orgc validate $parms(c) }
            default { error "Unexpected gtype: \"$gtype\""   }
        }
    }

    returnOnError -final

    # NEXT, modify the curve
    $type mutate satlevel [array get parms]

    return
}


# MAD:SAT:SLOPE
#
# Enters a magic satisfaction slope input.

order define ::mad MAD:SAT:SLOPE {
    title "Magic Satisfaction Slope Input"
    options \
        -alwaysunsaved                 \
        -sendstates     {}             \
        -schedulestates {PREP PAUSED}

    parm n         enum  "Neighborhood"  -tags nbhood  -type nbhood
    parm g         enum  "Group"         -tags group   -type {ptype satg}
    parm c         enum  "Concern"       -tags concern \
        -refreshcmd [list ::mad RefreshConcern]
    parm mad       enum  "MAD ID"        -tags mad -type mad -displaylong
    parm slope     text  "Slope"
    parm cause     enum  "Cause"         -type {ptype ecause+driver}
    parm p         text  "Near Factor"   -defval 0.0
    parm q         text  "Far Factor"    -defval 0.0
} {
    # FIRST, prepare the parameters
    prepare n     -toupper -required -type nbhood
    prepare g     -toupper -required -type {ptype satg}
    prepare c     -toupper -required -type {ptype c}
    prepare mad            -required -type mad
    prepare slope -toupper -required -type qmag -xform [list qmag value]
    prepare cause -toupper -required -type {ptype ecause+driver}
    prepare p              -required -type rfraction
    prepare q              -required -type rfraction

    returnOnError

    # NEXT, do cross-validation
    validate c {
        set gtype [group gtype $parms(g)]
        
        switch -exact -- $gtype {
            CIV     { ptype civc validate $parms(c) }
            ORG     { ptype orgc validate $parms(c) }
            default { error "Unexpected gtype: \"$gtype\""   }
        }
    }

    returnOnError -final

    # NEXT, modify the curve
    $type mutate satslope [array get parms]

    return
}


# MAD:COOP:ADJUST
#
# Adjusts a cooperation curve by some delta.

order define ::mad MAD:COOP:ADJUST {
    title "Magic Adjust Cooperation Level"
    options \
        -alwaysunsaved                 \
        -sendstates     PAUSED         \
        -schedulestates {PREP PAUSED}  \
        -table          gui_coop_nfg   \
        -tags           nfg

    parm n         key   "Neighborhood"  -tags nbhood
    parm f         key   "Of Group"      -tags group
    parm g         key   "With Group"    -tags group
    parm mad       enum  "MAD ID"        -tags mad -type mad -displaylong
    parm delta     text  "Delta"
} {
    # FIRST, prepare the parameters
    prepare n     -toupper -required -type nbhood
    prepare f     -toupper -required -type civgroup
    prepare g     -toupper -required -type frcgroup
    prepare mad            -required -type mad
    prepare delta -toupper -required -type qmag -xform [list qmag value]

    returnOnError

    # NEXT, do cross-validation
    validate f {
        coop validate [list $parms(n) $parms(f) $parms(g)]
    }

    returnOnError -final

    # NEXT, modify the curve
    setundo [$type mutate coopadjust [array get parms]]
}


# MAD:COOP:SET
#
# Sets a cooperation curve to some value.

order define ::mad MAD:COOP:SET {
    title "Magic Set Cooperation Level"
    options \
        -alwaysunsaved                 \
        -sendstates     PAUSED         \
        -schedulestates {PREP PAUSED}  \
        -table          gui_coop_nfg   \
        -tags           nfg

    parm n         key   "Neighborhood"  -tags nbhood
    parm f         key   "Of Group"      -tags group
    parm g         key   "With Group"    -tags group
    parm mad       enum  "MAD ID"        -tags mad -type mad -displaylong
    parm coop      text  "New Value"
} {
    # FIRST, prepare the parameters
    prepare n     -toupper -required -type nbhood
    prepare f     -toupper -required -type civgroup
    prepare g     -toupper -required -type frcgroup
    prepare mad            -required -type mad
    prepare coop  -toupper -required -type qcooperation \
        -xform [list qcooperation value]

    returnOnError

    # NEXT, do cross-validation
    validate f {
        coop validate [list $parms(n) $parms(f) $parms(g)]
    }

    returnOnError -final

    # NEXT, modify the curve
    setundo [$type mutate coopset [array get parms]]
}


# MAD:COOP:LEVEL
#
# Enters a magic cooperation level input.

order define ::mad MAD:COOP:LEVEL {
    title "Magic Cooperation Level Input"
    options \
        -alwaysunsaved                 \
        -sendstates     {}             \
        -schedulestates {PREP PAUSED}

    parm n         enum  "Neighborhood"  -tags nbhood -type nbhood
    parm f         enum  "Of Group"      -tags group  -type civgroup
    parm g         enum  "With Group"    -tags group  -type frcgroup
    parm mad       enum  "MAD ID"        -tags mad -type mad -displaylong
    parm limit     text  "Limit"
    parm days      text  "Days"                       -defval 2.0
    parm cause     enum  "Cause"         -type {ptype ecause+driver}
    parm p         text  "Near Factor"                -defval 0.0
    parm q         text  "Far Factor"                 -defval 0.0
    
} {
    # FIRST, prepare the parameters
    prepare n     -toupper -required -type nbhood
    prepare f     -toupper -required -type civgroup
    prepare g     -toupper -required -type frcgroup
    prepare mad            -required -type mad
    prepare limit -toupper -required -type qmag -xform [list qmag value]
    prepare days           -required -type rdays
    prepare cause -toupper -required -type {ptype ecause+driver}
    prepare p              -required -type rfraction
    prepare q              -required -type rfraction

    returnOnError -final

    # NEXT, modify the curve
    $type mutate cooplevel [array get parms]

    return
}

# MAD:COOP:SLOPE
#
# Enters a magic cooperation slope input.

order define ::mad MAD:COOP:SLOPE {
    title "Magic Cooperation Slope Input"
    options \
        -alwaysunsaved                 \
        -sendstates     {}             \
        -schedulestates {PREP PAUSED}

    parm n         enum  "Neighborhood"  -tags nbhood -type nbhood
    parm f         enum  "Of Group"      -tags group -type civgroup
    parm g         enum  "With Group"    -tags group -type frcgroup
    parm mad       enum  "MAD ID"        -tags mad -type mad -displaylong
    parm slope     text  "Slope"
    parm cause     enum  "Cause"         -type {ptype ecause+driver}
    parm p         text  "Near Factor"                -defval 0.0
    parm q         text  "Far Factor"                 -defval 0.0
    
} {
    # FIRST, prepare the parameters
    prepare n     -toupper -required -type nbhood
    prepare f     -toupper -required -type civgroup
    prepare g     -toupper -required -type frcgroup
    prepare mad            -required -type mad
    prepare slope -toupper -required -type qmag -xform [list qmag value]
    prepare cause -toupper -required -type {ptype ecause+driver}
    prepare p              -required -type rfraction
    prepare q              -required -type rfraction

    returnOnError -final

    # NEXT, modify the curve
    $type mutate coopslope [array get parms]

    return
}
