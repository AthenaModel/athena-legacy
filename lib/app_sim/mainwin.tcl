#-----------------------------------------------------------------------
# TITLE:
#    mainwin.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Main application window
#
#    This window is implemented as snit::widget; however, it's set up
#    to exit the program when it's closed, just like ".".  It's expected
#    that "." will be withdrawn at start-up.
#
#    Because this is an application window, it can make use of
#    application-wide resources, such as the RDB.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# mainwin

snit::widget mainwin {
    hulltype toplevel

    #-------------------------------------------------------------------
    # Components

    component cli                ;# The cli(n) pane
    component msgline            ;# The messageline(n)
    component viewer             ;# The mapviewer(n)
 
    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    #-------------------------------------------------------------------
    # Instance variables

    # Info array: scalar values
    #
    #    map     The currently displayed map image.
    #    zoom    The current zoom factor, e.g. 100 = 100% zoom

    variable info -array {
        map   ""
        zoom  100
    }

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, set the default window title
        wm title $win "Untitled - Minerva [version]"

        # NEXT, Exit the app when this window is closed.
        wm protocol $win WM_DELETE_WINDOW [list app exit]

        # NEXT, Allow the developer to pop up the debugger.
        bind $win <Control-F12> [list debugger new]

        # NEXT, Create the major window components
        $self CreateMenuBar
        $self CreateComponents

        # NEXT, Allow the created widget sizes to propagate to
        # $win, so the window gets its default size; then turn off 
        # propagation.  From here on out, the user is in control of the 
        # size of the window.

        update idletasks
        grid propagate . off

        # NEXT, Prepare to receive notifier events.
        notifier bind ::app <AppOpened>      $self [mymethod AppOpened]
        notifier bind ::app <AppSaved>       $self [mymethod AppSaved]
        notifier bind ::app <AppImportedMap> $self [mymethod AppImportedMap]

        # NEXT, Prepare to receive window events
        if 0 {
            bind $viewer <<Icon-1>>        {IconPoint %W %d}
            bind $viewer <<IconMoved>>     {IconMoved %W %d}
            bind $viewer <<PolyComplete>>  {PolyComplete %W %d}
            
            $viewer bind nbhood <Button-1> {NbhoodPoint %W %x %y}
        }

    }

    # CreateMenuBar
    #
    # Creates the main menu bar

    method CreateMenuBar {} {
        # Menu Bar
        set menu [menu $win.menubar -relief flat]
        $win configure -menu $menu
        
        # File Menu
        set filemenu [menu $menu.file]
        $menu add cascade -label "File" -underline 0 -menu $filemenu

        $filemenu add command                  \
            -label     "Open"                  \
            -underline 0                       \
            -command   [mymethod FileOpen]

        $filemenu add command                  \
            -label     "Save"                  \
            -underline 0                       \
            -command   [mymethod FileSave]

        $filemenu add command                  \
            -label     "Save As..."            \
            -underline 5                       \
            -command   [mymethod FileSaveAs]

        $filemenu add separator

        $filemenu add command                  \
            -label     "Import Map..."         \
            -underline 4                       \
            -command   [mymethod FileImportMap]

        $filemenu add separator
        
        $filemenu add command                \
            -label       "Exit"              \
            -underline   1                   \
            -accelerator "Ctrl+Q"            \
            -command     [list app exit]
        bind $win <Control-q> [list app exit]

        # Edit menu
        set editmenu [menu $menu.edit]
        $menu add cascade -label "Edit" -underline 0 -menu $editmenu
        
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

    # CreateComponents
    #
    # Creates the main window's components

    method CreateComponents {} {
        # FIRST, prepare the grid.  The scrolling log/shell paner
        # should stretch vertically on resize; the others shouldn't.
        # And everything should stretch horizontally.

        grid rowconfigure $win 0 -weight 0
        grid rowconfigure $win 1 -weight 1
        grid rowconfigure $win 2 -weight 0
        grid rowconfigure $win 3 -weight 0

        grid columnconfigure $win 0 -weight 1

        # NEXT, put in the row widgets

        # ROW 0, add a separator between the menu bar and the rest of the
        # window.
        frame $win.sep0 -height 2 -relief sunken -borderwidth 2

        # ROW 1, create the paner for the map/cli
        paner $win.paner -orient vertical -showhandle 1

        # ROW 2, add a separator
        frame $win.sep2 -height 2 -relief sunken -borderwidth 2

        # ROW 3, Create the Message line.
        install msgline using messageline $win.msgline

        # NEXT, add the mapviewer to the paner
        install viewer using mapviewer $win.paner.viewer \
            -width   600                                 \
            -height  600

        $win.paner add $win.paner.viewer \
            -sticky  nsew                \
            -minsize 60                  \
            -stretch always

        # NEXT, add the CLI to the paner
        install cli using cli $win.paner.cli \
            -height 8                        \
            -relief flat

        $win.paner add $win.paner.cli \
            -sticky  nsew             \
            -minsize 60               \
            -stretch never

        # NEXT, manage all of the components.
        grid $win.sep0     -sticky ew
        grid $win.paner    -sticky nsew
        grid $win.sep2     -sticky ew
        grid $win.msgline  -sticky ew
    }
   
    #-------------------------------------------------------------------
    # Menu Handlers

    # FileOpen
    #
    # Prompts the user to open a scenario in a particular file.

    method FileOpen {} {
        # FIRST, query for the scenario file name.
        set filename [tk_getOpenFile                      \
                          -parent $win                    \
                          -title "Open Scenario"          \
                          -filetypes {
                              {{Minerva Database} {.mdb} }
                          }]

        # NEXT, If none, they cancelled
        if {$filename eq ""} {
            return
        }

        # NEXT, Ask the app to open the scenario
        app open $filename
    }

    # FileSaveAs
    #
    # Prompts the user to save the scenario as a particular file.

    method FileSaveAs {} {
        # FIRST, query for the scenario file name.  If the file already
        # exists, the dialog will automatically query whether to 
        # overwrite it or not.
        set filename [tk_getSaveFile                       \
                          -parent $win                     \
                          -title "Save Scenario As"        \
                          -filetypes {
                              {{Minerva Database} {.mdb} }
                          }]

        # NEXT, If none, they cancelled.
        if {$filename eq ""} {
            return
        }

        # NEXT, Ask the app to save using this name
        app save $filename
    }

    # FileSave
    #
    # Saves the scenario to the current file, making a backup
    # copy.

    method FileSave {} {
        # FIRST, if no file name is known, do a SaveAs.
        if {[app dbfile] eq ""} {
            $type SaveAs
            return
        }

        # NEXT, Ask the app to save to the current dbfile
        app save
    }

    # FileImportMap
    #
    # Asks the user to select a map file for import.

    method FileImportMap {} {
        # FIRST, query for a map file.
        set filename [tk_getOpenFile                  \
                          -parent $win                \
                          -title "Select a map image" \
                          -filetypes {
                              {{JPEG Images} {.jpg} }
                              {{GIF Images}  {.gif} }
                              {{PNG Images}  {.png} }
                              {{Any File}    *      }
                          }]

        # NEXT, If none, they cancelled
        if {$filename eq ""} {
            return
        }

        # NEXT, Ask the app to import the map
        app importmap $filename
    }

    #-------------------------------------------------------------------
    # Notifier Event Handlers

    # AppOpened
    #
    # A new scenario file has been opened.

    method AppOpened {} {
        # FIRST, set the window title
        set tail [file tail [app dbfile]]

        wm title $win "$tail - Minerva [version]"

        # NEXT, load the map and refresh the graphics
        $self zoom 100

        # NEXT, Notify the user
        app puts "Opened $tail"
    }

    # AppSaved
    #
    # The data has been saved.

    method AppSaved {} {
        set tail [file tail [app dbfile]]

        wm title $win "$tail - Minerva [version]"
        app puts "Saved $tail"
    }

    # AppImportedMap filename
    #
    # filename         Map image file name
    #
    # The user has imported a new map.  Update the GUI accordingly

    method AppImportedMap {filename} {
        $self zoom 100

        $self puts "Imported map [file tail $filename]"
    }

    #-------------------------------------------------------------------
    # Utility Methods

    # zoom ?factor?
    #
    # factor     The zoom factor, as an integer percentage, 
    #            e.g., 50, 100, 200
    #
    # Sets/queries the zoom factor.  When the zoom is set,
    # updates the map display.
    #
    # TBD: If we adopt Pixane, much of this code will move into
    # mapviewer/mapcanvas.

    method zoom {{factor ""}} {
        # FIRST, handle queries
        if {$factor eq ""} {
            return $info(zoom)
        }

        # NEXT, display the desired zoom.
        rdb eval {
            SELECT data FROM maps
            WHERE zoom=$factor
        } {
            # Got it!
            set info(zoom) $factor

            # Create and install the new image in the viewer and
            # refresh it.

            set newMap [image create photo -format jpeg -data $data]

            $viewer configure -map $newMap

            $self refresh

            # Delete the old image, if any.
            if {$info(map) ne ""} {
                image delete $info(map)
            }

            set info(map) $newMap

            # Return the zoom factor.
            return $info(zoom)
        }

        # NEXT, there was no map for this zoom level.
        $self error "No map at zoom \"$zoom\""

        return $info(zoom)
    }

    # refresh
    #
    # Refreshes the data displayed by the viewer on the map.

    method refresh {} {
        # FIRST, clear the viewer, using the current map.
        $viewer clear

        # NEXT, redraw neighborhoods, icons, etc.
        # TBD
    }

    # error text
    #
    # text       A tsubst'd text string
    #
    # Displays the error in a message box

    method error {text} {
        set text [uplevel 1 [list tsubst $text]]

        tk_messageBox      \
            -default ok    \
            -message $text \
            -icon    error \
            -parent  $win  \
            -type    ok
    }

    # puts text
    #
    # text     A text string
    #
    # Writes the text to the message line

    method puts {text} {
        $msgline puts $text
    }
}


