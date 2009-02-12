#-----------------------------------------------------------------------
# TITLE:
#    orderdef.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Prototype order definitions.  Ultimately, these scripts will
#    be integrated into the "order define" calls in the various modules.
#    Grouping them here allows me to experiment with the syntax
#    without having to visit a bunch of files.
#
# DIALOG DEFINITION COMMANDS:
#
#   Ultimately, this documentation will go in the order(sim) man page.
#
#   title titleString
#     Sets the order title.
#
#   table name
#     Associates the order with an RDB table or view.
#
#   parm name fieldtype labeltext ?options...?
#     Defines a parameter.  Order of parameters is significant.
#
#     name       The parameter name
#     fieldtype  The kind of field used to enter/edit the value
#                   color    A color picker
#                   enum     An enumeration; requires a -type or
#                            a -configure script.
#                   key      A table key field; requires "table"
#                   multi    A multiple IDs field; requires "table"
#                   text     A plain old text entry
#     labeltext  The label used in the dialg
#
#     -tags taglist      <EntitySelect> events with a tag in this list
#                        will populate the field (if possible).  For 
#                        example, if -tags is "group" and a group is
#                        selected and the field is an enum, the GUI
#                        should ignore the event if the selected value
#                        is invalid for the enum.
#
#     -type enumtype     When used with enum, gives the enum(n) type
#                        which provides the valid values.
#
#     -defval value      Default parameter value; used to populate
#                        field if field is blank on refresh.
#
#     -refresh           Indicates that changes to this field
#                        should trigger a refresh of downstream fields.
#                        For text fields, refresh occurs with each change
#                        to the value string, as the user is typing.
#
#     -refreshcmd cmd    A command called to refresh this field when
#                        an upstream field triggers a refresh.  The
#                        command receives two arguments, the field
#                        object and a dictionary of the values of the 
#                        previous fields.  The command can:
#
#                        * Enable/Disable the field
#                        * Set or clear the value in the field
#                        * Set the set of valid values for enums.
#                        * etc.
#
# FIELD TYPES
#
#    * Every field type has a value that get gotten or set.
#    * Every field type has a state that can be "normal" or "disabled".
#    * Enum field types have a list of valid values that can be gotten
#      and set.
#
# QUESTIONS:
#
#    Q: Do we want one "parm" command, with options that depend on the
#       field type?  Or do we have one command per field type, so that
#       each can have its peculiar options?
#
#    Q: Should -refreshcmd scripts be like Tk scripts, with replacement
#       tokens?  Probably depends on what kind of API is available for
#       updating the field.
#
#    Q: Do we want a "qual" field type?
#
#-----------------------------------------------------------------------

order defmeta GROUP:CIVILIAN:CREATE {
    title "Create Civilian Group"

    #    name      field  label
    parm g         text   "ID"
    parm longname  text   "Long Name"
    parm color     color  "Color"
}

order defmeta GROUP:CIVILIAN:DELETE {
    title "Delete Civilian Group"
    table civgroups_view

    parm g  key  "Group"  -tags group
}

order defmeta GROUP:CIVILIAN:UPDATE {
    title "Update Civilian Group"
    table civgroups_view

    parm g         key    "ID"         -tags group
    parm longname  text   "Long Name"
    parm color     color  "Color"
}

order defmeta GROUP:CIVILIAN:UPDATE:MULTI {
    title "Update Multiple Civilian Groups"
    table gui_civgroups

    parm ids    multi  "Groups"
    parm color  color  "Color"
}

order defmeta COOPERATION:UPDATE {
    title "Update Cooperation"
    table coop_nfg

    parm n      key   "Neighborhood"  -tags nbhood
    parm f      key   "Of Group"      -tags group
    parm g      key   "With Group"    -tags group
    parm coop0  text  "Cooperation"
}

order defmeta COOPERATION:UPDATE:MULTI {
    title "Update Multiple Cooperations"
    table gui_coop_nfg
 
    parm ids    multi  "IDs"
    parm coop0  text   "Cooperation"
}

order defmeta GROUP:FORCE:CREATE {
    title "Create Force Group"

    parm g          text  "ID"
    parm longname   text  "Long Name"
    parm color      color "Color"
    parm forcetype  enum  "Force Type"        -type eforcetype
    parm local      enum  "Local Group?"      -type eyesno
    parm coalition  enum  "Coalition Member?" -type eyesno
}

order defmeta GROUP:FORCE:DELETE {
    title "Delete Force Group"
    table gui_frcgroups

    parm g  key "Group" -tags group
}

order defmeta GROUP:FORCE:UPDATE {
    title "Update Force Group"
    table gui_frcgroups

    parm g          key   "ID"                 -tags group
    parm longname   text  "Long Name"
    parm color      color "Color"
    parm forcetype  enum  "Force Type"         -type eforcetype
    parm local      enum  "Local Group?"       -type eyesno
    parm coalition  enum  "Coalition Member?"  -type eyesno
}

order defmeta GROUP:FORCE:UPDATE:MULTI {
    title "Update Multiple Force Groups"
    table gui_frcgroups

    parm ids        multi "Groups"
    parm color      color "Color"
    parm forcetype  enum  "Force Type"         -type eforcetype
    parm local      enum  "Local Group?"       -type eyesno
    parm coalition  enum  "Coalition Member?"  -type eyesno
}

order defmeta MAP:IMPORT {
    title "Import Map"

    # NOTE: Dialog is not usually used.
    parm filename   text "Map File"
}

order defmeta GROUP:NBHOOD:CREATE {
    title "Create Nbhood Group"

    parm n              text "Neighborhood"
    parm g              text "Civ Group"
    parm local_name     text "Local Name"
    parm demeanor       enum "Demeanor"       -type edemeanor
    parm rollup_weight  text "RollupWeight"   -defval 1.0
    parm effects_factor text "EffectsFactor"  -defval 1.0
}

order defmeta GROUP:NBHOOD:DELETE {
    title "Delete Nbhood Group"
    table gui_nbgroups

    parm n  key  "Neighborhood"  -tags nbhood
    parm g  key  "Civ Group"     -tags group
}

order defmeta GROUP:NBHOOD:UPDATE {
    title "Update Nbhood Group"
    table gui_nbgroups

    parm n              key   "Neighborhood"  -tags nbhood
    parm g              key   "Civ Group"     -tags group
    parm local_name     text  "Local Name"
    parm demeanor       enum  "Demeanor"      -type edemeanor
    parm rollup_weight  text  "RollupWeight"
    parm effects_factor text  "EffectsFactor"
}

order defmeta GROUP:NBHOOD:UPDATE:MULTI {
    title "Update Multiple Nbhood Groups"
    table gui_nbgroups

    parm ids            multi "Groups"
    parm local_name     text  "Local Name"
    parm demeanor       enum  "Demeanor"       -type edemeanor
    parm rollup_weight  text  "RollupWeight"
    parm effects_factor text  "EffectsFactor"
}

order defmeta NBHOOD:CREATE {
    title "Create Neighborhood"

    parm n            text "Neighborhood"
    parm longname     text "Long Name"
    parm urbanization enum "Urbanization"     -type eurbanization
    parm refpoint     text "Reference Point"  -tags point
    parm polygon      text "Polygon"          -tags polygon
}

order defmeta NBHOOD:DELETE {
    title "Delete Neighborhood"
    table gui_nbhoods   ;# Why gui_nbhoods?

    parm n  key  "Neighborhood"   -tags nbhood
}

order defmeta NBHOOD:LOWER {
    title "Lower Neighborhood"
    table gui_nbhoods

    parm n key "Neighborhood"     -tags nbhood
}

order defmeta NBHOOD:RAISE {
    title "Raise Neighborhood"
    table gui_nbhoods

    parm n key "Neighborhood"     -tags nbhood
}

order defmeta NBHOOD:UPDATE {
    title "Update Neighborhood"
    table gui_nbhoods

    parm n            key   "Neighborhood"     -tags nbhood
    parm longname     text  "Long Name"
    parm urbanization enum  "Urbanization"     -type eurbanization
    parm refpoint     text  "Reference Point"  -tags point
    parm polygon      text  "Polygon"          -tags polygon
}

order defmeta NBHOOD:UPDATE:MULTI {
    title "Update Multiple Neighborhoods"
    table gui_nbhoods

    parm ids          multi  "Neighborhoods"
    parm urbanization enum   "Urbanization"    -type eurbanization
}

order defmeta NBHOOD:RELATIONSHIP:UPDATE {
    title "Update Neighborhood Relationship"
    table nbrel_mn

    parm m             key  "Of Neighborhood"      -tags nbhood
    parm n             key  "With Neighborhood"    -tags nbhood
    parm proximity     enum "Proximity"            \
        -refreshcmd {::nbrel RefreshProximitySingle}
    parm effects_delay text "Effects Delay (Days)" 
}

order defmeta NBHOOD:RELATIONSHIP:UPDATE:MULTI {
    title "Update Multiple Neighborhood Relationships"
    table gui_nbrel_mn

    parm ids           multi  "IDs"
    parm proximity     enum   "Proximity" \
        -refreshcmd {::nbrel RefreshProximityMulti}
    parm effects_delay text   "Effects Delay (Days)"
}

order defmeta GROUP:ORGANIZATION:CREATE {
    title "Create Organization Group"

    parm g              text  "ID"
    parm longname       text  "Long Name"
    parm color          color "Color"
    parm orgtype        enum  "Org. Type"     -type eorgtype
    parm medical        enum  "Medical?"      -type eyesno
    parm engineer       enum  "Engineer?"     -type eyesno
    parm support        enum  "Support?"      -type eyesno
    parm rollup_weight  text  "RollupWeight"  -defval 1.0
    parm effects_factor text  "EffectsFactor" -defval 1.0
}

order defmeta GROUP:ORGANIZATION:DELETE {
    title "Delete Organization Group"
    table gui_orggroups

    parm g  key "Group"
}

order defmeta GROUP:ORGANIZATION:UPDATE {
    title "Update Organization Group"
    table gui_orggroups

    parm g              key   "ID"
    parm longname       text  "Long Name"
    parm color          color "Color"
    parm orgtype        enum  "Org. Type"     -type eorgtype
    parm medical        enum  "Medical?"      -type eyesno
    parm engineer       enum  "Engineer?"     -type eyesno
    parm support        enum  "Support?"      -type eyesno
    parm rollup_weight  text  "RollupWeight"  
    parm effects_factor text  "EffectsFactor" 
}

order defmeta GROUP:ORGANIZATION:UPDATE:MULTI {
    title "Update Multiple Organization Groups"
    table gui_orggroups


    parm ids            multi "Groups"
    parm color          color "Color"
    parm orgtype        enum  "Org. Type"     -type eorgtype
    parm medical        enum  "Medical?"      -type eyesno
    parm engineer       enum  "Engineer?"     -type eyesno
    parm support        enum  "Support?"      -type eyesno
    parm rollup_weight  text  "RollupWeight"  
    parm effects_factor text  "EffectsFactor" 
}

order defmeta RELATIONSHIP:UPDATE {
    title "Update Relationship"
    table rel_nfg

    parm n    key   "Neighborhood"   -tags nbhood
    parm f    key   "Of Group"       -tags group
    parm g    key   "With Group"     -tags group
    parm rel  text  "Relationship"   ;# TBD: Might want -refreshcmd
}

order defmeta RELATIONSHIP:UPDATE:MULTI {
    title "Update Multiple Relationships"
    table gui_rel_nfg

    parm ids  multi  "IDs"
    parm rel  text   "Relationship"  ;# TBD: Might want -refreshcmd
}

order defmeta SATISFACTION:UPDATE {
    title "Update Satisfaction Curve"
    table sat_ngc

    parm n         key   "Neighborhood"  -tags nbhood
    parm g         key   "Group"         -tags group
    parm c         key   "Concern"       -tags concern
    parm sat0      text  "Sat at T0"
    parm trend0    text  "Trend"
    parm saliency  text  "Saliency"
}

order defmeta SATISFACTION:UPDATE:MULTI {
    title "Update Multiple Satisfaction Curves"
    table gui_sat_ngc

    parm ids       multi  "Curves"
    parm sat0      text   "Sat at T0"
    parm trend0    text   "Trend"
    parm saliency  text   "Saliency"
}
