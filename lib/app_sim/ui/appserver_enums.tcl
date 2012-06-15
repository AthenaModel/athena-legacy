#-----------------------------------------------------------------------
# TITLE:
#    appserver_enums.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n), appserver(sim) module: Enumerations
#
#    my://app/enum/...
#
# CONTENT TYPES:
#    Enum URLs have two content types:
#
#    tcl/enumlist     - A simple list of enumerated values.
#    tcl/enumdict     - A dictionary of symbols and labels (e.g.,
#                       short and long names)
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# appserver module

appserver module ENUMS {
    #-------------------------------------------------------------------
    # Public methods

    # init
    #
    # Initializes the appserver module.

    typemethod init {} {
        # FIRST, register the resource types
        appserver register /enum/concerns {enum/concerns}                    \
            tcl/enumlist [asproc enum:enumlist econcern]                     \
            tcl/enumdict [asproc enum:enumdict econcern]                     \
            text/html    [asproc type:html "Enumeration: Concerns" econcern] \
            "Enumeration: Concerns"

        appserver register /enum/topitems {enum/topitems}                    \
            tcl/enumlist [asproc enum:enumlist etopitems]                    \
            tcl/enumdict [asproc enum:enumdict etopitems]                    \
            text/html    [asproc type:html "Enumeration: etopitems" etopitems] \
            "Enumeration: Top Item Limit"
    }
}



