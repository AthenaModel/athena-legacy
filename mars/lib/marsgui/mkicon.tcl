#-----------------------------------------------------------------------
# TITLE:
#    mkicon.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Module for creating icon images and files from text input.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::marsgui:: {
    namespace export mkicon mkiconfile
}

#-----------------------------------------------------------------------
# Public Commands


# mkicon cmd charmap colors
#
# cmd       Name of icon command to create.  If "", a name is 
#           generated automatically.
# charmap   A list of strings, one string for each row of the GIF image.
#           Each string contains one character for each pixel in the
#           row.
# colors    A dictionary of characters and hex colors, e.g., #ffffff is
#           white.  The special color "trans" indicates that the pixel
#           should be transparent.  Each character in the charmap needs
#           to be represented in the dictionary.
#
# Creates and returns a Tk photo image.

proc ::marsgui::mkicon {cmd charmap colors} {
    # FIRST, make sure the name is fully qualified.
    if {$cmd ne "" && ![string match "::*" $cmd]} {
        set ns [uplevel 1 {namespace current}]

        if {$ns eq "::"} {
            set cmd "::$cmd"
        } else {
            set cmd "${ns}$cmd"
        }
    }

    # NEXT, get the number of rows and columns
    set rows [llength $charmap]
    set cols [string length [lindex $charmap 1]]
    
    # NEXT, create an image of that size
    if {$cmd ne ""} {
        set icon [image create photo $cmd -width $cols -height $rows]
    } else {
        set icon [image create photo -width $cols -height $rows]
    }

    # NEXT, build up the pixels
    set r -1
    foreach row $charmap {
        incr r

        set c -1
        foreach char [split $row ""] {
            incr c

            set color [dict get $colors $char]
            if {$color eq "trans"} {
                $icon transparency set $c $r 1
            } else {
                $icon put $color -to $c $r
            }
        }
    }

    return $icon
}

# mkiconfile name fmt charmap colors
#
# name      The file name
# fmt       gif|png
# charmap   A list of strings, one string for each row of the GIF image.
#           Each string contains one character for each pixel in the
#           row.
# colors    A dictionary of characters and hex colors, e.g., #ffffff is
#           white.  The special color "trans" indicates that the pixel
#           should be transparent.  Each character in the charmap needs
#           to be represented in the dictionary.
#
# Creates a image file of the specified format.  By default, the file
# will be created in the current working directory.  Returns the
# absolute path to the icon file.

proc ::marsgui::mkiconfile {name fmt charmap colors} {
    # FIRST, make the icon
    set icon [mkicon "" $charmap $colors]

    # NEXT, save the image to disk, and delete the image object.
    $icon write $name -format $fmt
    image delete $icon

    return [file normalize $name]
}
