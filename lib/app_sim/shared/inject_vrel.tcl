#-----------------------------------------------------------------------
# TITLE:
#    inject_vrel.tcl
#
# AUTHOR:
#    Dave Hanks
#
# DESCRIPTION:
#    athena_sim(1): VREL(g, a, mag) inject
#
#    This module implements the VREL inject, which affects the vertical
#    relationship of each group in the g role with each actor in the a
#    role.
#
# PARAMETER MAPPING:
#
#    g   <= g
#    a   <= a
#    mag <= mag
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# INJECT: VREL

inject type define VREL {g a mag} {
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
            return "Change vertical relationships of groups in role $g with actors in role $a by $points points ($symbol)."
        }
    }

    typemethod check {pdict} {
        set errors [list]

        # TBD
        return [join $errors "  "]
    }
}

# INJECT:VREL:CREATE
#
# Creates a new VREL inject.

order define INJECT:VREL:CREATE {
    title "Create Inject: Vertical Relationship"

    options -sendstates {PREP PAUSED}

    form {
        rcc "CURSE ID:" -for curse_id
        text curse_id -context yes

        rcc "Description:" -for longname -span 4
        disp longname -width 60

        rcc "Mode:" -for mode -span 4
        enumlong mode -dictcmd {einputmode deflist} -defvalue transient

        rcc "Of Group Role:" -for g 
        selector rtype -defvalue "NEW" {
            case NEW "Define new role" {
                cc "Role:" -for g
                label "@"
                text g
            }

            case EXISTING "Use existing role" {
                cc "Role:" -for g
                enum g -listcmd {::inject rolenames VREL g}
            }
        }

        rcc "With Actor Role:" -for a
        selector rtype -defvalue "NEW" {
            case NEW "Define new role" {
                cc "Role:" -for a
                label "@"
                text a
            }

            case EXISTING "Use existing role" {
                cc "Role:" -for a
                enum a -listcmd {::inject rolenames VREL a}
            }
        }

        rcc "Magnitude:" -for mag -span 4
        mag mag
        label "points of change"
    }
} {
    # FIRST, prepare and validate the parameters
    prepare curse_id -toupper   -required -type curse
    prepare mode     -tolower   -required -type einputmode
    prepare g        -toupper   -required -type roleid
    prepare a        -toupper   -required -type roleid
    prepare mag -num -toupper   -required -type qmag

    returnOnError -final

    # NEXT, put inject_type in the parmdict
    set parms(inject_type) VREL

    # NEXT, create the inject
    setundo [inject mutate create [array get parms]]
}

# INJECT:VREL:UPDATE
#
# Updates existing VREL inject.

order define INJECT:VREL:UPDATE {
    title "Update Inject: Vertical Relationship"
    options -sendstates {PREP PAUSED} 

    form {
        rcc "Inject:" -for id
        key id -context yes -table gui_injects_VREL \
            -keys {curse_id inject_num} \
            -loadcmd {orderdialog keyload id {g a mode mag}}

        rcc "Description:" -for longname -span 4
        disp longname -width 60

        rcc "Mode:" -for mode -span 4
        enumlong mode -dictcmd {einputmode deflist}

        rcc "Of Group Role:" -for g 
        selector rtype -defvalue "EXISTING" {
            case NEW "Rename role" {
                cc "Role:" -for g
                label "@"
                text g
            }

            case EXISTING "Use existing role" {
                cc "Role:" -for g
                enum g -listcmd {::inject rolenames VREL g}
            }
        }

        rcc "With Actor Role:" -for a
        selector rtype -defvalue "EXISTING" {
            case NEW "Rename role" {
                cc "Role:" -for a
                label "@"
                text a
            }

            case EXISTING "Use existing role" {
                cc "Role:" -for a
                enum a -listcmd {::inject rolenames VREL a}
            }
        }

        rcc "Magnitude:" -for mag -span 4
        mag mag
        label "points of change"
    }
} {
    # FIRST, prepare the parameters
    prepare id    -required           -type inject
    prepare mode            -tolower  -type  einputmode
    prepare g               -toupper  -type roleid
    prepare a               -toupper  -type roleid
    prepare mag   -num      -toupper  -type qmag

    returnOnError -final

    # NEXT, modify the inject
    setundo [inject mutate update [array get parms]]
}


