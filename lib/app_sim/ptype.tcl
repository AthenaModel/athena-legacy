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

    # n
    #
    # Neighborhood names

    typemethod {n names} {} {
        nbhood names
    }

    typemethod {n validate} {value} {
        EnumVal "neighborhood" [$type n names] $value
    }


    # n+all
    #
    # Neighborhood names + ALL

    typemethod {n+all names} {} {
        linsert [nbhood names] 0 ALL
    }

    typemethod {n+all validate} {value} {
        EnumVal "neighborhood" [$type n+all names] $value
    }


    # g+none
    #
    # Group names + NONE

    typemethod {g+none names} {} {
        linsert [group names] 0 NONE
    }

    typemethod {g+none validate} {value} {
        EnumVal "group" [$type g+none names] $value
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

    # satg
    #
    # Satisfaction groups (CIV/ORG)

    typemethod {satg names} {} {
        rdb eval {
            SELECT g FROM groups WHERE gtype IN ('CIV', 'ORG');
        }
    }

    typemethod {satg validate} {value} {
        EnumVal "group" [$type satg names] $value
    }

    # c
    #
    # Concern names, CIV and ORG

    typemethod {c names} {} {
        rdb eval {SELECT c FROM concerns}
    }

    typemethod {c validate} {value} {
        EnumVal "concern" [$type c names] $value
    }

    # civc
    #
    # Concern names, CIV

    typemethod {civc names} {} {
        rdb eval {SELECT c FROM concerns WHERE gtype='CIV'}
    }

    typemethod {civc validate} {value} {
        EnumVal "civilian concern" [$type civc names] $value
    }

    # orgc
    #
    # Concern names, ORG

    typemethod {orgc names} {} {
        rdb eval {SELECT c FROM concerns WHERE gtype='ORG'}
    }

    typemethod {orgc validate} {value} {
        EnumVal "organization concern" [$type orgc names] $value
    }

    # c+mood
    #
    # Concern names (CIV and ORG), plus "MOOD"

    typemethod {c+mood names} {} {
        linsert [ptype c names] 0 MOOD
    }

    typemethod {c+mood validate} {value} {
        EnumVal "concern" [$type c+mood names] $value
    }

    # civc+mood
    #
    # Concern names (CIV), plus "MOOD"

    typemethod {civc+mood names} {} {
        linsert [ptype civc names] 0 MOOD
    }

    typemethod {civc+mood validate} {value} {
        EnumVal "civilian concern" [$type civc+mood names] $value
    }


    # orgc+mood
    #
    # Concern names (CIV), plus "MOOD"

    typemethod {orgc+mood names} {} {
        linsert [ptype orgc names] 0 MOOD
    }

    typemethod {orgc+mood validate} {value} {
        EnumVal "organization concern" [$type orgc+mood names] $value
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

