#-----------------------------------------------------------------------
# TITLE:
#    app.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    mars_commit(1) Application
#
#    This module defines app, the application ensemble.
#
#        package require app_commit
#        app init $argv
#
#    This program is a CM tool for commiting changes to the Subversion
#    repository.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# app ensemble

snit::type app {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Constructor

    # TBD

    #-------------------------------------------------------------------
    # Components

    typecomponent bugnum     ;# Entry for the bug number
    typecomponent changelist ;# Listbox showing the "svn status" output.
    typecomponent commentbox ;# Area to enter a log message
    typecomponent commitbtn  ;# Commit Button
    typecomponent refreshbtn ;# Refresh Button

    #-------------------------------------------------------------------
    # Type Variables

    typevariable bug         ""  ;# Bug number
    typevariable changes     {}  ;# List of "svn status" entries
    typevariable addNewFlag  0   ;# Add new files to repository

    #-------------------------------------------------------------------
    # Application Initializer

    # init argv
    #
    # argv         Command line arguments
    #
    # This the main program.

    typemethod init {argv} {
        # FIRST get the argument, if any.
        if {[llength $argv] > 0} {
            set bug [lindex $argv 0]
            
            if {![string is integer -strict $bug] ||
                $bug <= 0} {
                puts "Invalid bug number: $bug"
                exit 1
            }
        }

        # NEXT, get the changes
        app GetChanges

        # NEXT, create the GUI

        ttk::frame .f

        # Row 0: Tool Bar
        ttk::frame .f.bar
        ttk::label .f.bar.buglabel \
            -text "Bug Number:"

        set bugnum [ttk::entry .f.bar.bugnum           \
                        -width 8                       \
                        -textvariable [mytypevar bug]]

        set refreshbtn [ttk::button .f.bar.refreshbtn            \
                           -text    "Refresh"                    \
                           -command [mytypemethod GetChanges]]

        set commitbtn [ttk::button .f.bar.commitbtn              \
                           -text    "Commit"                     \
                           -command [mytypemethod CommitChanges]]

        pack .f.bar.buglabel   -side left  -padx 2
        pack .f.bar.bugnum     -side left  -padx 2
        pack .f.bar.commitbtn  -side right -padx 2
        pack .f.bar.refreshbtn -side right -padx 2


        # Row 1: Separator
        ttk::separator .f.sep1 -orient horizontal

        # Row 2: Changes bar 
        ttk::frame .f.chgbar

        ttk::label .f.chgbar.changes \
            -text "Changes:"

        pack .f.chgbar.changes -side left  -padx 2

        # Row 3: changelist
        set height [llength $changes]

        if {$height > 16} {
            set height 16
        } elseif {$height < 4} {
            set height 4
        }

        ScrolledWindow .f.changes \
            -relief      flat      \
            -borderwidth 1         \
            -auto        both
            
        set changelist [listbox .f.changes.list                      \
                            -font               {Courier 10}         \
                            -foreground         black                \
                            -background         white                \
                            -borderwidth        1                    \
                            -activestyle        none                 \
                            -selectmode         extended             \
                            -width              80                   \
                            -height             $height              \
                            -listvariable       [mytypevar changes]  \
                            -highlightthickness 0]

        $changelist see 0
        bind $changelist <1> [list focus %W]

        .f.changes setwidget $changelist

        # Row 4: Separator
        ttk::separator .f.sep4 -orient horizontal

        # Row 5: Comment bar 
        ttk::frame .f.cmtbar

        ttk::label .f.cmtbar.label \
            -text "Log Entry:"

        pack .f.cmtbar.label -side left  -padx 2

        # Row 6: Comment box
        ScrolledWindow .f.comments \
            -relief      flat      \
            -borderwidth 1         \
            -auto        both
            
        set commentbox [text .f.comments.text                \
                            -width              80           \
                            -height             16           \
                            -background         white        \
                            -foreground         black        \
                            -highlightthickness 0            \
                            -borderwidth        1            \
                            -relief             sunken       \
                            -font               {Courier 10} \
                            -wrap               none]

        .f.comments setwidget .f.comments.text

        # Grid the components into the frame
        grid .f.bar        -row 0 -column 0 -padx 2 -pady 2 -sticky ew
        grid .f.sep1       -row 1 -column 0         -pady 2 -sticky ew
        grid .f.chgbar     -row 2 -column 0 -padx 2 -pady 2 -sticky ew
        grid .f.changes    -row 3 -column 0 -padx 2 -pady 2 -sticky nsew
        grid .f.sep4       -row 4 -column 0         -pady 2 -sticky ew
        grid .f.cmtbar     -row 5 -column 0 -padx 2 -pady 2 -sticky ew
        grid .f.comments   -row 6 -column 0 -padx 2 -pady 2 -sticky nsew

        grid columnconfigure .f 0 -weight 1
        grid rowconfigure    .f 3 -weight 1 -minsize 20
        grid rowconfigure    .f 6 -weight 1 -minsize 20

        pack .f -fill both -expand yes
    }

    # GetChanges
    #
    # Calls "svn status" to get the current changes

    typemethod GetChanges {} {
        if {[catch {
            exec svn status
        } result]} {
            puts $result
            exit 1
        }

        if {$result eq ""} {
            puts "Nothing to commit."
            exit
        }

        set changes [split $result "\n"]
    }

    # CommitChanges
    #
    # Commits the selected changes to the repository.

    typemethod CommitChanges {} {
        # FIRST, have we a bug number?
        if {![string is integer -strict $bug]} {
            tk_messageBox               \
                -type    ok             \
                -icon    error          \
                -parent  .              \
                -title   "Commit Error" \
                -message "Invalid or missing bug number."

            return
        }

        # NEXT, see what we have to commit.  There are two cases:
        # where no explicit selection has been made, and where it 
        # has.

        set cmd [list svn commit -F svn-commit.tmp]

        if {[llength [$changelist curselection]] == 0} {
            # No explicit selection.  See whether we have any 
            # items to commit
            set count 0
            
            foreach change $changes {
                set code [string index $change 0]
                
                if {$code ne "?"} {
                    incr count
                }
            }

            if {$count == 0} {
                tk_messageBox                       \
                    -type    ok                     \
                    -icon    error                  \
                    -parent  .                      \
                    -title   "Commit Error"         \
                    -message "No changes to commit"

                return
            }
        } else {
            # Explicit selection.  Check for invalid
            # files, and build up the command.

            foreach idx [$changelist curselection] {
                set change [lindex $changes $idx]
                
                set code [string index $change 0]
                set file [string range $change 7 end]
                
                if {$code eq "?"} {
                    set msg    "Selected file has not been\n"
                    append msg "added to the repository:\n\n"
                    append msg $file
                    
                    tk_messageBox               \
                        -type    ok             \
                        -icon    error          \
                        -parent  .              \
                        -title   "Commit Error" \
                        -message $msg
                    
                    return
                }
                
                lappend cmd $file
            }
        }

        # NEXT, get the comment for the log
        set comment "Fixed Bug #{$bug}"

        set text [string trim [$commentbox get 1.0 end]]

        if {$text ne ""} {
            append comment "\n\n"
            append comment $text
        }

        # NEXT, output what we're going to do
        puts $cmd
        puts "----------------------------------------------------------------"
        puts $comment
        puts "----------------------------------------------------------------"
        
        # NEXT, write the comment to svn-commit.tmp
        set f [open "svn-commit.tmp" w]
        puts $f $comment
        close $f

        # NEXT, try to commit
        set code [catch {
            eval exec $cmd
        } result]

        puts $result

        catch {file delete svn-commit.tmp}

        if {$code} {
            set msg    "Cannot commit:\n\n"
            append msg $result
                    
            tk_messageBox               \
                -type    ok             \
                -icon    error          \
                -parent  .              \
                -title   "Commit Error" \
                -message $msg
        } else {
            tk_messageBox               \
                -type    ok             \
                -icon    info           \
                -parent  .              \
                -title   "Committed"    \
                -message "Bug $bug was committed successfully."

            $commitbtn configure -state disabled
        }
    }
}






