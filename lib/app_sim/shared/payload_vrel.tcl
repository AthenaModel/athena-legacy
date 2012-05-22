#-----------------------------------------------------------------------
# TITLE:
#    payload_vrel.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): VREL(g,mag) payload
#
#    This module implements the VREL payload, which affects the vertical
#    relationship of covered civilian groups with a specific actor.
#
# PARAMETER MAPPING:
#
#    a    <= a
#    mag  <= mag
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# PAYLOAD: VREL

payload type define VREL {a mag} {
    #-------------------------------------------------------------------
    # Public Methods

    #-------------------------------------------------------------------
    # payload(i) subcommands
    #
    # See the payload(i) man page for the signature and general
    # description of each subcommand.

    typemethod narrative {pdict} {
        dict with pdict {
            set points [format "%.1f" $mag]
            set symbol [qmag name $mag]
            return "Change vertical relationships with $a by $points points ($symbol)."
        }
    }

    typemethod check {pdict} {
        set errors [list]

        dict with pdict {
            if {$a ni [actor names]} {
                lappend errors "Actor $a no longer exists."
            }
        }

        return [join $errors "  "]
    }
}

# PAYLOAD:VREL:CREATE
#
# Creates a new VREL payload.

order define PAYLOAD:VREL:CREATE {
    title "Create Payload: Vertical Relationship"

    options \
        -sendstates PREP

    parm iom_id    text  "Message ID"      -context yes
    parm a         enum  "Actor"           -enumtype actor
    parm mag       mag   "Magnitude"
} {
    # FIRST, prepare and validate the parameters
    prepare iom_id   -toupper   -required -type iom
    prepare a        -toupper   -required -type actor
    prepare mag      -toupper   -required -type qmag

    returnOnError -final

    # NEXT, put payload_type in the parmdict
    set parms(payload_type) VREL

    # NEXT, create the payload
    setundo [payload mutate create [array get parms]]
}

# PAYLOAD:VREL:UPDATE
#
# Updates existing VREL payload.

order define PAYLOAD:VREL:UPDATE {
    title "Update Payload: Vertical Relationship"
    options \
        -sendstates PREP \
        -refreshcmd {::orderdialog refreshForKey id *}

    parm id        key   "Payload"      -context  yes                  \
                                        -table    gui_payloads_VREL    \
                                        -keys     {iom_id payload_num}
    parm a         enum  "Actor"        -enumtype actor
    parm mag       mag   "Magnitude"
} {
    # FIRST, prepare the parameters
    prepare id         -required -type payload
    prepare a          -toupper  -type actor
    prepare mag        -toupper  -type qmag

    returnOnError -final

    # NEXT, modify the payload
    setundo [payload mutate update [array get parms]]
}


