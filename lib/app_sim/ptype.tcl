#-----------------------------------------------------------------------
# TITLE:
#    ptype.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): order parameter validation types.
#
#    This module gathers together a number of validation types used
#    for validating orders.  The notion is that instead of each
#    order module defining a slew of validation types, we'll 
#    accumulate them here.
#
#    Note that some types, such as "civgroup validate", will continue
#    to be defined by the respective modules.  But peculiar types,
#    like "civg+all" (all civilian groups plus "ALL") will be defined
#    here.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# ptype

snit::type ptype {
    pragma -hasinstances no

    # n+all
    #
    # Neighborhood names + ALL

    typemethod {n+all names} {} {
        linsert [nbhood names] 0 ALL
    }

    typemethod {n+all validate} {value} {
        EnumVal "neighborhood" [$type n+all names] $value
    }


    # civg+all
    #
    # Civilian group names + ALL

    typemethod {civg+all names} {} {
        linsert [civgroup names] 0 ALL
    }

    typemethod {civg+all validate} {value} {
        EnumVal "civilian group" [$type civg+all names] $value
    }


    # frcg+all
    #
    # Force group names + ALL

    typemethod {frcg+all names} {} {
        linsert [frcgroup names] 0 ALL
    }

    typemethod {frcg+all validate} {value} {
        EnumVal "force group" [$type frcg+all names] $value
    }


    # orgg+all
    #
    # Organization group names + ALL

    typemethod {orgg+all names} {} {
        linsert [orggroup names] 0 ALL
    }

    typemethod {orgg+all validate} {value} {
        EnumVal "organization group" [$type orgg+all names] $value
    }

    #-------------------------------------------------------------------
    # Helper Routines

    # EnumVal ptype enum value
    #
    # ptype    Parameter type
    # enum     List of valid values
    # value    Value to validate
    #
    # Validates the value, returning it, or throws a good error message.

    proc EnumVal {ptype enum value} {
        if {$value ni $enum} {
            set enum [join $enum ", "]
            return -code error -errorcode INVALID \
                "Invalid $ptype \"$value\", should be one of: $enum"
        }

        return $value
    }
}

