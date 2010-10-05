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
            set id [rdb onecolumn {
                SELECT COALESCE(max(id)+1, 1) FROM mads
            }]

            # FIRST, Put the MAD in the database
            rdb eval {
                INSERT INTO mads(id,oneliner,cause,s,p,q)
                VALUES($id,
                       $oneliner,
                       $cause,
                       $s,
                       $p,
                       $q);
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
    #   oneliner     A new description, or ""
    #   cause        "UNIQUE", or an ecause(n) value, or ""
    #   s            A fraction, or ""
    #   p            A fraction, or ""
    #   q            A fraction, or ""
    #
    # Updates the MAD given the parms, which are presumed to be
    # valid.
    #
    # Note that cause, p, and q should only be entered if no
    # magic inputs have been entered for this MAD.

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
                SET oneliner = nonempty($oneliner, oneliner),
                    cause    = nonempty($cause,    cause),
                    s        = nonempty($s,        s),
                    p        = nonempty($p,        p),
                    q        = nonempty($q,        q)
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
                 -rtype   DAM                                        \
                 -subtype MAGIC                                      \
                 -meta1   MAGIC-3-1                                  \
                 -title   "MAGIC-3-1: [edamrule longname MAGIC-3-1]" \
                 -text    $text]

        # NEXT, cannot be undone.
        return
    }


    # mutate satadjust parmdict
    #
    # parmdict    A dictionary of order parameters
    #
    #    id               list {n g c}
    #    mad              MAD ID
    #    delta            Delta to the level, a qmag(n) value.
    #
    # Adjusts a satisfaction level by a delta given the parms, 
    # which are presumed to be valid.

    typemethod {mutate satadjust} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            lassign $id n g c

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
                     -rtype   DAM                                          \
                     -subtype ADJUST                                       \
                     -meta1   ADJUST-1-1                                   \
                     -title   "ADJUST-1-1: [edamrule longname ADJUST-1-1]" \
                     -text    $text]

            # NEXT, notify the app.
            # Note: need to update ::sat since current sat has changed,
            # and need to update ::mad since number of inputs for this
            # MAD has changed.
            notifier send ::sat <Entity> update $id
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
    #    id               list {n g c}
    #    mad              MAD ID
    #    sat              New qsat(n) value
    #
    # Sets a satisfaction level to a particular value given the parms, 
    # which are presumed to be valid.

    typemethod {mutate satset} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            lassign $id n g c

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
                     -rtype   DAM                                          \
                     -subtype ADJUST                                       \
                     -meta1   ADJUST-1-2                                   \
                     -title   "ADJUST-1-2: [edamrule longname ADJUST-1-2]"  \
                     -text    $text]

            # NEXT, notify the app.
            # Note: need to update ::sat since current sat has changed,
            # and need to update ::mad since number of inputs for this
            # MAD has changed.
            notifier send ::sat <Entity> update $id
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
    #    athresh          Ascending threshold, a qsat(n) value
    #    dthresh          Descending threshold, a qsat(n) value
    #
    # Makes the MAGIC-1-1 rule fire for the given input.
    
    typemethod {mutate satlevel} {parmdict} {
        dict with parmdict {
            # FIRST, get the GRAM driver ID
            rdb eval {
                SELECT driver,oneliner,cause,s,p,q FROM mads WHERE id=$mad
            } {}

            # NEXT, get the cause.
            if {$cause eq "UNIQUE"} {
                set cause [format "MAD%04d" $mad]
            }

            dam ruleset MAGIC $driver \
                -n     $n             \
                -f     $g             \
                -cause $cause         \
                -s     $s             \
                -p     $p             \
                -q     $q

            detail "Magic Attitude Driver:" $mad
            detail "Description:"           $oneliner
            detail "GRAM Driver ID:"        $driver

            dam rule MAGIC-1-1 {1} {
                dam sat level         \
                    -athresh $athresh \
                    -dthresh $dthresh \
                    $c $limit $days
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
    #    athresh          Ascending threshold, a qsat(n) value
    #    dthresh          Descending threshold, a qsat(n) value
    #
    # Makes the MAGIC-1-2 rule fire for the given input.
    
    typemethod {mutate satslope} {parmdict} {
        dict with parmdict {
            # FIRST, get the GRAM driver ID
            rdb eval {
                SELECT driver,oneliner,cause,s,p,q FROM mads WHERE id=$mad
            } {}

            # NEXT, get the cause.
            if {$cause eq "UNIQUE"} {
                set cause [format "MAD%04d" $mad]
            }

            dam ruleset MAGIC $driver \
                -n     $n             \
                -f     $g             \
                -cause $cause         \
                -s     $s             \
                -p     $p             \
                -q     $q

            detail "Magic Attitude Driver:" $mad
            detail "Description:"           $oneliner
            detail "GRAM Driver ID:"        $driver

            dam rule MAGIC-1-2 {1} {
                dam sat slope         \
                    -athresh $athresh \
                    -dthresh $dthresh \
                    $c $slope
            }
        }

        # NEXT, cannot be undone.
        return
    }


    # mutate coopadjust parmdict
    #
    # parmdict    A dictionary of order parameters
    #
    #    id               list {n f g}
    #    mad              MAD ID
    #    delta            Delta to the level, a qmag(n) value.
    #
    # Adjusts a cooperation level by a delta given the parms, 
    # which are presumed to be valid.

    typemethod {mutate coopadjust} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            lassign $id n f g

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
                     -rtype   DAM                                          \
                     -subtype ADJUST                                       \
                     -meta1   ADJUST-2-1                                   \
                     -title   "ADJUST-2-1: [edamrule longname ADJUST-2-1]" \
                     -text    $text]

            # NEXT, notify the app.
            # Note: need to update ::sat since current sat has changed,
            # and need to update ::mad since number of inputs for this
            # MAD has changed.
            notifier send ::coop <Entity> update $id
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
    #    id               list {n f g}
    #    mad              MAD ID
    #    coop             New level, a qcooperation(n) value.
    #
    # Sets a cooperation level to a new value given the parms, 
    # which are presumed to be valid.

    typemethod {mutate coopset} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            lassign $id n f g
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
                     -rtype   DAM                                          \
                     -subtype ADJUST                                       \
                     -meta1   ADJUST-2-2                                   \
                     -title   "ADJUST-2-2: [edamrule longname ADJUST-2-2]" \
                     -text    $text]

            # NEXT, notify the app.
            # Note: need to update ::sat since current sat has changed,
            # and need to update ::mad since number of inputs for this
            # MAD has changed.
            notifier send ::coop <Entity> update $id
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
    #    athresh          Ascending threshold, a qcooperation(n) value
    #    dthresh          Descending threshold, a qcooperation(n) value
    #
    # Makes the MAGIC-2-1 rule fire for the given input.
    
    typemethod {mutate cooplevel} {parmdict} {
        dict with parmdict {
            # FIRST, get the GRAM driver ID
            rdb eval {
                SELECT driver,oneliner,cause,s,p,q FROM mads WHERE id=$mad
            } {}

            # NEXT, get the cause.
            if {$cause eq "UNIQUE"} {
                set cause [format "MAD%04d" $mad]
            }

            dam ruleset MAGIC $driver \
                -n     $n             \
                -f     $f             \
                -doer  $g             \
                -cause $cause         \
                -s     $s             \
                -p     $p             \
                -q     $q

            detail "Magic Attitude Driver:" $mad
            detail "Description:"           $oneliner
            detail "GRAM Driver ID:"        $driver

            dam rule MAGIC-2-1 {1} {
                dam coop level        \
                    -athresh $athresh \
                    -dthresh $dthresh \
                    -- $limit $days
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
    #    athresh          Ascending threshold, a qcooperation(n) value
    #    dthresh          Descending threshold, a qcooperation(n) value
    #
    # Makes the MAGIC-2-2 rule fire for the given input.
    
    typemethod {mutate coopslope} {parmdict} {
        dict with parmdict {
            # FIRST, get the GRAM driver ID
            rdb eval {
                SELECT driver,oneliner,cause,s,p,q FROM mads WHERE id=$mad
            } {}

            # NEXT, get the cause.
            if {$cause eq "UNIQUE"} {
                set cause [format "MAD%04d" $mad]
            }

            dam ruleset MAGIC $driver \
                -n     $n             \
                -f     $f             \
                -doer  $g             \
                -cause $cause         \
                -s     $s             \
                -p     $p             \
                -q     $q

            detail "Magic Attitude Driver:" $mad
            detail "Description:"           $oneliner
            detail "GRAM Driver ID:"        $driver

            dam rule MAGIC-2-2 {1} {
                dam coop slope        \
                    -athresh $athresh \
                    -dthresh $dthresh \
                    -- $slope
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

    # Refresh_MU dlg fields fdict
    #
    # dlg       The order dialog
    # fields    A list of the fields that have changed
    # fdict     A dict of the current field values.
    #
    # Loads fields for the current MAD.  Also, the cause, s, p, and q 
    # fields must be disabled if there are inputs for this MAD.

    typemethod Refresh_MU {dlg fields fdict} {
        # FIRST, update fields if the MAD has changed.
        if {"id" in $fields} {
            $dlg loadForKey id
        }

        # NEXT, handle the cause, s, p, and q fields.
        $dlg disabled {}

        dict with fdict {
            if {$id ne ""} {
                set inputs [rdb onecolumn {
                    SELECT inputs FROM gui_mads WHERE id=$id
                }]

                if {$inputs > 0} {
                    $dlg disabled cause s p q
                }
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

    parm oneliner  text  "Description" 
    parm cause     enum  "Cause"         -type   {ptype ecause+unique} \
                                         -defval UNIQUE
    parm s         text  "Here Factor"   -defval 1.0
    parm p         text  "Near Factor"   -defval 0.0
    parm q         text  "Far Factor"    -defval 0.0

} {
    # FIRST, prepare and validate the parameters
    prepare oneliner          -required
    prepare cause    -toupper -required -type {ptype ecause+unique}
    prepare s                 -required -type rfraction
    prepare p                 -required -type rfraction
    prepare q                 -required -type rfraction

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
        -sendstates {PREP PAUSED}


    parm id key "MAD ID" -table    gui_mads_initial \
                         -key      id               \
                         -dispcols longid
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
        -sendstates  {PREP PAUSED}      \
        -refreshcmd  {::mad Refresh_MU}

    parm id       key   "MAD ID"        -table    gui_mads \
                                        -key      id       \
                                        -dispcols longid
    parm oneliner text  "Description"
    parm cause    enum  "Cause"         -type     {ptype ecause+unique}
    parm s        text  "Here Factor"
    parm p        text  "Near Factor"
    parm q        text  "Far Factor" 
} {
    # FIRST, prepare the parameters
    prepare id       -required -type mad
    prepare oneliner
    prepare cause    -toupper -type {ptype ecause+unique}
    prepare s                 -type rfraction
    prepare p                 -type rfraction
    prepare q                 -type rfraction

    returnOnError

    # NEXT, cause, s, p, and q should only be changed if there are no
    # inputs.
    set inputs [rdb onecolumn {SELECT inputs FROM gui_mads WHERE id=$id}]

    validate cause {
        if {$inputs > 0} {
            reject cause \
                "Cannot change cause once magic inputs have been made."
        }
    }

    validate s {
        if {$inputs > 0} {
            reject s \
                "Cannot change here factor once magic inputs have been made."
        }
    }

    validate p {
        if {$inputs > 0} {
            reject p \
                "Cannot change near factor once magic inputs have been made."
        }
    }

    validate q {
        if {$inputs > 0} {
            reject q \
                "Cannot change far factor once magic inputs have been made."
        }
    }

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
        -sendstates     {}             \
        -schedulestates {PREP PAUSED}

    parm id       key   "MAD ID"        -table    gui_mads  \
                                        -key      id        \
                                        -dispcols longid
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
        -sendstates     PAUSED         \
        -schedulestates {PREP PAUSED}

    parm id        key   "Curve"     -table gui_sat_ngc  \
                                     -key {n g c}
    parm mad       key   "MAD ID"    -table    gui_mads  \
                                     -key      id        \
                                     -dispcols longid
    parm delta     text  "Delta"
} {
    # FIRST, prepare the parameters
    prepare id    -toupper -required -type sat
    prepare mad            -required -type mad
    prepare delta -toupper -required -type qmag -xform [list qmag value]

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
        -sendstates     PAUSED         \
        -schedulestates {PREP PAUSED}

    parm id        key   "Curve"     -table gui_sat_ngc  \
                                     -key {n g c}
    parm mad       key   "MAD ID"    -table    gui_mads  \
                                     -key      id        \
                                     -dispcols longid
    parm sat       text  "New Value"
} {
    # FIRST, prepare the parameters
    prepare id    -toupper -required -type sat
    prepare mad            -required -type mad
    prepare sat   -toupper -required -type qsat -xform [list qsat value]

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
        -sendstates     {}             \
        -schedulestates {PREP PAUSED}

    parm n         enum  "Neighborhood"        -type     nbhood       \
                                               -tags     nbhood
    parm g         enum  "Group"               -type     civgroup
    parm c         enum  "Concern"             -type     {ptype civc}
    parm mad       key   "MAD ID"              -table    gui_mads     \
                                               -key      id           \
                                               -dispcols longid
    parm limit     text  "Limit"
    parm days      text  "Realization Time"    -defval 2.0
    parm athresh   text  "Ascending Theshold"  -defval 100.0
    parm dthresh   text  "Descending Theshold" -defval -100.0
} {
    # FIRST, prepare the parameters
    prepare n       -toupper -required -type nbhood
    prepare g       -toupper -required -type civgroup
    prepare c       -toupper -required -type {ptype civc}
    prepare mad              -required -type mad
    prepare limit   -toupper -required -type qmag -xform [list qmag value]
    prepare days             -required -type rdays
    prepare athresh          -required -type qsat -xform [list qsat value]
    prepare dthresh          -required -type qsat -xform [list qsat value]

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
        -sendstates     {}             \
        -schedulestates {PREP PAUSED}

    parm n         enum  "Neighborhood"        -type     nbhood       \
                                               -tags nbhood  
    parm g         enum  "Group"               -type     civgroup
    parm c         enum  "Concern"             -type     {ptype civc}
    parm mad       key   "MAD ID"              -table    gui_mads     \
                                               -key      id           \
                                               -dispcols longid
    parm slope     text  "Slope"
    parm athresh   text  "Ascending Theshold"  -defval 100.0
    parm dthresh   text  "Descending Theshold" -defval -100.0
} {
    # FIRST, prepare the parameters
    prepare n       -toupper -required -type nbhood
    prepare g       -toupper -required -type civgroup
    prepare c       -toupper -required -type {ptype civc}
    prepare mad              -required -type mad
    prepare slope   -toupper -required -type qmag -xform [list qmag value]
    prepare athresh          -required -type qsat -xform [list qsat value]
    prepare dthresh          -required -type qsat -xform [list qsat value]

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
        -sendstates     PAUSED         \
        -schedulestates {PREP PAUSED}

    parm id        key   "Curve"     -table gui_coop_nfg  \
                                     -key {n f g}
    parm mad       key   "MAD ID"    -table    gui_mads  \
                                     -key      id        \
                                     -dispcols longid
    parm delta     text  "Delta"
} {
    # FIRST, prepare the parameters
    prepare id    -toupper -required -type coop
    prepare mad            -required -type mad
    prepare delta -toupper -required -type qmag -xform [list qmag value]

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
        -sendstates     PAUSED         \
        -schedulestates {PREP PAUSED}

    parm id        key   "Curve"     -table gui_coop_nfg  \
                                     -key {n f g}
    parm mad       key   "MAD ID"    -table    gui_mads  \
                                     -key      id        \
                                     -dispcols longid
    parm coop      text  "New Value"
} {
    # FIRST, prepare the parameters
    prepare id    -toupper -required -type coop
    prepare mad            -required -type mad
    prepare coop  -toupper -required -type qcooperation \
        -xform [list qcooperation value]

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
        -sendstates     {}             \
        -schedulestates {PREP PAUSED}

    parm n         enum  "Neighborhood"        -type     nbhood   \
                                               -tags     nbhood 
    parm f         enum  "Of Group"            -type     civgroup
    parm g         enum  "With Group"          -type     frcgroup
    parm mad       key   "MAD ID"              -table    gui_mads \
                                               -key      id       \
                                               -dispcols longid
    parm limit     text  "Limit"
    parm days      text  "Days"                -defval 2.0
    parm athresh   text  "Ascending Theshold"  -defval 100.0
    parm dthresh   text  "Descending Theshold" -defval 0.0
} {
    # FIRST, prepare the parameters
    prepare n       -toupper -required -type nbhood
    prepare f       -toupper -required -type civgroup
    prepare g       -toupper -required -type frcgroup
    prepare mad              -required -type mad
    prepare limit   -toupper -required -type qmag -xform [list qmag value]
    prepare days             -required -type rdays
    prepare athresh          -required -type qcooperation \
        -xform [list qcooperation value]
    prepare dthresh          -required -type qcooperation \
        -xform [list qcooperation value]

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
        -sendstates     {}             \
        -schedulestates {PREP PAUSED}

    parm n         enum  "Neighborhood"        -type     nbhood   \
                                               -tags     nbhood 
    parm f         enum  "Of Group"            -type     civgroup
    parm g         enum  "With Group"          -type     frcgroup
    parm mad       key   "MAD ID"              -table    gui_mads \
                                               -key      id       \
                                               -dispcols longid
    parm slope     text  "Slope"
    parm athresh   text  "Ascending Theshold"  -defval 100.0
    parm dthresh   text  "Descending Theshold" -defval 0.0
} {
    # FIRST, prepare the parameters
    prepare n       -toupper -required -type nbhood
    prepare f       -toupper -required -type civgroup
    prepare g       -toupper -required -type frcgroup
    prepare mad              -required -type mad
    prepare slope   -toupper -required -type qmag -xform [list qmag value]
    prepare athresh          -required -type qcooperation \
        -xform [list qcooperation value]
    prepare dthresh          -required -type qcooperation \
        -xform [list qcooperation value]

    returnOnError -final

    # NEXT, modify the curve
    $type mutate coopslope [array get parms]

    return
}
