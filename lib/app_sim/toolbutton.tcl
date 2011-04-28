#-----------------------------------------------------------------------
# TITLE:
#    toolbutton.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Convenience procs for defining standard tool buttons
#
#-----------------------------------------------------------------------

# mktoolbutton w icon tooltip ?options...?
#
# w        The widget name
# icon     The icon name
# tooltip  The tooltip text
# options  ttk::button options
#
# Creates a Toolbutton showing the specified icon.  Presumes
# that ${icon}d is the disabled icon.

proc mktoolbutton {w icon tooltip args} {
    ttk::button $w \
        -style  Toolbutton                     \
        -image  [list $icon disabled ${icon}d] \
        {*}$args

    DynamicHelp::add $w -text $tooltip

    return $w
}

# mkaddbutton w tooltip ?options...?
#
# w        The widget name
# tooltip  The tooltip text
# options  ttk::button options
#
# Creates an "add" Toolbutton showing a "plus sign" icon.

proc mkaddbutton {w tooltip args} {
    mktoolbutton $w ::marsgui::icon::plus22 $tooltip {*}$args
}

# mkdeletebutton w tooltip ?options...?
#
# w        The widget name
# tooltip  The tooltip text
# options  ttk::button options
#
# Creates a "delete" Toolbutton showing a red "X" icon.

proc mkdeletebutton {w tooltip args} {
    mktoolbutton $w ::projectgui::icon::trash22 $tooltip {*}$args
}

# mkeditbutton w tooltip ?options...?
#
# w        The widget name
# tooltip  The tooltip text
# options  ttk::button options
#
# Creates an "edit" Toolbutton showing a "pencil" icon.

proc mkeditbutton {w tooltip args} {
    mktoolbutton $w ::marsgui::icon::pencil22 $tooltip {*}$args
}

