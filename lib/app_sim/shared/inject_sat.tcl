#-----------------------------------------------------------------------
# TITLE:
#    inject_sat.tcl
#
# AUTHOR:
#    Dave Hanks
#
# DESCRIPTION:
#    athena_sim(1): SAT(glist, clist, mag) inject
#
#    This module implements the SAT inject, which affects the satisfaction
#    level of each group in glist with each concern in clist.
#
# PARAMETER MAPPING:
#
#    g      <= g
#    c      <= c
#    mag    <= mag
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# INJECT: SAT

inject type define SAT {g c mag} {
    #-------------------------------------------------------------------
    # Public Methods

    #-------------------------------------------------------------------
    # inject(i) subcommands
    #
    # See the inject(i) man page for the signature and general
    # description of each subcommand.

    typemethod narrative {pdict} {
        dict with pdict {
            set points [format "%.1f" $mag]
            set symbol [qmag name $mag]
            return "Change satisfaction of $g with $c by $points points ($symbol)."
        }
    }

    typemethod check {pdict} {
        set errors [list]

        #TBD
        return [join $errors "  "]
    }
}

# INJECT:SAT:CREATE
#
# Creates a new SAT inject.

order define INJECT:SAT:CREATE {
    title "Create Inject: Satisfaction"

    options -sendstates {PREP PAUSED}

    form {
        rcc "CURSE ID:" -for curse_id
        text curse_id -context yes

        rcc "Description:" -for longname
        disp longname -width 60

        rcc "Civ Group Role:" -for rtype
        selector rtype -defvalue "NEW" {
            case NEW "Define new role" {
                rcc "Role:" -for g
                text g
            }

            case EXISTING "Use existing role" {
                rcc "Role:" -for g
                enum g -listcmd {::inject rolenames SAT g}
            }
        }

        rcc "With:" -for c
        concern c 

        rcc "Magnitude:" -for mag
        mag mag
        label "points of change"
    }
} {
    # FIRST, prepare and validate the parameters
    prepare curse_id -toupper   -required -type curse
    prepare g        -toupper   -required -type roleid
    prepare c        -toupper   -required -type econcern
    prepare mag -num -toupper   -required -type qmag

    returnOnError -final

    # NEXT, put inject_type in the parmdict
    set parms(inject_type) SAT

    # NEXT, create the inject
    setundo [inject mutate create [array get parms]]
}

# INJECT:SAT:UPDATE
#
# Updates existing SAT inject.

order define INJECT:SAT:UPDATE {
    title "Update Inject: Satisfaction"
    options -sendstates {PREP PAUSED} 

    form {
        rcc "Inject:" -for id
        key id -context yes -table gui_injects_SAT \
            -keys {curse_id inject_num} \
            -loadcmd {orderdialog keyload id {g c mag}}

        rcc "Description:" -for longname
        disp longname -width 60

        rcc "Civ Group Role:" -for rtype
        selector rtype -defvalue "EXISTING" {
            case NEW "Rename role" {
                rcc "Role:" -for g
                text g
            }

            case EXISTING "Use existing role" {
                rcc "Role:" -for g
                enum g -listcmd {::inject rolenames SAT g}
            }
        }

        rcc "With:" -for c
        concern c

        rcc "Magnitude:" -for mag
        mag mag
        label "points of change"
    }
} {
    # FIRST, prepare the parameters
    prepare id         -required           -type  inject
    prepare g          -required -toupper  -type  roleid
    prepare c                    -toupper  -type  econcern
    prepare mag   -num           -toupper  -type  qmag

    returnOnError -final

    # NEXT, modify the inject
    setundo [inject mutate update [array get parms]]
}


