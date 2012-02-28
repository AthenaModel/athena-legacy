#-----------------------------------------------------------------------
# TITLE:
#    guitypes.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Module for GUI-related validation types.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::marsgui:: {
    namespace export hexcolor
}

#-----------------------------------------------------------------------
# Public Commands

snit::type ::marsgui::hexcolor {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Public Type Methods

    # validate color
    #
    # color    A Tk color spec
    #
    # Validates the color using [winfo rgb], and converts the result
    # to a 24-bit hex color string.

    typemethod validate {value} {
        if {[catch {winfo rgb . $value} result]} {
            return -code error -errorcode INVALID \
                "Invalid hex color specifier, should be \"#RRGGBB\" or a valid color name"
        }

        # Get the channel numbers, which are 16-bit
        lassign $result r g b

        # Convert the channel numbers to 8-bit.
        set r [expr {$r >> 8}]
        set g [expr {$g >> 8}]
        set b [expr {$b >> 8}]

        # Return as a 24-bit hex color spec
        return [format "#%02X%02X%02X" $r $g $b]
    }
}

