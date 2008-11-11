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

    variable info -array {
        map   ""
    }

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, set the default window title
        wm title $win "Untitled - Minerva [version]"

        # NEXT, Exit the app when this window is closed.
        wm protocol $win WM_DELETE_WINDOW [mymethod FileExit]

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
        grid propagate $win off

        # NEXT, Prepare to receive notifier events.
        notifier bind ::scenario <ScenarioNew>    \
            $self [mymethod ScenarioNew]

        notifier bind ::scenario <ScenarioOpened> \
            $self [mymethod ScenarioOpened]

        notifier bind ::scenario <ScenarioSaved>  \
            $self [mymethod ScenarioSaved]

        notifier bind ::app      <AppImportedMap> \
            $self [mymethod AppImportedMap]

        # NEXT, Prepare to receive window events
        bind $viewer <<Icon-1>> [mymethod Icon-1 %d]

        if 0 {
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
            -label     "New Scenario..."       \
            -underline 0                       \
            -command   [mymethod FileNew]

        $filemenu add command                  \
            -label     "Open Scenario..."      \
            -underline 0                       \
            -command   [mymethod FileOpen]

        $filemenu add command                  \
            -label     "Save Scenario"         \
            -underline 0                       \
            -command   [mymethod FileSave]

        $filemenu add command                  \
            -label     "Save Scenario As..."   \
            -underline 14                      \
            -command   [mymethod FileSaveAs]

        $filemenu add separator

        $filemenu add command                  \
            -label     "Import Map..."         \
            -underline 4                       \
            -command   [mymethod FileImportMap]

        $filemenu add separator
        
        $filemenu add command                  \
            -label       "Exit"                \
            -underline   1                     \
            -accelerator "Ctrl+Q"              \
            -command     [mymethod FileExit]
        bind $win <Control-q> [mymethod FileExit]

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

        # Orders menu
        set ordersmenu [menu $menu.orders]
        $menu add cascade -label "Orders" -underline 0 -menu $ordersmenu
        
        $ordersmenu add command \
            -label "Create Neighborhood" \
            -command [list orderdialog enter NBHOOD:CREATE $win]
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

    # FileNew
    #
    # Prompts the user to create a brand new scenario.

    method FileNew {} {
        # FIRST, Allow the user to save unsaved data.
        if {![$self SaveUnsavedData]} {
            return
        }

        # NEXT, create the new scenario
        scenario new
    }

    # FileOpen
    #
    # Prompts the user to open a scenario in a particular file.

    method FileOpen {} {
        # FIRST, Allow the user to save unsaved data.
        if {![$self SaveUnsavedData]} {
            return
        }

        # NEXT, query for the scenario file name.
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

        # NEXT, Open the requested scenario.
        scenario open $filename
    }

    # FileSaveAs
    #
    # Prompts the user to save the scenario as a particular file.

    method FileSaveAs {} {
        # FIRST, query for the scenario file name.  If the file already
        # exists, the dialog will automatically query whether to 
        # overwrite it or not. Returns 1 on success and 0 on failure.

        set filename [tk_getSaveFile                       \
                          -parent $win                     \
                          -title "Save Scenario As"        \
                          -filetypes {
                              {{Minerva Database} {.mdb} }
                          }]

        # NEXT, If none, they cancelled.
        if {$filename eq ""} {
            return 0
        }

        # NEXT, Save the scenario using this name
        return [scenario save $filename]
    }

    # FileSave
    #
    # Saves the scenario to the current file, making a backup
    # copy.  Returns 1 on success and 0 on failure.

    method FileSave {} {
        # FIRST, if no file name is known, do a SaveAs.
        if {[scenario dbfile] eq ""} {
            return [$self FileSaveAs]
        }

        # NEXT, Save the scenario to the current file.
        return [scenario save]
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

    # FileExit
    #
    # Verifies that the user has saved data before exiting.

    method FileExit {} {
        # FIRST, Allow the user to save unsaved data.
        if {![$self SaveUnsavedData]} {
            return
        }

        # NEXT, the data has been saved if it's going to be; so exit.
        app exit
    }

    # SaveUnsavedData
    #
    # Allows the user to save unsaved changes.  Returns 1 if the user
    # is ready to proceed, and 0 if the current activity should be
    # cancelled.

    method SaveUnsavedData {} {
        if {[scenario unsaved]} {
            set name [file tail [scenario dbfile]]

            set message [tsubst {
                |<--
                The scenario [tif {$name ne ""} {"$name" }]has not been saved.
                Do you want to save your changes?
            }]

            set answer [tk_messageBox                    \
                            -icon    warning             \
                            -message $message            \
                            -parent  $win                \
                            -title   "Minerva [version]" \
                            -type    yesnocancel]

            if {$answer eq "cancel"} {
                return 0
            } elseif {$answer eq "yes"} {
                # Stop exiting if the save failed
                if {![$self FileSave]} {
                    return 0
                }
            }
        }

        return 1
    }

    #-------------------------------------------------------------------
    # Mapviewer Event Handlers

    # Icon-1 id
    #
    # id      An icon ID
    #
    # Called when the user clicks on an icon.

    method Icon-1 {id} {
        $self puts "Found $id at [$viewer icon ref $id]"
    }

    #-------------------------------------------------------------------
    # Notifier Event Handlers

    # ScenarioNew
    #
    # A new scenario has been created.

    method ScenarioNew {} {
        # FIRST, set the window title
        wm title $win "Untitled - Minerva [version]"

        # NEXT, refresh the map display
        $viewer newmap

        # NEXT, Notify the user
        $self puts "New scenario created"
    }

    # ScenarioOpened
    #
    # A new scenario file has been opened.

    method ScenarioOpened {} {
        # FIRST, set the window title
        set tail [file tail [scenario dbfile]]

        wm title $win "$tail - Minerva [version]"

        # NEXT, load the map (if any) and refresh the graphics
        $viewer newmap

        # NEXT, Notify the user
        $self puts "Opened $tail"
    }

    # ScenarioSaved
    #
    # The data has been saved.

    method ScenarioSaved {} {
        set tail [file tail [scenario dbfile]]

        wm title $win "$tail - Minerva [version]"
        $self puts "Saved $tail"
    }

    # AppImportedMap filename
    #
    # filename         Map image file name
    #
    # The user has imported a new map.  Update the GUI accordingly

    method AppImportedMap {filename} {
        # Display the new map
        $viewer newmap

        $self puts "Imported map [file tail $filename]"
    }

    #-------------------------------------------------------------------
    # Utility Methods

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


