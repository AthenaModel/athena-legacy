#-----------------------------------------------------------------------
# TITLE:
#    reportviewerwin.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    projectgui(n) package: Report Viewer Window widget.
#
# This is a window which displays a single report.  To create/pop-up
# one, use reportviewerwin display.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::projectgui:: {
    namespace export reportviewerwin
}

#-----------------------------------------------------------------------
# Widget Definition

snit::widget ::projectgui::reportviewerwin {
    hulltype toplevel

    #-------------------------------------------------------------------
    # Type methods

    # display db id
    #
    # db     The reports database command name
    # id     A report ID
    #
    # Display report $id in its own window
    typemethod display {db id} {
        set w .repwin_$id

        if {[winfo exists $w]} {
            $w show
        } else {
            $type $w -db $db
            $w display $id
        }
    }

    #-------------------------------------------------------------------
    # Options

    delegate option -db to viewer

    #-------------------------------------------------------------------
    # Components

    component viewer    ;# The reportviewer widget

    delegate option * to hull
    delegate method * to hull

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # Create the reportviewer
        install viewer using ::projectgui::reportviewer $win.text

        $self configurelist $args

        pack $viewer -side top -fill both -expand 1
    }

    #-------------------------------------------------------------------
    # Public Methods

    # display id
    #
    # id     The report ID
    #
    # Retrieves and displays the requested report.
    
    method display {id} {
        wm title $win "Report #$id"
        $viewer display $id
    }

    # show
    #
    # Pops up the window.
    method show {} {
        if {[wm state $win] eq "withdrawn" ||
            [wm state $win] eq "iconic"} {
            wm deiconify $win
        }
        raise $win
        focus $win
    }
}

