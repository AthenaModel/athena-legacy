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
