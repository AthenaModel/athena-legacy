#-----------------------------------------------------------------------
# TITLE:
#    reportviewer.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    marsgui(n) package: Report Viewer widget.
#
#    This is a scrolled text widget outfitted to display reports from
#    a database.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::marsgui:: {
    namespace export reportviewer
}

#-----------------------------------------------------------------------
# Widget Definition

snit::widget ::marsgui::reportviewer {
    hulltype ttk::frame
    
    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    # -db
    #
    # The name of the sqlite3 database command.

    option -db -configuremethod CfgDb

    method CfgDb {opt val} {
        # Clear the widget if it's displaying something already
        set oldval $options($opt)
        set options($opt) $val

        if {$oldval ne ""} {
            $self clear
        }
    }
    
    # Option: -logcmd
    #
    # A command that takes one additional argument, a status message
    # to be displayed to the user.
    
    option -logcmd \
        -default ""

    #-------------------------------------------------------------------
    # Components

    component reptext            ;# Text widget
    component hotbtn             ;# "Hot List" checkbutton

    #-------------------------------------------------------------------
    # Instance Variables

    variable currentReport -1     ;# ID of currently displayed report
    variable hot           0      ;# Whether the report is on the hot list
                                   # or not.

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, save the options
        $self configurelist $args

        # NEXT, create the info bar across the top.
        set bar [ttk::frame $win.bar]
        
        ttk::label $bar.label \
            -text "Report Text"

        install hotbtn using ttk::checkbutton $bar.hotbtn \
            -text     "Hot List"                          \
            -variable [myvar hot]                         \
            -state    disabled                            \
            -command  [mymethod Toggle]

        pack $bar.label  -side left
        pack $bar.hotbtn -side right

        # NEXT, create the rotext widget
        install reptext using ::marsgui::rotext $win.text \
            -yscrollcommand [list $win.yscroll set] \
            -xscrollcommand [list $win.xscroll set]
        
        isearch enable $reptext
        isearch logger $reptext [mymethod Log]

        # NEXT, create the scrollbasrs.
        ttk::scrollbar $win.yscroll \
            -orient  vertical       \
            -command [list $reptext yview]

        ttk::scrollbar $win.xscroll \
            -orient  horizontal     \
            -command [list $reptext xview]

        # NEXT, layout the widgets
        grid columnconfigure $win 0 -weight 1
        grid rowconfigure    $win 1 -weight 1

        grid $bar -sticky ew -columnspan 2
        grid $reptext $win.yscroll -sticky nsew
        grid $win.xscroll          -sticky ew

        # NEXT, define some color tags
        $reptext tag configure header                  \
            -background \#BBDDFF                       \
            -font       {Helvetica 12 bold}            \
            -tabs       {0.6i left 2.25i left 3.2i left} \
            -spacing1   2

        # NEXT, raise the "sel" tag so that selections appear properly.
        $reptext tag raise sel
    }

    # Toggle
    #
    # Toggles the mark on the current report.
    
    method Toggle {} {
        reporter hotlist set $currentReport $hot
    }
    
    # Method: Log
    #
    # Logs a status message by calling the <-logcmd>.
    #
    # Syntax:
    #   Log _msg_
    #
    #   msg     A short text message
    
    method Log {msg} {
        callwith $options(-logcmd) $msg
    }


    #-------------------------------------------------------------------
    # Public methods

    # display id
    #
    # id      A report ID
    #
    # Display the report with the specified ID

    method display {id} {
        $options(-db) eval {
            SELECT id,stamp,rtype,subtype,title,text,hotlist FROM reports 
            WHERE id = $id
        } row {
            $reptext del 1.0 end

            set tags header

            $reptext ins end "Time:\t$row(stamp)\t"            $tags
            $reptext ins end "ID:  $row(id)    "               $tags

            if {$row(rtype) ne ""} {
                $reptext ins end "Type:  $row(rtype)"          $tags

                if {$row(subtype) ne ""} {
                    $reptext ins end "/$row(subtype)"          $tags
                }

                $reptext ins end "\n"                          $tags
            }


            $reptext ins end "Title:\t$row(title)\n"  $tags

            $reptext ins end "\n"
            $reptext ins end $row(text)
            $reptext see 1.0
            $reptext yview moveto 0.0

            set hot $row(hotlist)
            $hotbtn configure -state normal
        }

        set currentReport $id
    }


    # clear
    #
    # Deletes the current report text from the widget, and
    # sets currentReport to -1.

    method clear {} {
        $reptext del 1.0 end

        set currentReport -1
        set hot 0
        $hotbtn configure -state disabled
    }


    # selectAll
    #
    # Selects the entire content of the widget; moves the focus to the
    # widget.
    
    method selectAll {} {
        $reptext tag add sel 1.0 end
    }
}



