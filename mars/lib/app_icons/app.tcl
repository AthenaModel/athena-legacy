#-----------------------------------------------------------------------
# TITLE:
#    app.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    mars_icons(1) Application
#
#    This module defines app, the application ensemble.
#
#        package require app_icons
#        app init $argv
#
#    This program is a tool for displaying the icons in a namespace.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# app ensemble

snit::type app {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Components
    
    # TBD

    #-------------------------------------------------------------------
    # Application Initializer

    # init argv
    #
    # argv         Command line arguments
    #
    # This the main program.

    typemethod init {argv} {
        # FIRST get the argument, if any.
        if {[llength $argv] == 0} {
            set ns ::marsgui::icon
        } elseif {[llength $argv] == 1} {
            set ns [lindex $argv 0]
        } else {
            puts "Usage: mars icons ?namespace?"
            exit 1
        }
        
        # NEXT, get a list of the icons
        set icons [list]
        
        foreach name [lsort [info commands ${ns}::*]] {
            # Skip non images
            if {[catch {image type $name}]} {
                continue
            }
            
            # Skip images that are too big
            if {[image width $name] > 50 ||
                [image height $name] > 50
            } {
                puts "Skipped $name: too big, [image width $name]x[image height $name]"
                continue     
            }
            
            lappend icons $name
        }
        
        # NEXT, did we find any?
        set len [llength $icons]
        
        if {$len == 0} {
            puts "No icons found in $ns."
            exit 0
        }
        
        # NEXT, set the window title
        wm title . "Mars Icon Browser: ${ns}::*"

        # NEXT, create a title label
        ttk::label .title  \
            -anchor center \
            -text "Icons in ${ns}::*"

        grid .title -row 0 -column 0 -columnspan 6 -pady 8 -padx 5 -sticky ew
        
        # NEXT, layout a grid of icons, six wide
        set r 1
        
        for {set i 0} {$i < $len} {incr i} {
            set r1 [expr {$r + 1}]
            set c [expr {$i % 6}]
            set icon [lindex $icons $i]
            set name [namespace tail $icon]
            
            if {$c == 0} {
                set padx {5 2}
            } elseif {$c == 5} {
                set padx {3 5}
            } else {
                set padx {3 2}
            }

            ttk::button .icon$i -image $icon -style Toolbutton
            ttk::label  .lab$i  -text  $name
            
            grid .icon$i -row $r  -column $c -padx $padx
            grid .lab$i  -row $r1 -column $c -padx $padx -pady {0 5}
            
            if {$c == 5} {
                incr r 2
            }
        }
    }
}



