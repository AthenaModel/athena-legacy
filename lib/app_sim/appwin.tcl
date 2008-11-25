#-----------------------------------------------------------------------
# TITLE:
#    appwin.tcl
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
# appwin

snit::widget appwin {
    hulltype toplevel

    #-------------------------------------------------------------------
    # Components

    component cli                   ;# The cli(n) pane
    component msgline               ;# The messageline(n)
    component content               ;# The content notebook
    component viewer -public viewer ;# The mapviewer(n)
    component slog                  ;# The scrolling log
 
    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    # -main flag
    #
    # If "yes", this is the main application window.  Otherwise,
    # this is just a browser window. This may affect the components, 
    # the menus, and so forth.
    
    option -main      \
        -default  no \
        -readonly yes

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
        # FIRST, get the options
        $self configurelist $args

        # NEXT, set the default window title
        # TBD: Not here.
        wm title $win "Untitled - Minerva [version]"

        # NEXT, Exit the app when this window is closed, if it's a 
        # main window.
        if {$options(-main)} {
            wm protocol $win WM_DELETE_WINDOW [mymethod FileExit]
        }

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
        notifier bind ::scenario <Reconfigure>   $self [mymethod Reconfigure]
        notifier bind ::scenario <ScenarioSaved> $self [mymethod Reconfigure]

        # NEXT, Prepare to receive window events
        bind $content <<NotebookTabChanged>> [mymethod Reconfigure]

        bind $viewer <<Icon-1>>       [mymethod Icon-1 %d]
        bind $viewer <<Nbhood-1>>     [mymethod Nbhood-1 %d]

        # NEXT, prepare to append pucked points, etc., to the CLI
        if {$options(-main)} {
            bind $viewer <<Point-1>>      [mymethod Point-1 %d]
            bind $viewer <<PolyComplete>> [mymethod PolyComplete %d]
        }

        # NEXT, Reconfigure self on creation
        $self Reconfigure
    }

    destructor {
        notifier forget $self
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
            -label       "New Browser"         \
            -underline   4                     \
            -accelerator "Ctrl+N"              \
            -command     [list appwin new]
        bind $win <Control-n> [list appwin new]
        
        $filemenu add command                  \
            -label     "New Scenario..."       \
            -underline 0                       \
            -command   [mymethod FileNew]

        $filemenu add command                  \
            -label     "Open Scenario..."      \
            -underline 0                       \
            -command   [mymethod FileOpen]

        $filemenu add command                  \
            -label       "Save Scenario"       \
            -underline   0                     \
            -accelerator "Ctrl+S"              \
            -command     [mymethod FileSave]
        bind $win <Control-s> [mymethod FileSave]

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

        if {$options(-main)} {
            $filemenu add command                  \
                -label       "Exit"                \
                -underline   1                     \
                -accelerator "Ctrl+Q"              \
                -command     [mymethod FileExit]
            bind $win <Control-q> [mymethod FileExit]
        } else {
            $filemenu add command                  \
                -label       "Close Window"        \
                -underline   6                     \
                -accelerator "Ctrl+W"              \
                -command     [list destroy $win]
            bind $win <Control-w> [list destroy $win]
        }

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
        
        $self AddOrder $ordersmenu NBHOOD:CREATE
        $self AddOrder $ordersmenu NBHOOD:MODIFY
        $self AddOrder $ordersmenu NBHOOD:LOWER
        $self AddOrder $ordersmenu NBHOOD:RAISE
    }

    # AddOrder mnu order
    #
    # mnu    A pull-down menu
    # order  An order name
    #
    # Adds a menu item for the order

    method AddOrder {mnu order} {
        $mnu add command \
            -label   [ordergui meta $order title] \
            -command [list ordergui enter $win $order]
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

        # ROW 1, create the content widgets.  If this is a main window,
        # then we have a paner containing the content notebook with 
        # a CLI underneath.  Otherwise, we get just the content
        # notebook.
        if {$options(-main)} {
            paner $win.paner -orient vertical -showhandle 1
            install content using ttk::notebook $win.paner.content \
                -padding 2 

            $win.paner add $content \
                -sticky  nsew       \
                -minsize 120        \
                -stretch always

            set row1 $win.paner
        } else {
            install content using ttk::notebook $win.content \
                -padding 2 

            set row1 $win.content
        }

        # ROW 2, add a separator
        frame $win.sep2 -height 2 -relief sunken -borderwidth 2

        # ROW 3, Create the Message line.
        install msgline using messageline $win.msgline

        # NEXT, add the mapviewer to the content notebook
        
        install viewer using mapviewer $content.viewer \
            -width   600                                        \
            -height  600

        $content add $viewer \
            -sticky  nsew    \
            -padding 2       \
            -text    "Map"

        # NEXT, add the nbhood browser to the content notebook
        
        nbhoodbrowser $content.nbhoods \
            -width   600                         \
            -height  600

        $content add $content.nbhoods \
            -sticky  nsew                       \
            -padding 2                          \
            -text    "Nbhoods"


        # NEXT, add the scrolling log to the content notebook

        install slog using scrollinglog $content.slog \
            -relief     flat                      \
            -height     30                        \
            -logcmd     [mymethod puts]           \
            -loglevel   "normal"

        $content add $slog \
            -sticky  nsew  \
            -padding 2     \
            -text    "Log"

        $slog load [log cget -logfile]
        log configure -newlogcmd [list $slog load]

        # NEXT, add the CLI to the paner, if needed.
        if {$options(-main)} {
            install cli using cli $win.paner.cli \
                -height 8                        \
                -relief flat
            
            $win.paner add $win.paner.cli \
                -sticky  nsew             \
                -minsize 60               \
                -stretch never

            # Register the CLI, so that history is saved in the 
            # scenario file.
            scenario register [list $cli saveable]
        }

        # NEXT, manage all of the components.
        grid $win.sep0     -sticky ew
        grid $row1         -sticky nsew
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

        # NEXT, Import the map
        if {[catch {
            order send "" client MAP:IMPORT [list filename $filename]
        } result]} {
            app error {
                |<--
                Import failed: [dict get $result filename]

                $filename
            }
        }
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

    # Nbhood-1 n
    #
    # n      A nbhood ID
    #
    # Called when the user clicks on a nbhood.

    method Nbhood-1 {n} {
        rdb eval {SELECT longname FROM nbhoods WHERE n=$n} {}

        $self puts "Found $n: $longname"
    }

    # Point-1 ref
    #
    # ref     A map reference string
    #
    # The user has pucked a point in point mode. Append it to the
    # CLI.

    method Point-1 {ref} {
        $cli append " $ref"
    }

    # PolyComplete poly
    #
    # poly     A list of map references defining a polygon
    #
    # The user has drawn a polygon on the map.  Append it to the
    # CLI.

    method PolyComplete {poly} {
        $cli append " $poly"
    }


    #-------------------------------------------------------------------
    # Notifier Event Handlers

    # Reconfigure
    #
    # Reconfigure the window given the new scenario

    method Reconfigure {} {
        # FIRST, set the window title

        set dbfile [file tail [scenario dbfile]]
        if {$dbfile eq ""} {
            set dbfile "Untitled"
        }

        set tab [$content tab current -text]

        if {$options(-main)} {
            set wintype "Main"
        } else {
            set wintype "Browser"
        }

        wm title $win "$dbfile, $tab - Minerva [version] $wintype"
    }

    #-------------------------------------------------------------------
    # Utility Methods

    # new ?option value...?
    #
    # Creates a new app window.

    typemethod new {args} {
        $type create .%AUTO% {*}$args
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



