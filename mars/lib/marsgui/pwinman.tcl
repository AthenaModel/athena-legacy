#-----------------------------------------------------------------------
# FILE: pwinman.tcl
#   
#   Pseudo-window Manager Widget
#
# PACKAGE:
#   marsgui(n) -- Mars GUI Infrastructure Package
#
# PROJECT:
#   Mars Simulation Infrastructure Library
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

namespace eval ::marsgui:: {
    namespace export pwinman
}

#-----------------------------------------------------------------------
# Widget: pwinman
#
# The pseudo-window manager is a widget for managing a vertical stack
# of pwin(n) pseudo-windows.  It's essentially a fancy ttk::panedwindow.
#
#-----------------------------------------------------------------------

snit::widget ::marsgui::pwinman {
    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        namespace import ::marsutil::*
    }

    #-------------------------------------------------------------------
    # Group: Components

    # Component: paner
    #
    # The ttk::panedwindow that does the work.
    
    component paner

    # Component: end
    #
    # An empty frame, used as the last pane in the panedwindow.

    component end

    #-------------------------------------------------------------------
    # Group: Options
    #
    # Delegate options to the hull

    delegate option -width  to hull
    delegate option -height to hull

    #-------------------------------------------------------------------
    # Group: Instance variables

    # Variable: pwins
    #
    # A list of the pwins in the order of display.

    variable pwins {}

    #-------------------------------------------------------------------
    # Group: Constructor

    # Constructor: constructor
    #
    # The constructor creates the hull, which is a ttk::panedwindow.

    constructor {args} {
        # FIRST, give the widget a small default size
        $hull configure \
            -width  200 \
            -height 100

        # NEXT, Create the panedwindow
        install paner using ttk::panedwindow $win.paner

        # NEXT, apply the user's options
        $self configurelist $args

        # NEXT, create the null frame.
        install end using ttk::frame $win.paner.end
        $paner add $end

        # NEXT, pack the paner
        pack $paner -fill both -expand yes

        # NEXT, the pwinman is whatever size the application 
        # wants it to be.
        pack propagate $win off
    }

    #-------------------------------------------------------------------
    # Group: Public Methods

    delegate method cget      to hull
    delegate method configure to hull
    delegate method identify  to hull

    # Method: add
    #
    # Returns the name of a new pwin(n), into which the application
    # can add content.  The pwin(n) is placed at the end of the 
    # list of panes.

    method add {} {
        return [$self insert end]
    }

    # Method: insert
    #
    # Adds a new pwin at the specified _pos_, and returns
    # its pathname.  When _pos_ is *end*, this method is 
    # equivalent to <add>.
    # 
    # Syntax:
    #   insert _pos_
    #
    #   pos - A numeric index, a pwin name, or *end*.

    method insert {pos} {
        # FIRST, The pos is either "end", or a managed window,
        # or an integer.
        if {$pos eq "end"} {
            set pos $end
        } elseif {$pos ni $pwins} {
            require {
                [string is integer -strict $pos] &&
                $pos >= 0                        &&
                $pos <= [llength $pwins]
            } "Invalid position: \"$pos\""
        }

        # NEXT, create a new pwin.
        set pwin [pwin $paner.%AUTO%]
        $pwin configure \
            -command [mymethod PwinCB $pwin]

        # NEXT, insert it into the pwins list.
        if {$pos eq $end} {
            lappend pwins $pwin
        } else {
            set ndx [lsearch -exact $pwins $pos]
            set pwins [linsert $pwins $ndx $pwin]
        }

        # NEXT, insert it into the panedwindow
        $paner insert $pos $pwin

        # NEXT, update the state of the pwin buttons
        $self UpdatePwinButtons

        return $pwin
    }

    # Method: index
    #
    # Returns the numeric index corresponding to _pos_.
    #
    # Syntax:
    #   index _pos_
    #
    #   pos - A numeric index, a pwin name, or *end*.

    method index {pos} {
        if {$pos eq "end"} {
            return [expr {[llength $pwins] - 1}]
        } elseif {$pos in $pwins} {
            return [lsearch -exact $pwins $pos]
        } else {
            $self ValidateIntegerPos $pos
            return $pos
        }
    }

    # Method: pwin
    #
    # Returns the pwin name cooresponding to _pos_
    #
    # Syntax:
    #   pwin _pos_
    #
    #   pos - A numeric index, a pwin name, or *end*.

    method pwin {pos} {
        if {$pos eq "end"} {
            return [lindex $pwins end]
        } elseif {$pos in $pwins} {
            return $pos
        } else {
            $self ValidateIntegerPos $pos

            return [lindex $pwins $pos]
        }
    }

    # Method: delete
    #
    # Destroys the pwin at the specified _pos_.
    #
    # Syntax:
    #   delete _pos_
    #
    #   pos - A numeric index, a pwin name, or *end*.

    method delete {pos} {
        set pwin [$self pwin $pos]
        ldelete pwins $pwin
        $paner forget $pwin
        destroy $pwin

        return
    }

    # Method: move
    #
    # Moves the pwin at position _start_ to position
    # _dest_.  Note that _dest_ can be *up* or *down*,
    # meaning that the pwin should be move up or down
    # one slot.
    #
    # Syntax:
    #   move _start dest_
    #
    #   start - A numeric index, a pwin name, or *end*.
    #   dest  - A numeric index, a pwin name, or *end*, 
    #           *up*, or *down*.
    
    method move {start dest} {
        # FIRST, turn the start position into a pwin name
        # and an index.
        set pwin [$self pwin $start]
        set index [$self index $start]

        # NEXT, We need two things: the name of the before which
        # pwin will be inserted in the panedwindow, and the index 
        # at which pwin should be re-inserted in the pwins list after
        # it has been deleted.
        if {$dest eq "up"} {
            set insertAt [expr {$index - 1}]
            set before [lindex $pwins $index-1]
            require {$before ne ""} \
                "Cannot move pwin at position further up: \"$start\""
        } elseif {$dest eq "down"} {
            set insertAt [expr {$index + 1}]
            set before [lindex $pwins $index+1]
            require {$before ne ""} \
                "Cannot move pwin at position further down: \"$start\""
        } elseif {$dest eq "end"} {
            set before $end
            set insertAt end
        } elseif {$dest ni $pwins} {
            $self ValidateIntegerPos $dest

            set before [lindex $pwins $dest]
            set insertAt $dest
        } else {
            set before $dest
            set insertAt [lsearch -exact $pwins $dest]
        }

        # NEXT, update the pwins list.
        ldelete pwins $pwin
        set pwins [linsert $pwins $insertAt $pwin]

        # NEXT, update the panedwindow
        $paner insert $before $pwin

        # NEXT, update the state of the pwin buttons
        $self UpdatePwinButtons
        
        return
    }

    #-------------------------------------------------------------------
    # Group: Private Methods

    # Method: PwinCB
    #
    # Handles up, down, and close from the pwins.
    #
    # Syntax:
    #   PwinCB _pwin op_
    #
    #   pwin - The specific pwin
    #   op   - *up*, *down*, or *close*

    method PwinCB {pwin op} {
        switch -exact $op {
            up   -
            down {
                $self move $pwin $op
            }

            close {
                $self delete $pwin
            }

            default {
                error "Invalid operation: \"$op\""
            }
        }
    }

    # Method: UpdatePwinButtons
    #
    # Sets the state of the up and down buttons on the pwins.

    method UpdatePwinButtons {} {
        foreach pwin $pwins {
            $pwin configure -upstate normal -downstate normal
        }

        [lindex $pwins 0]   configure -upstate   disabled
        [lindex $pwins end] configure -downstate disabled
    }

    # Method: ValidateIntegerPos
    #
    # Validates a window pos specified as an integer index.
    #
    # Syntax:
    #   ValidateIntegerPos _pos_
    #
    #   pos - A position that should be the integer index of a pwin.

    method ValidateIntegerPos {pos} {
        require {
            [string is integer -strict $pos] &&
            [lindex $pwins $pos] ne ""
        } "Invalid position: \"$pos\""
    }
}