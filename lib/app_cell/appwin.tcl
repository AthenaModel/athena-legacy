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
    component toolbar               ;# Application tool bar
    component content               ;# Tabbed notebook for content
    component cmeditor              ;# cellmodel(5) script editor
    component detail                ;# Detail browser
    component cli                   ;# CLI
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

        # NEXT, Prepare to receive notifier events.
        notifier bind ::cmscript <Update> $self [mymethod SetWindowTitle]

        # NEXT, Prepare to receive window events

        # NEXT, Exit the app when this window is closed.
        wm protocol $win WM_DELETE_WINDOW {app exit}

        # NEXT, Allow the developer to pop up the debugger.
        bind all <Control-F9> [list debugger new]

        # NEXT, restore the window
        wm title $win "Athena Cell [version]"
        wm deiconify $win
        raise $win

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
        set filemenu [menu $menubar.file]
        $menubar add cascade -label "File" -underline 0 -menu $filemenu

        $filemenu add command \
            -label       "New File" \
            -underline   0 \
            -accelerator "Ctrl+N" \
            -command     [mymethod FileNew]
        bind $win <Control-n> [mymethod FileNew]
        bind $win <Control-N> [mymethod FileNew]

        $filemenu add command \
            -label       "Open File..." \
            -underline   0              \
            -accelerator "Ctrl+O"       \
            -command     [mymethod FileOpen]
        bind $win <Control-o> [mymethod FileOpen]
        bind $win <Control-O> [mymethod FileOpen]

        $filemenu add command \
            -label       "Save File" \
            -underline   0           \
            -accelerator "Ctrl+S"    \
            -command     [mymethod FileSave]
        bind $win <Control-s> [mymethod FileSave]
        bind $win <Control-S> [mymethod FileSave]

        $filemenu add command \
            -label     "Save File As..." \
            -underline 10                \
            -command   [mymethod FileSaveAs]

        $filemenu add separator

        $filemenu add command \
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
            -label "Undo" \
            -underline 0 \
            -accelerator "Ctrl+Z" \
            -command {event generate [focus] <<Undo>>}

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
        grid rowconfigure $win 1 -weight 0 ;# Tool Bar
        grid rowconfigure $win 2 -weight 0 ;# Separator
        grid rowconfigure $win 3 -weight 1 ;# Content
        grid rowconfigure $win 4 -weight 0 ;# Separator
        grid rowconfigure $win 5 -weight 0 ;# Status Line

        grid columnconfigure $win 0 -weight 1

        # NEXT, put in the row widgets

        # ROW 0, add a separator between the menu bar and the rest of the
        # window.
        ttk::separator $win.sep0

        # ROW 1, add a toolbar
        install toolbar using ttk::frame $win.toolbar

        # New File
        ttk::button $toolbar.new \
            -style   Toolbutton               \
            -image   ::marsgui::icon::newfile \
            -command [mymethod FileNew]
        DynamicHelp::add $toolbar.new -text "New File"
        
        # Open File
        ttk::button $toolbar.open \
            -style   Toolbutton                 \
            -image   ::marsgui::icon::openfile \
            -command [mymethod FileOpen]
        DynamicHelp::add $toolbar.open -text "Open File..."

        # Save File
        ttk::button $toolbar.save \
            -style   Toolbutton                \
            -image   ::marsgui::icon::savefile \
            -command [mymethod FileSave]
        DynamicHelp::add $toolbar.save -text "Save File"
        
        # Check File
        ttk::button $toolbar.check \
            -style   Toolbutton               \
            -image   ::marsgui::icon::check22 \
            -command [mymethod FileCheck]
        DynamicHelp::add $toolbar.check -text "Check File"
        

        pack $toolbar.new   -side left
        pack $toolbar.open  -side left
        pack $toolbar.save  -side left
        pack $toolbar.check -side left -padx {10 0}

        # ROW 2, add a separator between the tool bar and the content
        # window.
        ttk::separator $win.sep2

        # ROW 3, create the content widgets.
        ttk::panedwindow $win.paner -orient vertical

        install content using ttk::notebook $win.paner.content \
            -padding 2 

        $win.paner add $content \
            -weight 1

        # ROW 4, add a separator
        ttk::separator $win.sep4

        # ROW 5, Create the Status Line frame.
        ttk::frame $win.status    \
            -borderwidth        2 

        # Message line
        install msgline using messageline $win.status.msgline

        pack $win.status.msgline -fill both -expand yes

        # NEXT, add the content tabs

        # Script Editor
        install cmeditor using cmscripteditor $content.cmeditor
        cmscript register $cmeditor

        $content add $cmeditor \
            -sticky  nsew \
            -padding 2 \
            -text    "Script"

        # Detail Browser
        install detail using detailbrowser $content.detail
        $content add $detail  \
            -sticky  nsew     \
            -padding 2        \
            -text    "Detail"

        # NEXT, add the CLI to the paner
        # TBD: For now, connect to the main interpreter.
        install cli using cli $win.paner.cli    \
            -height    10                       \
            -relief    flat                     \
            -maxlines  1000                     \
            -promptcmd [mymethod CliPrompt]     \
            -evalcmd   [list uplevel #0]
        $win.paner add $cli

        # NEXT, manage all of the components.
        grid $win.sep0     -sticky ew
        grid $toolbar      -sticky ew
        grid $win.sep2     -sticky ew
        grid $win.paner    -sticky nsew
        grid $win.sep4     -sticky ew
        grid $win.status   -sticky ew
    }

    #-------------------------------------------------------------------
    # Menu Item Handlers

    # FileNew
    #
    # Prompts the user to create a brand new script.

    method FileNew {} {
        # FIRST, Allow the user to save unsaved data.
        if {![$self SaveUnsavedData]} {
            return
        }

        # NEXT, create the new script
        cmscript new
    }

    # FileOpen
    #
    # Prompts the user to open a script file.

    method FileOpen {} {
        # FIRST, Allow the user to save unsaved data.
        if {![$self SaveUnsavedData]} {
            return
        }

        # NEXT, query for the script file name.
        set filename [tk_getOpenFile                      \
                          -parent $win                    \
                          -title "Open Cell Model"        \
                          -filetypes {
                              {{cellmodel(5) script}     {.cm} }
                          }]

        # NEXT, If none, they cancelled
        if {$filename eq ""} {
            return
        }

        # NEXT, Open the requested script.
        cmscript open $filename
    }

    # FileSaveAs
    #
    # Prompts the user to save the script as a particular file.

    method FileSaveAs {} {
        # FIRST, query for the script file name.  If the file already
        # exists, the dialog will automatically query whether to 
        # overwrite it or not. Returns 1 on success and 0 on failure.

        set filename [tk_getSaveFile                       \
                          -parent $win                     \
                          -title "Save Cell Model As"        \
                          -filetypes {
                              {{cellmodel(5) script} {.cm} }
                          }]

        # NEXT, If none, they cancelled.
        if {$filename eq ""} {
            return 0
        }

        # NEXT, Save the script using this name
        return [cmscript save $filename]
    }

    # FileSave
    #
    # Saves the script to the current file, making a backup
    # copy.  Returns 1 on success and 0 on failure.

    method FileSave {} {
        # FIRST, if no file name is known, do a SaveAs.
        if {[cmscript cmfile] eq ""} {
            return [$self FileSaveAs]
        }

        # NEXT, Save the script to the current file.
        return [cmscript save]
    }

    # SaveUnsavedData
    #
    # Allows the user to save unsaved changes.  Returns 1 if the user
    # is ready to proceed, and 0 if the current activity should be
    # cancelled.

    method SaveUnsavedData {} {
        if {[cmscript unsaved]} {
            # FIRST, deiconify the window, this gives the message box
            # a parent to popup over.
            wm deiconify $win

            # NEXT, popup the message box for the user
            set name [file tail [cmscript cmfile]]

            set message [tsubst {
                |<--
                The cell model [tif {$name ne ""} {"$name" }]has not been saved.
                Do you want to save your changes?
            }]

            set answer [messagebox popup                     \
                            -icon    warning                 \
                            -message $message                \
                            -parent  $win                    \
                            -title   "Athena Cell [version]" \
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


    # FileCheck
    #
    # Checks the syntax of the current model.

    method FileCheck {} {
        lassign [cmscript check] code line errmsg

        if {$code eq "SYNTAX"} {
            $self ShowFileSyntaxError $line $errmsg
        } elseif {$code eq "INSANE"} {
            $self ShowFileSanityError
        } else {
            $self puts "The model loaded successfully, and appears to be sane."
        }
    }

    # ShowFileSyntaxError line errmsg
    #
    # line    - The line number
    # errmsg  - The error message
    #
    # Jumps to the line with the error in the editor, and displays an
    # error dialog.

    method ShowFileSyntaxError {line errmsg} {
        # FIRST, jump to the error.
        $cmeditor mark set insert $line.0
        $cmeditor see insert

        # NEXT, display the messagebox.
        set message [tsubst {
            |<--
            The cell model has an error at line $line:

            $errmsg
        }]

        messagebox popup                \
            -icon    error              \
            -message $message           \
            -parent  $win               \
            -title   "Syntax Error"     \
            -buttons { ok "OK" }

        # NEXT, set the focus to the editor, so they can see the insertion
        # point at the error location.
        $cmeditor focus
    }

    # ShowFileSanityError
    #
    # Displays a message if the file is not sane.

    method ShowFileSanityError {} {
        set message [normalize {
            The cell model syntax is OK, but the model is not sane.
            Press the "Model Overview" button, below, to see the details.
        }]

        set answer [messagebox popup    \
            -icon    error              \
            -message $message           \
            -parent  $win               \
            -title   "Sanity Error"     \
            -buttons { 
                overview "Model Overview"
                ok       "OK" 
            }]

        if {$answer eq "overview"} {
            $content select $detail
            $detail show my://app
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

    #-------------------------------------------------------------------
    # Other Event Handlers and Callbacks

    # SetWindowTitle
    #
    # Sets the window title given the current script

    method SetWindowTitle {} {
        # FIRST, get the file name.
        set cmfile [file tail [cmscript cmfile]]

        if {$cmfile eq ""} {
            set cmfile "Untitled"
        }

        wm title $win "Athena Cell [version]: $cmfile"
    }


    # CliPrompt
    #
    # Returns a prompt string for the CLI

    method CliPrompt {} {
        return ">"
    }
    
    #-------------------------------------------------------------------
    # Utility Routines

    # gotoline line
    #
    # line   - A line number in the editor
    #
    # Makes the editor visible and goes to the specified line.

    method gotoline {line} {
        $content select $cmeditor
        $cmeditor mark set insert $line.0
        $cmeditor see insert
        $cmeditor focus
    }

    # show uri
    #
    # uri - A URI
    #
    # Shows the URI in the detail browser, making the detail browser
    # visible.

    method show {uri} {
        $detail show $uri
        $contect select $detail
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
