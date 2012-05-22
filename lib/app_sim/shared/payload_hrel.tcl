#-----------------------------------------------------------------------
# TITLE:
#    payload_hrel.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): HREL(g,mag) payload
#
#    This module implements the HREL payload, which affects the horizontal
#    relationship of covered civilian groups with a specific group.
#
# PARAMETER MAPPING:
#
#    g    <= g
#    mag  <= mag
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# PAYLOAD: HREL

payload type define HREL {g mag} {
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
            return "Change horizontal relationships with $g by $points points ($symbol)."
        }
    }

    typemethod check {pdict} {
        set errors [list]

        dict with pdict {
            if {$g ni [group names]} {
                lappend errors "Group $g no longer exists."
            }
        }

        return [join $errors "  "]
    }
}

# PAYLOAD:HREL:CREATE
#
# Creates a new HREL payload.

order define PAYLOAD:HREL:CREATE {
    title "Create Payload: Horizontal Relationship"

    options \
        -sendstates PREP

    parm iom_id    text  "Message ID"      -context yes
    parm g         enum  "Group"           -enumtype group
    parm mag       mag   "Magnitude"
} {
    # FIRST, prepare and validate the parameters
    prepare iom_id   -toupper   -required -type iom
    prepare g        -toupper   -required -type group
    prepare mag      -toupper   -required -type qmag

    returnOnError -final

    # NEXT, put payload_type in the parmdict
    set parms(payload_type) HREL

    # NEXT, create the payload
    setundo [payload mutate create [array get parms]]
}

# PAYLOAD:HREL:UPDATE
#
# Updates existing HREL payload.

order define PAYLOAD:HREL:UPDATE {
    title "Update Payload: Horizontal Relationship"
    options \
        -sendstates PREP \
        -refreshcmd {::orderdialog refreshForKey id *}

    parm id        key   "Payload"      -context  yes                  \
                                        -table    gui_payloads_HREL    \
                                        -keys     {iom_id payload_num}
    parm g         enum  "Group"        -enumtype group
    parm mag       mag   "Magnitude"
} {
    # FIRST, prepare the parameters
    prepare id         -required -type payload
    prepare g          -toupper  -type group
    prepare mag        -toupper  -type qmag

    returnOnError -final

    # NEXT, modify the payload
    setundo [payload mutate update [array get parms]]
}


