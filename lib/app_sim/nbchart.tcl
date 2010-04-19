#-----------------------------------------------------------------------
# FILE: nbchart.tcl
#
#   Athena Neighborhood Bar Chart
#
# PACKAGE:
#   app_sim(n) -- athena_sim(1) implementation package
#
# PROJECT:
#   Athena S&RO Simulation
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

#-----------------------------------------------------------------------
# Widget: nbchart
#
# The nbchart(n) widget is an hbarchart(n) that plots data for one or
# more neighborhood variables.
#
#-----------------------------------------------------------------------

snit::widgetadaptor nbchart {
    #-------------------------------------------------------------------
    # Group: Options
    # 
    # Unknown options are delegated to the hull

    delegate option * to hull

    # Option: -title
    #
    # Title for this chart.  If "", defaults to the -varnames.

    option -title

    # Option: -varnames
    #
    # List of variable names to plot.
    
    option -varnames \
        -default         {}             \
        -configuremethod ConfigAndReset

    # Method: ConfigAndReset
    #
    # Option configuration method; saves the option value, and 
    # reconfigures the underlying hbarchart.
    #
    # Syntax:
    #   ConfigAndReset _opt val_
    #
    #   opt - The option name
    #   val - The new value
   
    method ConfigAndReset {opt val} {
        # FIRST, save the option value.
        set options($opt) $val

        # NEXT, Reset the bar chart.
        $self Reset
    }
 
    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using hbarchart \
            -ylabels [list "no data"] \
            -ytext   "Neighborhoods"
        

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, bind to receive updates.
        # TBD: Do we want a new notifier event, to indicate that
        # neighborhood data in general might have changed?
        notifier bind ::sim <Tick>      $win [mymethod update]
        notifier bind ::sim <DbSyncB>   $win [mymethod update]
        notifier bind ::demog <Entity>  $win [mymethod update]
        notifier bind ::nbhood <Entity> $win [mymethod update]
        notifier bind ::econn  <Entity> $win [mymethod update]
        notifier bind ::sat <Entity>    $win [mymethod update]
        notifier bind ::coop <Entity>   $win [mymethod update]

        $self Reset
    }

    destructor {
        notifier forget $win
    }

    #-------------------------------------------------------------------
    # Private Methods

    # Method: Reset
    #
    # Reconfigures the hbarchart given the current options.  Sets
    # the xtext, ytext, min, max, and plots the data.

    method Reset {} {
        # FIRST, get the title.
        if {$options(-title) ne ""} {
            set title $options(-title)
        } else {
            set title [join $options(-varnames) ", "]
        }

        # NEXT, initialize the ylabels
        set ylabels [list]

        # NEXT, get the view and the data.
        if {$options(-varnames) ne ""} {
            array set vdict [view n get $options(-varnames)]

            # NEXT, get the data
            foreach varname $options(-varnames) {
                set data($varname) [list]
            }

            rdb eval "SELECT * FROM $vdict(view) ORDER BY n" row {
                lappend ylabels $row(n)
                
                for {set i 0} {$i < $vdict(count)} {incr i} {
                    lappend data([lindex $options(-varnames) $i]) $row(x$i)
                }
            }
        }

        if {[llength $ylabels] == 0} {
            set ylabels [list "no data"]
        }

        # NEXT, configure the chart and plot the data
        $hull configure \
            -title   $title   \
            -ylabels $ylabels

        set unitList [list]

        set maxDecimals 0

        foreach varname $options(-varnames) {
            set vardict [dict get $vdict(meta) $varname]

            dict with vardict {
                ladd unitList $units
                
                if {$decimals > $maxDecimals} {
                    set maxDecimals $decimals
                }

                $hull plot $varname \
                    -data $data($varname) \
                    -rmin $rmin           \
                    -rmax $rmax
            }
        }

        $hull configure \
            -xtext [join $unitList ", "] \
            -xformat "%.${maxDecimals}f"
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    # Method: update
    #
    # Retrieves and plots the latest data.

    method update {} {
        $self Reset
    }

}


