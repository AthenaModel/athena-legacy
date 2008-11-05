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
    typecomponent mdb                ;# The scenario MDB

    #-------------------------------------------------------------------
    # Type Variables

    # Info Array: most scalars are stored here
    #
    # dbfile      Name of the current scenario file
    # map         Current map image, or ""

    typevariable info -array {
        dbfile ""
        map    ""
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
        wm title . "Untitled - Minerva [version]"

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

        # NEXT, open the scenario database
        scenario ::mdb
        mdb open :memory:
        mdb clear

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

        $filemenu add command                  \
            -label     "Open"                  \
            -underline 0                       \
            -command   [mytypemethod Open]

        $filemenu add command                  \
            -label     "Save"                  \
            -underline 0                       \
            -command   [mytypemethod Save]

        $filemenu add command                  \
            -label     "Save As..."            \
            -underline 5                       \
            -command   [mytypemethod SaveAs]

        $filemenu add separator

        $filemenu add command                  \
            -label     "Import Map..."         \
            -underline 4                       \
            -command   [mytypemethod ImportMap]

        $filemenu add separator
        
        $filemenu add command                \
            -label       "Exit"              \
            -underline   1                   \
            -accelerator "Ctrl+Q"            \
            -command     [mytypemethod exit]
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
    # Menu Handlers

    # Open
    #
    # Prompts the user to open a scenario in a particular file.
    # The contents of the file is copied into the MDB.
    #
    # TBD: Need to implement read-only mode for sqldocument(n),
    # including turning off journalling!

    typemethod Open {} {
        # FIRST, query for the scenario file name.
        set filename [tk_getOpenFile             \
                          -parent .              \
                          -title "Open Scenario" \
                          -filetypes {
                              {{Minerva Database} {.mdb} }
                          }]

        # If none, they cancelled
        if {$filename eq ""} {
            return
        }

        # NEXT, can we open the file?  Is it a valid file?
        # TBD: How do we know?

        # NEXT, It's a valid file.  Clear the MDB and load the data
        mdb clear
        mdb eval "
            COMMIT TRANSACTION;
            ATTACH DATABASE '$filename' AS source
        "

        # NEXT, copy the tables
        set destTables [mdb eval {
            SELECT name FROM sqlite_master 
            WHERE type='table'
            AND name NOT GLOB '*sqlite*'
            AND name NOT glob 'sqldocument_*'
        }]

        set sourceTables [mdb eval {
            SELECT name FROM source.sqlite_master 
            WHERE type='table'
            AND name NOT GLOB '*sqlite*'
        }]

        mdb transaction {
            foreach table $destTables {
                if {$table ni $sourceTables} {
                    continue
                }

                mdb eval "INSERT INTO main.$table SELECT * FROM source.$table"
            }
        }

        # NEXT, detach the saveas database.
        mdb eval {
            DETACH DATABASE source;
            BEGIN IMMEDIATE TRANSACTION
        }

        # NEXT, Refresh the GUI.
        $viewer configure -map ""
        $viewer clear
        if {$info(map) ne ""} {
            image delete $info(map)
            set info(map) ""
        }
        $type SetMap 100

        set info(dbfile) $filename
        wm title . "[file tail $filename] - Minerva [version]"
    }

    # SaveAs
    #
    # Prompts the user to save the scenario as a particular file.

    typemethod SaveAs {} {
        # FIRST, query for the scenario file name.
        set filename [tk_getSaveFile             \
                          -parent .              \
                          -title "Save Scenario As" \
                          -filetypes {
                              {{Minerva Database} {.mdb} }
                          }]

        # If none, they cancelled
        if {$filename eq ""} {
            return
        }

        # TBD: Make sure we don't overwrite by accident!
        mdb saveas $filename

        set info(dbfile) $filename
        wm title . "[file tail $filename] - Minerva [version]"
    }

    # Save
    #
    # Saves the scenario to the current file, making a backup
    # copy.

    typemethod Save {} {
        # FIRST, if no file name is known, do a SaveAs.
        if {$info(dbfile) eq ""} {
            $type SaveAs
            return
        }

        # NEXT, if there's an existing file, which there surely is,
        # save it as a backup file.
        file rename -force $info(dbfile) [file rootname $info(dbfile)].bak
 
        # NEXT, save it.
        mdb saveas $info(dbfile)
    }

    # ImportMap
    #
    # Asks the user to select a map file, and pulls it into the MDB.

    typemethod ImportMap {} {
        # FIRST, query for a map file.
        set filename [tk_getOpenFile             \
                          -parent .              \
                          -title "Select a map image" \
                          -filetypes {
                              {{JPEG Images} {.jpg} }
                              {{GIF Images}  {.gif} }
                              {{PNG Images}  {.png} }
                              {{Any File}    *      }
                          }]

        # If none, they cancelled
        if {$filename eq ""} {
            return
        }

        # NEXT, is it a real image?
        if {[catch {
            set map [image create photo -file $filename]
        } result]} {
            app error {
                |<--
                Could not open the specified file as a map image:

                $filename
            }

            return
        }
        
        # NEXT, get the image data, and save it in the MDB
        set data [$map data -format jpeg]

        mdb eval {
            INSERT OR REPLACE
            INTO maps(zoom, data)
            VALUES(100,$data);
        }

        image delete $map

        # NEXT, make this the displayed map
        $type SetMap 100
    }


    # SetMap zoom
    #
    # zoom         A zoom factor
    # 
    # Loads the specified map into the viewer

    typemethod SetMap {zoom} {
        # FIRST, retrieve the map data from the MDB.
        mdb eval {
            SELECT data FROM maps
            WHERE zoom=$zoom
        } {
            # Got it!
            set newMap [image create photo -format jpeg -data $data]

            $viewer configure -map $newMap
            $viewer clear

            if {$info(map) ne ""} {
                image delete $info(map)
            }

            set info(map) $newMap

            return
        }

        # NEXT, there was no map for this zoom level.
        app error "No map at zoom \"$zoom\""
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

    # error text
    #
    # text       A tsubst'd text string
    #
    # Displays the error in a message box

    typemethod error {text} {
        set text [uplevel 1 [list tsubst $text]]

        tk_messageBox \
            -default ok \
            -message $text \
            -icon    error \
            -parent  .     \
            -type    ok
    }

    # exit
    #
    # Exits the program

    typemethod exit {} {
        exit
    }
}







