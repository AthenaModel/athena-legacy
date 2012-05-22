#-----------------------------------------------------------------------
# TITLE:
#    payload_coop.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): COOP(g,mag) payload
#
#    This module implements the COOP payload, which affects the cooperation
#    of covered civilian groups with a specific force group.
#
# PARAMETER MAPPING:
#
#    g    <= g
#    mag  <= mag
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# PAYLOAD: COOP

payload type define COOP {g mag} {
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
            return "Change cooperation with $g by $points points ($symbol)."
        }
    }

    typemethod check {pdict} {
        set errors [list]

        dict with pdict {
            if {$g ni [frcgroup names]} {
                lappend errors "Force group $g no longer exists."
            }
        }

        return [join $errors "  "]
    }
}

# PAYLOAD:COOP:CREATE
#
# Creates a new COOP payload.

order define PAYLOAD:COOP:CREATE {
    title "Create Payload: Cooperation"

    options \
        -sendstates PREP

    parm iom_id    text  "Message ID"      -context yes
    parm g         enum  "Force Group"     -enumtype frcgroup
    parm mag       mag   "Magnitude"
} {
    # FIRST, prepare and validate the parameters
    prepare iom_id   -toupper   -required -type iom
    prepare g        -toupper   -required -type frcgroup
    prepare mag      -toupper   -required -type qmag

    returnOnError -final

    # NEXT, put payload_type in the parmdict
    set parms(payload_type) COOP

    # NEXT, create the payload
    setundo [payload mutate create [array get parms]]
}

# PAYLOAD:COOP:UPDATE
#
# Updates existing COOP payload.

order define PAYLOAD:COOP:UPDATE {
    title "Update Payload: Cooperation"
    options \
        -sendstates PREP \
        -refreshcmd {::orderdialog refreshForKey id *}

    parm id        key   "Payload"      -context  yes                  \
                                        -table    gui_payloads_COOP    \
                                        -keys     {iom_id payload_num}
    parm g         enum  "Force Group"  -enumtype frcgroup
    parm mag       mag   "Magnitude"
} {
    # FIRST, prepare the parameters
    prepare id         -required -type payload
    prepare g          -toupper  -type frcgroup
    prepare mag        -toupper  -type qmag

    returnOnError -final

    # NEXT, modify the payload
    setundo [payload mutate update [array get parms]]
}


