#-----------------------------------------------------------------------
# TITLE:
#   driver_curse.tcl
#
# AUTHOR:
#   Dave Hanks
#
# DESCRIPTION:
#    Athena Complex User-defined Role-based Situations and Events (CURSE)
#    module: CURSE
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# CURSE 

driver type define CURSE {curse_id} {
    #-------------------------------------------------------------------
    # Public Type Methods

    # assess fdict
    #
    # fdict - A MAGIC rule firing dictionary; see "ruleset", below.
    #
    # Assesses a particular magic input.

    typemethod assess {fdict} {
        # FIRST, if the rule set is inactive, skip it.
        if {![parmdb get dam.CURSE.active]} {
            log warning CURSE \
                "driver type has been deactivated"
            return
        }

        $type ruleset $fdict
    }

    #-------------------------------------------------------------------
    # Narrative Type Methods

    # sigline signature
    #
    # signature - The driver signature
    #
    # Returns a one-line description of the driver given its signature
    # values.

    typemethod sigline {signature} {
        # The signature is the curse_id
        return [rdb onecolumn {
            SELECT longname FROM curses WHERE curse_id=$signature
        }]
    }

    # narrative fdict
    #
    # fdict - Firing dictionary
    #
    # Produces a one-line narrative text string for a given rule firing

    typemethod narrative {fdict} {
        dict with fdict {}

        switch -exact -- $atype {
            coop { set crv "[join $f {, }] with [join $g {, }]" }
            hrel { set crv "[join $f {, }] with [join $g {, }]" }
            sat  { set crv "[join $g {, }] with $c" }
            vrel { set crv "[join $g {, }] with [join $a {, }]" }
            default {error "unexpected atype: \"$atype\""}
        }

        return "CURSE {curse:$curse_id} $atype $mode $crv [format %.1f $mag]"
    }
    
    # detail fdict 
    #
    # fdict - Firing dictionary
    # ht    - An htools(n) buffer
    #
    # Produces a narrative HTML paragraph including all fdict information.

    typemethod detail {fdict ht} {
        dict with fdict {}

        # FIRST, load the mad data.
        rdb eval {
            SELECT * FROM curses WHERE curse_id=$curse_id
        } curse {}

        $ht link my://app/curse/$curse_id "CURSE $curse_id"
        $ht put ": $curse(longname)"
        $ht para
    }

    #-------------------------------------------------------------------
    # Rule Set: CURSE --
    #    Complex User-defined Role-based Situations and Events

    # ruleset fdict
    #
    # fdict - Dictionary containing CURSE data
    #
    #   dtype     - CURSE
    #   curse_id  - CURSE ID
    #   atype     - coop | hrel | sat | vrel
    #   mode      - P | T
    #   cause     - The cause, or UNIQUE for a unique cause
    #   mag       - Magnitude (numeric)
    #   f         - groups (if coop or hrel)
    #   g         - groups (if coop, hrel, sat, or vrel)
    #   c         - concern (if sat)
    #   a         - actors (if vrel)
    #
    # Executes the rule set for the magic input

    typemethod ruleset {fdict} {
        dict with fdict {}
        log detail CURSE $fdict

        # FIRST, check group populations, so that we can skip empty
        # civilian groups.
        set flist {}
        set glist {}

        if {[dict exists $fdict f]} {
            foreach grp $f {
                if {$grp ni [civgroup names]} {
                    lappend flist $grp 
                } elseif {[demog getg $grp population]} {
                    lappend flist $grp
                }
            }
        }

        if {[dict exists $fdict g]} {
            foreach grp $g {
                if {$grp ni [civgroup names]} {
                    lappend glist $grp
                } elseif {[demog getg $grp population]} {
                    lappend glist $grp
                }
            }
        }

        # NEXT, load the curse data.
        rdb eval {
            SELECT * FROM curses WHERE curse_id=$curse_id
        } curse {}

        # NEXT, get the cause.  Passing "" will make URAM use the
        # numeric driver ID as the numeric cause ID.
        if {$curse(cause) eq "UNIQUE"} {
            set curse(cause) ""
        }

        lappend opts \
            -cause $curse(cause) \
            -s     $curse(s)     \
            -p     $curse(p)     \
            -q     $curse(q)

        # NEXT, here are the rules.

        dam rule CURSE-1-1 $fdict -cause $curse(cause) {
            $atype eq "hrel"     && 
            [llength $flist] > 0 &&
            [llength $glist] > 0
        } {
            dam hrel $mode $flist $glist $mag
        }

        dam rule CURSE-2-1 $fdict -cause $curse(cause) {
            $atype eq "vrel"     &&
            [llength $glist] > 0 &&
            [llength $a]     > 0
        } {
            dam vrel $mode $glist $a $mag
        }

        dam rule CURSE-3-1 $fdict {*}$opts {
            $atype eq "sat"      &&
            [llength $glist] > 0 
        } {
            dam sat $mode $glist $c $mag
        }

        dam rule CURSE-4-1 $fdict {*}$opts {
            $atype eq "coop"     &&
            [llength $flist] > 0 &&
            [llength $glist] > 0
        } {
            dam coop $mode $flist $glist $mag
        }
    }
}


