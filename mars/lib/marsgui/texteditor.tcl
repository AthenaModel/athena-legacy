#-----------------------------------------------------------------------
# TITLE:
#    texteditor.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Mars marsgui(n) package: Simple Text Editor
#
#    This widget provides a simple text editor window for editing
#    text files within a larger application.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::marsgui:: {
    namespace export texteditor
}


#-----------------------------------------------------------------------
# The Texteditor Widget Type

snit::widget ::marsgui::texteditor {
    hulltype toplevel
    widgetclass TextEditor

    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        # Add defaults to the option database
        option add *TextEditor.background         white
        option add *TextEditor.Foreground         black
        option add *TextEditor.font               codefont
        option add *TextEditor.width              80
        option add *TextEditor.height             24
    }

    #-------------------------------------------------------------------
    # Components

    component text    ;# The Tk text widget

    #-------------------------------------------------------------------
    # Options

    # Options delegated to hull
    delegate option * to hull

    # Options delegated to text
    delegate option -height     to text
    delegate option -width      to text
    delegate option -background to text
    delegate option -foreground to text
    delegate option -font       to text

    # -title
    #
    # Window title.  The default is set in the constructor.
    option -title -default {} -configuremethod CfgTitle

    method CfgTitle {opt val} {
        set options($opt) $val
        $self SetFileName $currentFile
    }

    # -initialdir
    #
    # Initial directory for opening and saving.  Defaults to [pwd],
    # which is set in the constructor.
    option -initialdir -default {}

    # -filetypes
    #
    # File pattern list for open and save; see tk_getOpenFile(n).
    # Default is "*.txt"
    option -filetypes -default {
        {"Text file" {.txt}}
        {"All files" {*}}
    }

    #-------------------------------------------------------------------
    # Instance variables

    variable currentFile ""       ;# Name of the loaded file.
    variable message     ""       ;# Message shown by message line.

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, create the menu bar
        set menubar [menu $win.menubar]
        $win configure -menu $menubar

        # NEXT, create the File menu
        set filemenu [menu $menubar.file]
        $menubar add cascade -label "File" -underline 0 -menu $filemenu

        $filemenu add command \
            -label "Open File..." \
            -underline 0 \
            -accelerator "Ctrl+O" \
            -command [mymethod open]
        bind $win <Control-o> [mymethod open]

        $filemenu add command \
            -label "Save File" \
            -underline 0 \
            -accelerator "Ctrl+S" \
            -command [mymethod SaveFile]
        bind $win <Control-s> [mymethod SaveFile]

        $filemenu add command \
            -label "Save File As..." \
            -underline 10 \
            -command [mymethod SaveAs]

        $filemenu add separator

        $filemenu add command \
            -label "Close Window" \
            -underline 6 \
            -accelerator "Ctrl+W" \
            -command [mymethod Close]
        bind $win <Control-w> [mymethod Close]

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

        # NEXT, create the text widget
        install text using text $win.text \
            -wrap           none \
            -undo           1 \
            -autoseparators 1 \
            -yscrollcommand [list $win.yscroll set] \
            -xscrollcommand [list $win.xscroll set]

        scrollbar $win.yscroll \
            -orient vertical \
            -command [list $text yview]

        scrollbar $win.xscroll \
            -orient horizontal \
            -command [list $text xview]

        label $win.msgline \
            -textvariable [myvar message] \
            -anchor w \
            -justify left

        # NEXT, grid everything.
        grid columnconfigure $win 0 -weight 1
        grid columnconfigure $win 1 -weight 0

        grid rowconfigure $win 0 -weight 1
        grid rowconfigure $win 1 -weight 0

        grid $win.text     $win.yscroll -sticky nsew
        grid $win.xscroll               -sticky nsew
        grid $win.msgline -columnspan 2 -sticky ew

        # NEXT, set the hull's background to the default, so that
        # the lower-right corner is properly colored.
        $hull configure -background $::marsgui::defaultBackground
        
        # NEXT, set the default window title.
        set options(-title) "[wm title .] Text Editor"
        $self SetFileName ""

        # Handle the command-line arguments
        $self configurelist $args
    }

    #-------------------------------------------------------------------
    # Private Methods

    # Close
    #
    # Destroy this console.
    
    method Close {} {
        destroy $win
    }

    # SetFileName filename
    #
    # Sets the filename variable and updates the window title.

    method SetFileName {filename} {
        if {$filename eq ""} {
            set nameString "(untitled)"
        } else {
            set nameString [file tail $filename]
        }

        set currentFile $filename

        wm title $win "$options(-title): $nameString"
    }

    # SaveFile
    #
    # Saves the text to the current file name, first making a backup
    # file, "<name>~".  If the document is untitled, calls SaveAs to
    # prompt for a file name.

    method SaveFile {} {
        # FIRST, if the file is untitled, call SaveAs to prompt for 
        # a title.
        if {$currentFile eq ""} {
            $self SaveAs
            return
        }

        # NEXT, copy the file to its backup.
        if {[file exists $currentFile]} {
            if {[catch {file copy -force $currentFile "$currentFile~"} result]} {
                set message "Error, $result"
                bell
                return
            }
        }

        # NEXT, save the current text.
        if {[catch {
            set f [open $currentFile w]
            puts $f [$text get 1.0 "end - 1 chars"]
            close $f
        } result]} {
            set message "Error, $result"
            bell
            return
        }

        $text edit modified 0
        $text edit reset

        set message "Saved."
    }

    # SaveAs
    #
    # Prompts for a new file name, and saves the file under that
    # name.

    method SaveAs {} {
        set filename [tk_getSaveFile \
                          -initialfile $currentFile \
                          -initialdir $options(-initialdir) \
                          -filetypes $options(-filetypes) \
                          -title "Save File As..." \
                          -parent $win]

        if {$filename eq ""} {
            set message "Cancelled."
            return
        }

        $self SetFileName $filename
        $self SaveFile
    }

    #-------------------------------------------------------------------
    # Public Methods

    # load filename
    #
    # filename      A file name
    #
    # Attempts to load the named file into the editor.  If the named
    # file doesn't exist, a blank file with the given name is opened.

    method load {filename} {
        if {[$text edit modified]} {
            set message "Please save first."
            bell
            return
        }

        if {[file exists $filename]} {
            set f [open $filename]

            set content [read $f]

            close $f

            $text delete 1.0 end
            $text insert end $content
            $text mark set insert 1.0
            $text see 1.0

            set message "Loaded: $filename"
        } else {
            $text delete 1.0 end
            set message "New file: $filename"
        }

        $text edit modified 0
        $text edit reset
        $self SetFileName $filename
    }

    # open ?filename?
    #
    # Prompts for the file name if none is given, and opens the
    # named file.

    method open {{filename ""}} {
        if {[$text edit modified]} {
            set message "Please save first."
            bell
            return
        }

        if {$filename eq ""} {
            set filename [tk_getOpenFile \
                              -parent $win \
                              -initialdir $options(-initialdir) \
                              -filetypes $options(-filetypes) \
                              -title "Open Text File"]
            if {$filename eq ""} {
                set message "Cancelled."
                return
            }
        }

        $win load $filename
    }
}




