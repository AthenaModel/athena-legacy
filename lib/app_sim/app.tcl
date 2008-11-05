#-----------------------------------------------------------------------
# TITLE:
#    app.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n) Application Ensemble
#
#    This module defines app, the application ensemble.  app encapsulates 
#    all of the functionality of minerva_sim(1), including the application's 
#    start-up behavior.  To invoke the  application,
#
#        package require app_sim
#        app init $argv
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Required Packages

# All needed packages are required in app_sim.tcl.
 
#-----------------------------------------------------------------------
# app ensemble

snit::type app {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Components

    typecomponent cli                ;# The cli(n) pane
    typecomponent msgline            ;# The messageline(n)
    typecomponent viewer             ;# The mapviewer(n)
    typecomponent rdb                ;# The scenario RDB

    #-------------------------------------------------------------------
    # Type Variables

    # Info Array: most scalars are stored here

    typevariable info -array {

    }

    #-------------------------------------------------------------------
    # Application Initializer

    # init argv
    #
    # argv  Command line arguments (if any)
    #
    # Initializes the application.
    typemethod init {argv} {
        # FIRST, "Process" the command line.
        if {[llength $argv] > 1} {
            app usage
            exit 1
        }

        # NEXT, create the GUI

        # Set the window title
        wm title . "Minerva [version]: Simulation"

        # Prepare to cleanup on exit
        wm protocol . WM_DELETE_WINDOW [mytypemethod exit]

        # Construct major window components
        ConstructMenuBar
        ConstructMainWindow

        # NEXT, allow the developer to pop up the debugger window.
        bind . <F12> [list debugger new]

        # NEXT, Allow the widget sizes to propagate to the toplevel, so
        # the window gets its default size; then turn off propagation.
        # From here on out, the user is in control of the size of the
        # window.
        update idletasks
        grid propagate . off

        # NEXT, load the map, if any
        if {[llength $argv] == 1} {
            set mapfile [lindex $argv 0]
            if {[catch {
                set map [image create photo -file $mapfile]
            } result]} {
                puts "Could not open map file: $mapfile\n$result"
                app exit
            }

            $viewer configure -map $map
            $viewer clear
        }
    }

    # ConstructMenuBar
    #
    # Creates the main menu bar

    proc ConstructMenuBar {} {
        # Menu Bar
        set menu [menu .menubar -relief flat]
        . configure -menu $menu
        
        # File Menu
        set filemenu [menu $menu.file]
        $menu add cascade -label "File" -underline 0 -menu $filemenu
        
        $filemenu add command \
            -label "Exit" \
            -underline 1 \
            -accelerator "Ctrl+Q" \
            -command exit
        bind . <Control-q> [mytypemethod exit]

        # Edit menu
        set editmenu [menu $menu.edit]
        .menubar add cascade -label "Edit" -underline 0 -menu $editmenu
        
        $editmenu add command \
            -label "Cut" \
            -underline 2 \
            -accelerator "Ctrl+X" \
            -command {event generate [focus] <<Cut>>}

        $editmenu add command \
            -label "Copy" \
            -underline 0 \
            -accelerator "Ctrl+C" \
            -command {event generate [focus] <<Copy>>}
        
        $editmenu add command \
            -label "Paste" \
            -underline 0 \
            -accelerator "Ctrl+V" \
            -command {event generate [focus] <<Paste>>}
        
        $editmenu add separator
        
        $editmenu add command \
            -label "Select All" \
            -underline 7 \
            -accelerator "Ctrl+Shift+A" \
            -command {event generate [focus] <<SelectAll>>}
    }

    # ConstructMainWindow
    #
    # Adds the components to the main window

    proc ConstructMainWindow {} {
        # FIRST, prepare the grid.  The scrolling log/shell paner
        # should stretch vertically on resize; the others shouldn't.
        # And everything should stretch horizontally.

        grid rowconfigure . 0 -weight 0
        grid rowconfigure . 1 -weight 1
        grid rowconfigure . 2 -weight 0
        grid rowconfigure . 3 -weight 0

        grid columnconfigure . 0 -weight 1

        # NEXT, put in the row widgets

        # ROW 0, add a separator between the menu bar and the rest of the
        # window.
        frame .sep0 -height 2 -relief sunken -borderwidth 2

        # ROW 1, create the paner for the map/cli
        paner .paner -orient vertical -showhandle 1

        # ROW 2, add a separator
        frame .sep2 -height 2 -relief sunken -borderwidth 2

        # ROW 3, Create the Message line.
        set msgline [messageline .msgline]

        # NEXT, add the mapviewer to the paner
        mapviewer .paner.viewer                             \
            -width        600                               \
            -height       600

        set viewer .paner.viewer
        
        .paner add .paner.viewer \
            -sticky  nsew        \
            -minsize 60          \
            -stretch always

        # NEXT, add the CLI to the paner
        set cli [cli .paner.cli    \
                     -height 8     \
                     -relief flat]

        .paner add .paner.cli \
            -sticky  nsew     \
            -minsize 60       \
            -stretch never

        # NEXT, manage all of the components.
        grid .sep0     -sticky ew
        grid .paner    -sticky nsew
        grid .sep2     -sticky ew
        grid .msgline  -sticky ew

        # NEXT, add some bindings
        bind $viewer <<Icon-1>>        {IconPoint %W %d}
        bind $viewer <<IconMoved>>     {IconMoved %W %d}
        bind $viewer <<PolyComplete>>  {PolyComplete %W %d}
        
        $viewer bind nbhood <Button-1> {NbhoodPoint %W %x %y}
    }


    #-------------------------------------------------------------------
    # Utility Type Methods

    # usage
    #
    # Displays the application's command-line syntax
    
    typemethod usage {} {
        puts "Usage: minerva sim"
        puts ""
        puts "See minerva_sim(1) for more information."
    }

    # puts text
    #
    # text     A text string
    #
    # Writes the text to the message line

    typemethod puts {text} {
        $msgline puts $text
    }

    # exit
    #
    # Exits the program

    typemethod exit {} {
        exit
    }
}







