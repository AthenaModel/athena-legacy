#-----------------------------------------------------------------------
# TITLE:
#    helpers.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Helper Procs
#
#    Useful procs that don't belong anywhere else.
#
#-----------------------------------------------------------------------

# lprio list item prio
#
# list    A list of unique items
# item    An item in the list
# prio    top, raise, lower, or bottom
#
# Moves the item in the list, and returns the new list.

proc lprio {list item prio} {
    # FIRST, get item's position in the list.
    set index [lsearch -exact $list $item]

    # NEXT, get the new position
    let end {[llength $list] - 1}

    switch -exact -- $prio {
        top     { set newpos 0                       }
        raise   { let newpos {max(0,    $index - 1)} }
        lower   { let newpos {min($end, $index + 1)} }
        bottom  { set newpos $end                    }
        default { error "Unknown prio: \"$prio\""    }
    }

    # NEXT, if the item is already in its position, we're done.
    if {$newpos == $index} {
        return $list
    }

    # NEXT, put the item in its list.
    ldelete list $item
    set list [linsert $list $newpos $item]

    # FINALLY, return the new list.
    return $list
}


# mag* multiplier mag
#
# multiplier    A numeric multiplier
# mag           A qmag(n) value
#
# Returns the numeric value of mag times the multiplier.

proc mag* {multiplier mag} {
    set result [expr {$multiplier * [qmag value $mag]}]

    if {$result == -0.0} {
        set result 0.0
    }

    return $result
}

# mag+ stops mag
#
# stops      Some number of "stops"
# mag        A qmag symbol
#
# Returns the symbolic value of mag, moved up or down the specified
# number of stops, or 0.  I.e., XL +1 stop is XXL; XL -1 stop is L.  
# Stopping up or down never changes the sign.  Stopping down from
# from XXXS returns 0; stopping up from XXXXL returns the value
# of XXXXL.

proc mag+ {stops mag} {
    set symbols [qmag names]
    set index [qmag index $mag]

    if {$index <= 9} {
        # Sign is positive; 0 is XXXXL+, 9 is XXXS+

        let index {$index - $stops}

        if {$index < 0} {
            return [lindex $symbols 0]
        } elseif {$index > 9} {
            return 0
        } else {
            return [lindex $symbols $index]
        }
    } else {
        # Sign is negative; 10 is XXXS-, 19 is XXXXL-

        let index {$index + $stops}

        if {$index > 19} {
            return [lindex $symbols 19]
        } elseif {$index < 10} {
            return 0
        } else {
            return [lindex $symbols $index]
        }
    }


    expr {$stops * [qmag value $mag]}
}


# hrel.fg f g
#
# f    A group
# g    Another group
#
# Returns the relationship of f with g.
#
# TBD: Needs to get data from uram_hrel.

proc hrel.fg {f g} {
    set rel [rdb eval {
        SELECT rel FROM rel_view
        WHERE f=$f AND g=$g
    }]

    return $rel
}

# vrel.ga g a
#
# g - A civ group
# a - An actor
#
# Returns the vertical relationship between the group and the 
# actor.

proc vrel.ga {g a} {
    rdb onecolumn {SELECT vrel FROM vrel_ga WHERE g=$g AND a=$a}
}
