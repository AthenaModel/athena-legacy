#-----------------------------------------------------------------------
# TITLE:
#    inject_hrel.tcl
#
# AUTHOR:
#    Dave Hanks
#
# DESCRIPTION:
#    athena_sim(1): HREL(flist, glist, mag) inject
#
#    This module implements the HREL inject, which affects the horizontal
#    relationship of each group in flist with each group in glist.
#
# PARAMETER MAPPING:
#
#    f   <= f
#    g   <= g
#    mag <= mag
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# INJECT: HREL

inject type define HREL {f g mag} {
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
            return "Change horizontal relationships of $f with $g by $points points ($symbol)."
        }
    }

    typemethod check {pdict} {
        set errors [list]

        # TBD
        return [join $errors "  "]
    }
}

# INJECT:HREL:CREATE
#
# Creates a new HREL inject.

order define INJECT:HREL:CREATE {
    title "Create Inject: Horizontal Relationship"

    options -sendstates PREP

    form {
        rcc "CURSE ID:" -for curse_id
        text curse_id -context yes

        rcc "Description:" -for longname
        disp longname -width 60

        rcc "Of Group Role:" -for f
        selector rtype -defvalue "NEW" {
            case NEW "Define new role" {
                rcc "Role:" -for f
                text f
            }

            case EXISTING "Use existing role" {
                rcc "Role:" -for f
                enum f -listcmd {::inject rolenames HREL f}
            }
        }

        rcc "With Group Role:" -for g 
        selector rtype -defvalue "NEW" {
            case NEW "Define new role" {
                rcc "Role:" -for g
                text g
            }

            case EXISTING "Use existing role" {
                rcc "Role:" -for g
                enum g -listcmd {::inject rolenames HREL g}
            }
        }

        rcc "Magnitude:" -for mag
        mag mag
        label "points of change"
    }
} {
    # FIRST, prepare and validate the parameters
    prepare curse_id -toupper   -required -type curse
    prepare f        -toupper   -required -type roleid
    prepare g        -toupper   -required -type roleid
    prepare mag -num -toupper   -required -type qmag

    returnOnError -final

    # NEXT, put inject_type in the parmdict
    set parms(inject_type) HREL

    # NEXT, create the inject
    setundo [inject mutate create [array get parms]]
}

# INJECT:HREL:UPDATE
#
# Updates existing HREL inject.

order define INJECT:HREL:UPDATE {
    title "Update Inject: Horizontal Relationship"
    options -sendstates PREP 

    form {
        rcc "Inject:" -for id
        key id -context yes -table gui_injects_HREL \
            -keys {curse_id inject_num} \
            -loadcmd {orderdialog keyload id {f g mag}}

        rcc "Description:" -for longname
        disp longname -width 60

        rcc "Of Group Role:" -for f
        selector rtype -defvalue "EXISTING" {
            case NEW "Rename role" {
                rcc "Role:" -for f
                text f
            }

            case EXISTING "Use existing role" {
                rcc "Role:" -for f
                enum f -listcmd {::inject rolenames HREL f}
            }
        }

        rcc "With Group Role:" -for g 
        selector rtype -defvalue "EXISTING" {
            case NEW "Rename role" {
                rcc "Role:" -for g
                text g
            }

            case EXISTING "Use existing role" {
                rcc "Role:" -for g
                enum g -listcmd {::inject rolenames HREL g}
            }
        }

        rcc "Magnitude:" -for mag
        mag mag
        label "points of change"
    }
} {
    # FIRST, prepare the parameters
    prepare id         -required -type inject
    prepare f          -toupper  -type roleid
    prepare g          -toupper  -type roleid
    prepare mag   -num -toupper  -type qmag

    returnOnError -final

    # NEXT, modify the inject
    setundo [inject mutate update [array get parms]]
}


