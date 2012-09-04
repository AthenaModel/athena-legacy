#-----------------------------------------------------------------------
# TITLE:
#    hrel.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Horizontal Relationship Manager
#
#    By default, the initial baseline horizontal relationships (hrel)
#    are computed from belief systems by the bsystem module, an
#    instance of mam(n), with the exception that rel.gg is always 1.0.
#    The analyst is allowed to override any initial baseline relationship 
#    for which f != g.  The natural relationship is always either 1.0 
#    when f=g and the affinity otherwise.
#
#    These overrides are stored in the hrel_fg table and viewed in
#    hrelbrowser(sim).  The hrel_view view pulls all of the data together.
#
#    Because hrel_fg overrides values computed elsewhere, this
#    module follows a rather different pattern than other scenario
#    editing modules.  The relationships come into being automatically
#    with the groups.  Thus, there is no HREL:CREATE order.  Instead,
#    HREL:OVERRIDE and HREL:OVERRIDE:MULTI will create new records as 
#    needed.  HREL:RESTORE will delete overrides.
#
#    Note that overridden relationships are deleted via cascading
#    delete if the relevant groups are deleted.
#
# NOTE:
#    This module concerns itself only with the scenario inputs.  For
#    the dynamic relationship values, see URAM.
#
#-----------------------------------------------------------------------

snit::type hrel {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Queries

    # validate id
    #
    # id     An fg relationship ID, [list $f $g]
    #
    # Throws INVALID if id doesn't name an overrideable relationship.

    typemethod validate {id} {
        lassign $id f g

        set f [group validate $f]
        set g [group validate $g]

        if {$f eq $g} {
            return -code error -errorcode INVALID \
                "A group's relationship with itself cannot be overridden."
        }

        return [list $f $g]
    }

    # exists id
    #
    # id     An fg relationship ID, [list $f $g]
    #
    # Returns 1 if there's an overridden relationship 
    # between f and g, and 0 otherwise.

    typemethod exists {id} {
        lassign $id f g

        rdb exists {
            SELECT * FROM hrel_fg WHERE f=$f AND g=$g
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
    # parmdict  - A dictionary of hrel parms
    #
    #    id     - list {f g}
    #    base   - The overridden baseline relationship of f with g
    #
    # Creates a relationship record given the parms, which are presumed to be
    # valid.

    typemethod {mutate create} {parmdict} {
        dict with parmdict {
            lassign $id f g

            # FIRST, default hrel to 0.0
            if {$base eq ""} {
                set base 0.0
            }

            # NEXT, Put the group in the database
            rdb eval {
                INSERT INTO 
                hrel_fg(f,g,base)
                VALUES($f, $g, $base);
            }

            # NEXT, Return the undo command
            return [list rdb delete hrel_fg "f='$f' AND g='$g'"]
        }
    }


    # mutate delete id
    #
    # id   - list {f g}
    #
    # Deletes the relationship override.

    typemethod {mutate delete} {id} {
        lassign $id f g

        # FIRST, delete the records, grabbing the undo information
        set data [rdb delete -grab hrel_fg {f=$f AND g=$g}]

        # NEXT, Return the undo script
        return [list rdb ungrab $data]
    }


    # mutate update parmdict
    #
    # parmdict  - A dictionary of group parms
    #
    #    id     - list {f g}
    #    base   - Modified baseline relationship of f with g
    #
    # Updates a baseline relationship override given the parms, which
    # are presumed to be valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            lassign $id f g

            # FIRST, get the undo information
            set data [rdb grab hrel_fg {f=$f AND g=$g}]

            # NEXT, Update the group
            rdb eval {
                UPDATE hrel_fg
                SET base = nonempty($base, base)
                WHERE f=$f AND g=$g
            } {}

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
    }
}


#-------------------------------------------------------------------
# Orders: HREL:*

# HREL:RESTORE
#
# Deletes existing relationship override

order define HREL:RESTORE {
    title "Restore Baseline Horizontal Relationship"
    options \
        -sendstates PREP

    form {
        # Form not used in dialog.
        key id -table gui_hrel_view -keys {f g} -labels {Of With}
    }
} {
    # FIRST, prepare the parameters
    prepare id       -toupper  -required -type hrel

    returnOnError -final

    # NEXT, delete the record
    setundo [hrel mutate delete $parms(id)]
}

# HREL:OVERRIDE
#
# Updates existing override

order define HREL:OVERRIDE {
    title "Override Baseline Horizontal Relationship"
    options -sendstates PREP

    form {
        rcc "Groups:" -for id
        key id -table gui_hrel_view -keys {f g} -labels {Of With} \
            -loadcmd {orderdialog keyload id *}

        rcc "Baseline:" -for base
        rel base
    }
} {
    # FIRST, prepare the parameters
    prepare id       -toupper  -required -type hrel
    prepare base     -toupper  -num      -type qaffinity

    returnOnError -final

    # NEXT, modify the curve
    if {[hrel exists $parms(id)]} {
        setundo [hrel mutate update [array get parms]]
    } else {
        setundo [hrel mutate create [array get parms]]
    }
}


# HREL:OVERRIDE:MULTI
#
# Updates multiple existing relationship overrides

order define HREL:OVERRIDE:MULTI {
    title "Override Multiple Baseline Horizontal Relationships"
    options -sendstates PREP 

    form {
        rcc "IDs:" -for ids
        multi ids -table gui_hrel_view -key id \
            -loadcmd {orderdialog multiload id *}

        rcc "Baseline:" -for base
        rel base
    }
} {
    # FIRST, prepare the parameters
    prepare ids      -toupper  -required -listof hrel
    prepare base     -toupper  -num      -type qaffinity

    returnOnError -final


    # NEXT, modify the records
    set undo [list]

    foreach parms(id) $parms(ids) {
        if {[hrel exists $parms(id)]} {
            lappend undo [hrel mutate update [array get parms]]
        } else {
            lappend undo [hrel mutate create [array get parms]]
        }
    }

    setundo [join $undo \n]
}


