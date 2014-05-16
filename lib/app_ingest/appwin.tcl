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
#    application-wide resources.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# appwin

snit::widget appwin {
    hulltype toplevel

    #-------------------------------------------------------------------
    # Components

    component editmenu              ;# The Edit menu
    component toolbar               ;# Application tool bar
    component wizard                ;# Wizard manager
    component msgline               ;# The message line

    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    #-------------------------------------------------------------------
    # Instance variables

    # TBD

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, withdraw the hull widget, until it's populated.
        wm withdraw $win

        # NEXT, get the options
        $self configurelist $args

        # NEXT, create the menu bar
        $self CreateMenuBar

        # NEXT, create components.
        $self CreateComponents
        
        # NEXT, Allow the created widget sizes to propagate to
        # $win, so the window gets its default size; then turn off 
        # propagation.  From here on out, the user is in control of the 
        # size of the window.

        update idletasks
        grid propagate $win off

        # NEXT, Exit the app when this window is closed.
        wm protocol $win WM_DELETE_WINDOW [mymethod FileExit]

        # NEXT, Allow the developer to pop up the debugger.
        bind all <Control-F9> [list debugger new]

        # NEXT, start the wizard going.
        $wizard start

        # NEXT, restore the window
        wm title $win "Athena DCGS V3 Ingest [projinfo version] ([projinfo build])"
        wm deiconify $win
        raise $win

        # NEXT, prepare to receive events
        notifier bind ::ingester <update> $win [list $wizard refresh]

    }

    destructor {
        notifier forget $self
    }

    # CreateMenuBar
    #
    # Creates the application menus

    method CreateMenuBar {} {
        # FIRST, create the menu bar
        set menubar [menu $win.menubar -borderwidth 0]
        $win configure -menu $menubar

        # NEXT, create the File menu
        set menu [menu $menubar.file]
        $menubar add cascade -label "File" -underline 0 -menu $menu

        $menu add command \
            -label       "Quit"   \
            -underline   0        \
            -accelerator "Ctrl+Q" \
            -command     [mymethod FileExit]
        bind $win <Control-q> [mymethod FileExit]
        bind $win <Control-Q> [mymethod FileExit]

        # NEXT, create the Edit menu
        set editmenu [menu $menubar.edit]
        $menubar add cascade -label "Edit" -underline 0 -menu $editmenu
    
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
        
        $editmenu add command \
            -label "Select All" \
            -underline 0 \
            -accelerator "Ctrl+Shift+A" \
            -command {event generate [focus] <<SelectAll>>}
    }

    #-------------------------------------------------------------------
    # Components

    # CreateComponents
    #
    # Creates the main window's components.

    method CreateComponents {} {
        # FIRST, prepare the grid.
        grid rowconfigure $win 0 -weight 0 ;# Separator
        grid rowconfigure $win 1 -weight 1 ;# Content
        grid rowconfigure $win 2 -weight 0 ;# Separator
        grid rowconfigure $win 3 -weight 0 ;# Status Line

        grid columnconfigure $win 0 -weight 1

        # NEXT, put in the row widgets

        # ROW 0, add a separator between the menu bar and the rest of the
        # window.
        ttk::separator $win.sep0

        # ROW 1, create the wizard manager.
        install wizard using wizman $win.wizard

        # ROW 2, add a separator
        ttk::separator $win.sep2

        # ROW 3, Create the Status Line frame.
        ttk::frame $win.status    \
            -borderwidth        2 

        # Message line
        install msgline using messageline $win.status.msgline

        pack $win.status.msgline -fill both -expand yes

        # NEXT, add the initial wizard pages to the content notebook.

        $wizard add [wizscenario $win.scenario]
        $wizard add [wiztigr     $win.tigr]
        $wizard add [wizsorter   $win.sorter]
        $wizard add [wizevents   $win.events]
        $wizard add [wizexport   $win.export]

        # NEXT, manage all of the components.
        grid $win.sep0     -sticky ew
        grid $win.wizard   -sticky nsew
        grid $win.sep2     -sticky ew
        grid $win.status   -sticky ew
    }

    #-------------------------------------------------------------------
    # Menu Item Handlers

    # FileExit
    #
    # Verifies that the user has saved data before exiting.

    method FileExit {} {
        # FIRST, Allow the user to save unsaved data.
        if 0 {
            if {![$self SaveUnsavedData]} {
                return
            }
        }

        # NEXT, the data has been saved if it's going to be; so exit.
        app exit
    }


    
    #-------------------------------------------------------------------
    # Utility Routines

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

