#-----------------------------------------------------------------------
# TITLE:
#    payload_sat.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): SAT(c,mag) payload
#
#    This module implements the SAT payload, which affects the satisfaction
#    of covered civilian groups with a specific force group.
#
# PARAMETER MAPPING:
#
#    c    <= c
#    mag  <= mag
#
#-----------------------------------------------------------------------

#-------------------------------------------------------------------
# PAYLOAD: SAT

payload type define SAT {c mag} {
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
            return "Change satisfaction with $c by $points points ($symbol)."
        }
    }
}

# PAYLOAD:SAT:CREATE
#
# Creates a new SAT payload.

order define PAYLOAD:SAT:CREATE {
    title "Create Payload: Satisfaction"

    options \
        -sendstates PREP

    parm iom_id    text  "Message ID"      -context yes
    parm c         enum  "Concern"         -enumtype econcern
    parm mag       text  "Magnitude"
} {
    # FIRST, prepare and validate the parameters
    prepare iom_id   -toupper   -required -type iom
    prepare c        -toupper   -required -type econcern
    prepare mag      -toupper   -required -type qmag

    returnOnError -final

    # NEXT, put payload_type in the parmdict
    set parms(payload_type) SAT

    # NEXT, create the payload
    setundo [payload mutate create [array get parms]]
}

# PAYLOAD:SAT:UPDATE
#
# Updates existing SAT payload.

order define PAYLOAD:SAT:UPDATE {
    title "Update Payload: Satisfaction"
    options \
        -sendstates PREP \
        -refreshcmd {::orderdialog refreshForKey id *}

    parm id        key  "Payload"       -context yes               \
                                        -table   gui_payloads_SAT \
                                        -keys    payload_id
    parm iom_id    disp  "Message ID"
    parm c         enum  "Concern"      -enumtype econcern
    parm mag       text  "Magnitude"
} {
    # FIRST, prepare the parameters
    prepare id         -required -type payload
    prepare c          -toupper  -type econcern
    prepare mag        -toupper  -type qmag

    returnOnError -final

    # NEXT, modify the payload
    setundo [payload mutate update [array get parms]]
}


