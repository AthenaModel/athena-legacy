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

    component editmenu              ;# The Edit menu
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

    # Status info
    #
    # simstate    Current simulation state
    # zulutime    Current sim time as a zulu time string

    variable info -array {
        simstate ""
        zulutime ""
    }

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, get the options
        $self configurelist $args

        # NEXT, set the default window title
        # TBD: Not here.
        wm title $win "Untitled - Athena [version]"

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
        notifier bind ::sim      <Reconfigure>   $self [mymethod Reconfigure]
        notifier bind ::scenario <ScenarioSaved> $self [mymethod Reconfigure]
        notifier bind ::sim      <Time>          $self [mymethod Time]
        notifier bind ::sim      <State>         $self [mymethod State]

        # NEXT, Prepare to receive window events
        bind $content <<NotebookTabChanged>> [mymethod Reconfigure]

        bind $viewer <<Unit-1>>       [mymethod Unit-1 %d]
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
        bind $win <Control-N> [list appwin new]
        
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
        bind $win <Control-S> [mymethod FileSave]

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
            bind $win <Control-Q> [mymethod FileExit]
        } else {
            $filemenu add command                  \
                -label       "Close Window"        \
                -underline   6                     \
                -accelerator "Ctrl+W"              \
                -command     [list destroy $win]
            bind $win <Control-w> [list destroy $win]
            bind $win <Control-W> [list destroy $win]
        }

        # Edit menu
        set editmenu [menu $menu.edit \
                          -postcommand [mymethod PostEditMenu]]
        $menu add cascade -label "Edit" -underline 0 -menu $editmenu

        $editmenu add command                \
            -label       "Undo"              \
            -underline   0                   \
            -accelerator "Ctrl+Z"            \
            -command     [mymethod EditUndo]

        bind $win <Control-z> [mymethod EditUndo]
        bind $win <Control-Z> [mymethod EditUndo]

        $editmenu add command                \
            -label       "Redo"              \
            -underline   0                   \
            -accelerator "Ctrl+Shift+Z"      \
            -command     [mymethod EditRedo]

        bind $win <Shift-Control-z> [mymethod EditRedo]
        bind $win <Shift-Control-Z> [mymethod EditRedo]

        $editmenu add separator
        
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

        # Orders/Simulation
        set submenu [menu $ordersmenu.sim]
        $ordersmenu add cascade -label "Simulation" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu SIM:STARTDATE

        # Orders/Unit
        set submenu [menu $ordersmenu.unit]
        $ordersmenu add cascade -label "Unit" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu UNIT:CREATE
        $self AddOrder $submenu UNIT:UPDATE
        $self AddOrder $submenu UNIT:DELETE

        # Orders/Civilian Group
        set submenu [menu $ordersmenu.civgroup]
        $ordersmenu add cascade -label "Civilian Group" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu GROUP:CIVILIAN:CREATE
        $self AddOrder $submenu GROUP:CIVILIAN:UPDATE
        $self AddOrder $submenu GROUP:CIVILIAN:DELETE

        # Orders/Nbhood Group
        set submenu [menu $ordersmenu.nbgroup]
        $ordersmenu add cascade -label "Nbhood Group" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu GROUP:NBHOOD:CREATE
        $self AddOrder $submenu GROUP:NBHOOD:UPDATE
        $self AddOrder $submenu GROUP:NBHOOD:DELETE

        # Orders/Force Group
        set submenu [menu $ordersmenu.frcgroup]
        $ordersmenu add cascade -label "Force Group" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu GROUP:FORCE:CREATE
        $self AddOrder $submenu GROUP:FORCE:UPDATE
        $self AddOrder $submenu GROUP:FORCE:DELETE

        # Orders/Org Group
        set submenu [menu $ordersmenu.orggroup]
        $ordersmenu add cascade -label "Org Group" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu GROUP:ORGANIZATION:CREATE
        $self AddOrder $submenu GROUP:ORGANIZATION:UPDATE
        $self AddOrder $submenu GROUP:ORGANIZATION:DELETE

        # Orders/Neighborhood Menu
        set submenu [menu $ordersmenu.nbhood]
        $ordersmenu add cascade -label "Neighborhood" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu NBHOOD:CREATE
        $self AddOrder $submenu NBHOOD:UPDATE
        $self AddOrder $submenu NBHOOD:LOWER
        $self AddOrder $submenu NBHOOD:RAISE
        $self AddOrder $submenu NBHOOD:DELETE
        $self AddOrder $submenu NBHOOD:RELATIONSHIP:UPDATE

        # Orders/Relationship Menu
        set submenu [menu $ordersmenu.rel]
        $ordersmenu add cascade -label "Relationship" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu RELATIONSHIP:UPDATE

        # Orders/Cooperation Menu
        set submenu [menu $ordersmenu.coop]
        $ordersmenu add cascade -label "Cooperation" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu COOPERATION:UPDATE

        # Orders/Satisfaction Menu
        set submenu [menu $ordersmenu.sat]
        $ordersmenu add cascade -label "Satisfaction" \
            -underline 0 -menu $submenu
        
        $self AddOrder $submenu SATISFACTION:UPDATE
    }

    # AddOrder mnu order
    #
    # mnu    A pull-down menu
    # order  An order name
    #
    # Adds a menu item for the order

    method AddOrder {mnu order} {
        $mnu add command \
            -label   [order title $order]         \
            -command [list order enter $order]
    }

    # CreateComponents
    #
    # Creates the main window's components

    method CreateComponents {} {
        # FIRST, prepare the grid.  The scrolling log/shell paner
        # should stretch vertically on resize; the others shouldn't.
        # And everything should stretch horizontally.

        grid rowconfigure $win 0 -weight 0    ;# Separator
        grid rowconfigure $win 1 -weight 0    ;# Tool Bar
        grid rowconfigure $win 2 -weight 0    ;# Separator
        grid rowconfigure $win 3 -weight 1    ;# Content
        grid rowconfigure $win 4 -weight 0    ;# Separator
        grid rowconfigure $win 5 -weight 0    ;# Status line

        grid columnconfigure $win 0 -weight 1

        # NEXT, put in the row widgets

        # ROW 0, add a separator between the menu bar and the rest of the
        # window.
        frame $win.sep0 -height 2 -relief sunken -borderwidth 2

        # ROW 1, add a simulation toolbar
        frame $win.toolbar        \
            -relief flat          \
            -borderwidth        0 \
            -highlightthickness 0

        # Run
        button $win.toolbar.run  \
            -image      ::projectgui::icon::play22    \
            -relief     flat                          \
            -overrelief raised                        \
            -state      normal                        \
            -command    [mymethod Run]

        DynamicHelp::add $win.toolbar.run -text "Run Simulation"

        
        # Duration

        # Pause

        button $win.toolbar.pause  \
            -image      ::projectgui::icon::pause22   \
            -relief     flat                          \
            -overrelief raised                        \
            -state      normal                        \
            -command    [mymethod Pause]

        DynamicHelp::add $win.toolbar.pause -text "Pause Simulation"


        # Restart

        button $win.toolbar.restart \
            -image      ::projectgui::icon::rewind22  \
            -relief     flat                          \
            -overrelief raised                        \
            -state      normal                        \
            -command    [mymethod Restart]

        DynamicHelp::add $win.toolbar.restart -text "Restart Simulation"


        # Sim State
        label $win.toolbar.simstate                    \
            -borderwidth        1                      \
            -highlightthickness 0                      \
            -font               codefont               \
            -width              7                      \
            -anchor             w                      \
            -textvariable       [myvar info(simstate)]

        # Zulu time
        label $win.toolbar.zulutime                    \
            -borderwidth        1                      \
            -highlightthickness 0                      \
            -font               codefont               \
            -width              12                     \
            -textvariable       [myvar info(zulutime)]

        pack $win.toolbar.run      -side left          
        pack $win.toolbar.pause    -side left
        pack $win.toolbar.restart  -side left
        pack $win.toolbar.zulutime -side right -padx 2 
        pack $win.toolbar.simstate -side right -padx 2 

        # ROW 2, add a separator between the tool bar and the content
        # window.
        frame $win.sep2 -height 2 -relief sunken -borderwidth 2

        # ROW 3, create the content widgets.  If this is a main window,
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

            set row3 $win.paner
        } else {
            install content using ttk::notebook $win.content \
                -padding 2 

            set row3 $win.content
        }

        # ROW 4, add a separator
        frame $win.sep4 -height 2 -relief sunken -borderwidth 2

        # ROW 5, Create the Status Line frame.
        frame $win.status         \
            -relief flat          \
            -borderwidth        2 \
            -highlightthickness 0

        # Message line
        install msgline using messageline $win.status.msgline

        pack $win.status.msgline -fill both -expand yes


        # NEXT, add the mapviewer to the content notebook
        
        install viewer using mapviewer $content.viewer \
            -width   600                                        \
            -height  600

        $content add $viewer \
            -sticky  nsew    \
            -padding 2       \
            -text    "Map"

        # NEXT, add the units browser to the content notebook
        unitbrowser $content.unit      \
            -width   600               \
            -height  600

        $content add $content.unit     \
            -sticky  nsew              \
            -padding 2                 \
            -text    "Units"

        # NEXT, add the nbhood browser to the content notebook
        nbhoodbrowser $content.nbhoods \
            -width   600               \
            -height  600

        $content add $content.nbhoods  \
            -sticky  nsew              \
            -padding 2                 \
            -text    "Nbhoods"

        # NEXT, add the nbrel browser to the content notebook
        nbrelbrowser $content.nbrel    \
            -width   600               \
            -height  600

        $content add $content.nbrel    \
            -sticky  nsew              \
            -padding 2                 \
            -text    "Prox"

        # NEXT, add the CIV group browser to the content notebook
        civgroupbrowser $content.civgroups \
            -width   600                   \
            -height  600

        $content add $content.civgroups    \
            -sticky  nsew                  \
            -padding 2                     \
            -text    "CivGrps"

        # NEXT, add the NB group browser to the content notebook
        nbgroupbrowser $content.nbgroups \
            -width   600                   \
            -height  600

        $content add $content.nbgroups     \
            -sticky  nsew                  \
            -padding 2                     \
            -text    "NbGrps"

        # NEXT, add the satisfaction browser to the content notebook
        satbrowser $content.sat            \
            -width   600                   \
            -height  600

        $content add $content.sat          \
            -sticky  nsew                  \
            -padding 2                     \
            -text    "Sat"

        # NEXT, add the FRC group browser to the content notebook
        frcgroupbrowser $content.frcgroups \
            -width   600                   \
            -height  600

        $content add $content.frcgroups    \
            -sticky  nsew                  \
            -padding 2                     \
            -text    "ForceGrps"

        # NEXT, add the ORG group browser to the content notebook
        orggroupbrowser $content.orggroups \
            -width   600                   \
            -height  600

        $content add $content.orggroups    \
            -sticky  nsew                  \
            -padding 2                     \
            -text    "OrgGrps"

        # NEXT, add the relationship browser to the content notebook
        relbrowser $content.rel            \
            -width   600                   \
            -height  600

        $content add $content.rel          \
            -sticky  nsew                  \
            -padding 2                     \
            -text    "Rel"

        # NEXT, add the cooperation browser to the content notebook
        coopbrowser $content.coop          \
            -width   600                   \
            -height  600

        $content add $content.coop         \
            -sticky  nsew                  \
            -padding 2                     \
            -text    "Coop"

        # NEXT, add the scrolling log to the content notebook

        install slog using scrollinglog $content.slog \
            -relief        flat                       \
            -height        30                         \
            -logcmd        [mymethod puts]            \
            -loglevel      "normal"                   \
            -showloglist   yes                        \
            -rootdir       [workdir join log]         \
            -defaultappdir app_sim                    \
            -format        {
                {zulu  12 yes}
                {v      7 yes}
                {c      9 yes}
                {m      0 yes}
            }


        $content add $slog \
            -sticky  nsew  \
            -padding 2     \
            -text    "Log"

        $slog load [log cget -logfile]
        notifier bind ::app <AppLogNew> $self [list $slog load]

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
        grid $win.toolbar  -sticky ew
        grid $win.sep2     -sticky ew
        grid $row3         -sticky nsew
        grid $win.sep4     -sticky ew
        grid $win.status   -sticky ew
    }
   
    #-------------------------------------------------------------------
    # File Menu Handlers

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
                              {{Athena Scenario} {.adb} }
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
                              {{Athena Scenario} {.adb} }
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
            order send gui MAP:IMPORT [list filename $filename]
        } result]} {
            app error {
                |<--
                Import failed: $result

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

            set answer [messagebox popup                 \
                            -icon    warning             \
                            -message $message            \
                            -parent  $win                \
                            -title   "Athena [version]" \
                            -buttons {
                                save    "Save"
                                discard "Discard"
                                cancel  "Cancel"
                            }]

            if {$answer eq "cancel"} {
                return 0
            } elseif {$answer eq "save"} {
                # Stop exiting if the save failed
                if {![$self FileSave]} {
                    return 0
                }
            }
        }

        return 1
    }

    #-------------------------------------------------------------------
    # Edit Menu Handlers

    # PostEditMenu
    #
    # Enables/Disables the undo/redo menu items when the menu is posted.

    method PostEditMenu {} {
        # Undo item
        set title [cif canundo]

        if {$title ne ""} {
            $editmenu entryconfigure 0 \
                -state normal          \
                -label "Undo $title"
        } else {
            $editmenu entryconfigure 0 \
                -state disabled        \
                -label "Undo"
        }

        # Redo item
        set title [cif canredo]

        if {$title ne ""} {
            $editmenu entryconfigure 1 \
                -state normal          \
                -label "Redo $title"
        } else {
            $editmenu entryconfigure 1 \
                -state disabled        \
                -label "Redo"
        }
    }

    # EditUndo
    #
    # Undoes the top order on the undo stack, if any.

    method EditUndo {} {
        if {[cif canundo] ne ""} {
            cif undo
        }
    }

    # EditRedo
    #
    # Redoes the last undone order if any.

    method EditRedo {} {
        if {[cif canredo] ne ""} {
            cif redo
        }
    }

    #-------------------------------------------------------------------
    # Toolbar Event Handlers

    # Run
    #
    # Sends SIM:RUN

    method Run {} {
        order send gui SIM:RUN
    }


    # Pause
    #
    # Sends SIM:PAUSE

    method Pause {} {
        order send gui SIM:PAUSE
    }


    # Restart
    #
    # Sends SIM:RESTART

    method Restart {} {
        order send gui SIM:RESTART
    }


    #-------------------------------------------------------------------
    # Mapviewer Event Handlers


    # Unit-1 u
    #
    # u      A unit ID
    #
    # Called when the user clicks on a unit icon.

    method Unit-1 {u} {
        rdb eval {SELECT * FROM gui_units WHERE u=$u} row {
        $self puts \
            "Unit $u  at: $row(location)  group: $row(g)  activity: $row(activity)  personnel: $row(personnel)"
        }
    }

    # Nbhood-1 n
    #
    # n      A nbhood ID
    #
    # Called when the user clicks on a nbhood.

    method Nbhood-1 {n} {
        rdb eval {SELECT longname FROM nbhoods WHERE n=$n} {}

        $self puts "Neighborhood $n: $longname"
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

        wm title $win "$dbfile, $tab - Athena [version] $wintype"

        # NEXT, set the status variables
        $self Time
        $self State
    }

    # Time
    #
    # Display the sim time when it is updated.

    method Time {} {
        set info(zulutime) [simclock asZulu]
    }

    # State state
    #
    # Display the sim state when it is updated.

    method State {} {
        set info(simstate) [sim state]
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

        messagebox popup   \
            -message $text \
            -icon    error \
            -parent  $win
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









