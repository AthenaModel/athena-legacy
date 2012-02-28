# TITLE:
#    timeline.tcl
#
# AUTHOR:
#    Dave Hanks
#
# DESCRIPTION:
#     marsgui(n) package: timeline canvas widgetadpator.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::marsgui:: {
    namespace export timeline
}

#----------------------------------------------------------------------
# timeline

snit::widgetadaptor ::marsgui::timeline {

    #------------------------------------------------------------------
    # Delegation
    delegate option * to hull

    #------------------------------------------------------------------
    # Options

    # -simclock clock
    #
    # Used for time conversions

    option -simclock
    
    # -activecolor color
    #
    # Color to show when the item is clicked
    option -selectedcolor -default black

    # -vscrollbar bar
    #
    # The scrollbar to be used. If not set then no scrollbar is displayed
    option -vscrollbar -default ""

    # -leftmargin pixels
    #
    # The width of the left margin area in pixels where the labels are 
    # displayed
    option -leftmargin -type {snit::integer -min 60} \
                       -default 100                  \
                       -configuremethod CnfLMargin

    method CnfLMargin {opt val} {
        set options(-leftmargin) $val
        ::Plotchart::plotconfig timechart margin left $val
        $self Display
    }

    #------------------------------------------------------------------
    # Variables
    #

    variable vline     "" ;# The ID of the vline
    variable vlinelbl  "" ;# The ID of the vline label
    variable selectid  "" ;# The ID of the bar in the chart that is selected
    variable tmin 9999999 ;# The minimum time of an entry in the chart
    variable tmax       0 ;# The maximum time of an entry in the chart

    component clock       ;# The simclock(n) object
    component chart       ;# The plotchart object

    # Array of bar data
    #
    # ids          Driver IDs
    # name-$id     Label to display
    # start-$id    Start time of bar
    # end-$id      End time of bar
    # color-$id    Color to show when not active

    variable bars -array {
        ids   ""
    }

    # Converts between month string and month number. This is used for
    # computing times on the time chart
    variable months -array {
        JAN 01
        FEB 02
        MAR 03
        APR 04
        MAY 05
        JUN 06
        JUL 07
        AUG 08
        SEP 09
        OCT 10
        NOV 11
        DEC 12
    }

    #------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, create the hull
        installhull using canvas    \
            -background white       \
            -highlightthickness 0   \
            -borderwidth        0   \
            -width              620 \
            -height             210

        $self configurelist $args

        # NEXT the simclock
        set clock $options(-simclock)

        # NEXT, default left margin is 100 pixels
        ::Plotchart::plotconfig timechart margin left $options(-leftmargin)

        # NEXT, define mouse behavior
        bind $self <Button-1>  [mymethod ChartClicked %x %y]

        # NEXT, when the window is resized.
        # TBD: this may not be good when there are a lot of things to 
        # display, in which case use the ConfigureEvent method.
        bind $win <Configure> [mymethod Display]
    }

    delegate method * to hull

    #------------------------------------------------------------------
    # Event Handlers
    #
    
    # ChartClicked xpos ypos
    #
    # xpos    The x-position of the click
    # ypos    The y-position of the click
    #
    # This method responds to mouse clicks in the plot area of the
    # time chart. If a bar is clicked then that bar is set to 
    # active and the plot is redrawn. If a -selectedcolor option has
    # been provided, the bar changes to that color. Finally, a 
    # <<BarClicked>> virtual event is generated with the x and y
    # position of the click along with the id of the bar that was
    # clicked.

    method ChartClicked {xpos ypos} {
        # FIRST, if the click is on the vline, no-op
        set current [$self gettags current]
        if {$current ne "" && [lindex $current 0] eq "vline"} {
            return
        }

        # NEXT, figure out which entry was clicked, there has to at 
        # least be a label, so we look for that
        set tag [$self find closest 50 $ypos]

        if {[$self type $tag] eq "text"} {
            # NEXT, if it is a text entry, then we've got an entry, get
            # the id of the new one
            set text [$self itemcget $tag -text]
            set newid [string range $text 0 [string first " " $text]]

            # NEXT, set the old one (it might be the empty string)
            set oldid $selectid

            # NEXT, clear out the selected id
            set selectid ""

            # NEXT, if the current one is different from the new one active
            # the new one
            if {$oldid ne $newid} {
                set selectid $newid
            }
            # NEXT, redraw the graph
            # TBD: could probably make this change only the item that
            # needs to change
            $self Display

            # NEXT, generate virtual event
            event generate $win <<BarClicked>> \
                -x    $xpos                    \
                -y    $ypos                    \
                -data $selectid
        }
    }

    # ConfigureEvent
    #
    # This method causes the graph to be redisplayed after the window is
    # resized. Right now, the display method is called directly from the
    # <Configure> event callback. This may prove to not work well when there
    # are a lot of items in the canvas, thus I am leaving this in even though
    # it is not used at the moment.

    method ConfigureEvent {} {
        if {[info exists resizing]} {
            after cancel $resizing
        }

        set resizing [after 400 [mymethod display]]
    }

    # CreateMark xpos
    #
    # xpos     desired X position of the vline
    #
    # This method creates a new vertical line along with its label
    # at the specified X position, but subject to the boundaries of
    # the underlying time chart

    method CreateMark {xpos} {
        # FIRST, if there's no information, nothing to show
        if {$bars(ids) eq ""} {return}

        # NEXT, limit the X coordinate of the vertical line
        set xmin [Plotchart::plotconfig timechart margin left]
        let wd   [winfo width $self]
        let xmax {$wd - [Plotchart::plotconfig timechart margin right]}

        if {$xpos < $xmin} {set xpos $xmin}
        if {$xpos > $xmax} {set xpos $xmax}

        # NEXT, pad the min y-coordinate by 15 pixels to make it look nice
        let ymin {15+[Plotchart::plotconfig timechart margin top]}
        set ht   [winfo height $self]
        let ymax {$ht - [Plotchart::plotconfig timechart margin bottom]}

        # NEXT, create the vline on the timeline
        set vline [$self create line $xpos $ymin $xpos $ymax \
                       -tags {vline line} -width 2]

        # NEXT, define bindings for vline behavior
        $self bind $vline <Enter> \
            [list $self configure -cursor sb_h_double_arrow]
        $self bind $vline <Leave> [list $self configure -cursor ""]
        $self bind $vline <B1-Motion> [list $self MoveVline %x]

        let ypos {$ht - [Plotchart::plotconfig timechart margin bottom]/2}
        set vlinelbl [$self create text $xpos $ypos -tags {vline lbl}]

        # NEXT, configure label
        let seconds {int([lindex [Plotchart::pixelToCoords $self $xpos 0] 0])}
        set zulu [string toupper [clock format $seconds -format {%d%H%MZ%b%y}]]
        $self itemconfigure $vlinelbl -text $zulu

        # NEXT, generate event
        event generate $win <<VLine>> -x $xpos 
    }

    # MoveVline xpos
    #
    # xpos    X-coordinate of the new location for the vline
    #
    # This method computes the new location of the vline in the 
    # canvas and sets the position subject to the bounds 
    # of the Plotchart margins

    method MoveVline {xpos} {
        # FIRST, if history is not present quick exit
        if {$bars(ids) eq ""} {return}

        # NEXT, bound the xposition by the margins of the charts
        set xmin [Plotchart::plotconfig timechart margin left]
        let wd   [winfo width $self]
        let xmax {$wd - [Plotchart::plotconfig timechart margin right]}
        if {$xpos < $xmin} {set xpos $xmin}
        if {$xpos > $xmax} {set xpos $xmax}

        # NEXT, move the vline to the new location
        set xnow [lindex [$self coords $vline] 0]
        let dx {double($xpos) - double($xnow)}
        $self move vline $dx 0

        # NEXT, configure label
        set seconds [lindex [Plotchart::pixelToCoords $self $xpos 0] 0]
        let seconds {int($seconds)}
        set zulu [string toupper [clock format $seconds -format {%d%H%MZ%b%y}]]
        $self itemconfigure $vlinelbl -text $zulu

        event generate $win <<VLine>> -x $xpos 
    }

    #------------------------------------------------------------------
    # Public methods

    # clear
    #
    # Removes everything from the canvas and resets all variables to
    # the default

    method clear {} {
        $self delete all
        set vline ""
        array unset bars
        set tmin 9999999
        set tmax 0
    }

    # method numbars
    #
    # Returns the number of bars that are currently displayed

    method numbars {} {
        return [llength $bars(ids)]
    }

    # bar add id range ?option val...?
    #
    # id     The bar id of the bar to be displayed
    # range  A two element list of times (start/end) in ticks
    #
    # Options:
    #    -name    The name of the bar to appear at the left
    #    -color   The color of the bar (default black)

    method {bar add} {id range args} {
        assert {[llength $range] == 2}

        array set opts {
            -name ""
            -color black
        }

        foreach {opt val} $args {
            switch -exact -- $opt {
                -name {
                    set opts(-name) $val
                }

                 -color {
                     set opts(-color) $val
                }

                default {
                     error \
       "Unknown option name, \"$opt\", should be one of: [array names opts]"
                }
            }
        }

        set start [lindex $range 0]
        set end   [lindex $range 1]

        snit::integer validate $start
        snit::integer validate $end 

        if {$opts(-name) eq ""} {
            set $opts(-name) "$id"
        }

        lappend bars(ids)   $id
        set bars(name-$id)  $opts(-name)
        set bars(start-$id) $start
        set bars(end-$id)   $end
        set bars(color-$id) $opts(-color)

        if {$start < $tmin} {set tmin $start}
        if {$end   > $tmax} {set tmax $end}

        $self Display
    }

    # bar delete id
    #
    # id   The id of a bar 
    #
    # This method deletes the bar in the graph associated with the bar id
    # provided. The display is updated
    #
    # TBD: see if the end points in time have changed?

    method {bar delete} {id} {
        # FIRST, special choices
        if {$id eq "last"} {
            set id [lindex $bars(ids) end]
        } elseif {$id eq "first"} {
            set id [lindex $bars(ids) 0]
        }

        # NEXT, if the bar doesn't exist, no-op
        if {[lsearch -all -exact $bars(ids) $id] eq ""} {
            return
        }

        # NEXT, remove the id from the list
        set bars(ids) [lsearch -all -inline -not -exact $bars(ids) $id]

        # NEXT the bar data and redisplay
        unset bars(name-$id)
        unset bars(start-$id)
        unset bars(end-$id)
        unset bars(color-$id)

        $self Display
    }

    # bar select id
    # 
    # id   The id of a bar
    #
    # Show the bar identified with the supplied id as selected

    method {bar select} {id} {
        # FIRST, unrecognized id, no-op
        if {$id ne "" && [lsearch -all -exact $bars(ids) $id] eq ""} {
            return
        }

        set selectid $id

        $self Display
    }

    # bar configure id args
    #
    # id    The id of a bar
    # args  Options to configure
    #
    # Options:
    #    -name    The name of the bar to appear at the left
    #    -color   The color of the bar (default black)

    method {bar configure} {id args} {
        # NEXT, if the bar doesn't exist, no-op
        if {[lsearch -all -exact $bars(ids) $id] eq ""} {
            return
        }

        foreach {opt val} $args {
            switch -exact -- $opt {
                -name {
                    set bars(name-$id) $val
                }

                 -color {
                     set bars(color-$id) $val
                }

                default {
                     error \
       "Unknown option name, \"$opt\", should be one of: [array names opts]"
                }
            }
        }

        $self Display
    }

    # Display
    #
    # Show the bars on a time chart.

    method Display {} {
        # FIRXT, if no bars, nothing to do
        if {$bars(ids) eq ""} {
            return
        }

        # NEXT, save the vline xpos, we'll build from scratch
        if {$vline ne ""} {
            set xpos [lindex [$self coords $vline] 0]
        } 

        # NEXT, get rid of everything we are going to build from scratch
        # every time.
        $self delete all

        # NEXT, handle the special case where there is only one tock's worth
        # of data.
        if {$tmin == $tmax} {
            let tmax {$tmin+1}
        }

        # NEXT, determine the limits and increments for the axes
        let dt {$tmax - $tmin}

        # NEXT, determine the time increment to display.
        let tincr {int(ceil($dt/100.0)*10)}
        
        # NEXT, prepare the time chart that displays the bars
        # and their durations
        set isostart [$self ZuluToISO [$clock toZulu $tmin]]
        set isoend   [$self ZuluToISO [$clock toZulu $tmax]]

        # NEXT, create the time chart and configure it to have a maximum
        # number of 100 bars, this number combined with
        # the height above determine the width of the bars
        set n [expr {([winfo height $self]-60)/15}]

        set chart [::Plotchart::createTimechart $self \
             $isostart $isoend $n]

        # NEXT, draw each bar
        foreach barid $bars(ids) {
            let start {int([max $tmin $bars(start-$barid)])}
            let end   {int([min $tmax $bars(end-$barid)])}

            set isostart [$self ZuluToISO [$clock toZulu $start]]
            set isoend   [$self ZuluToISO [$clock toZulu $end]]

            # NEXT, determine the color, the active  bar is 
            # shown in a different color
            if {$selectid == $barid} {
                set color $options(-selectedcolor)
            } else {
                set color $bars(color-$barid)
            }

            # NEXT, place it on the time chart 
            $chart period $bars(name-$barid) $isostart $isoend $color
        }

        # NEXT, draw the vertical lines
        let t {int($tmin)}
        while {$t < $tmax} {
            set ztime [$clock toZulu $t]
            set isotime [$self ZuluToISO $ztime]
            set ztime [string range $ztime 0 6]
            $chart vertline $ztime $isotime
            let t {$t + $tincr}
        }

        # NEXT, set the scrollbar into the timechart
        if {$options(-vscrollbar) ne ""} {
            $chart vscroll $options(-vscrollbar)
        }

        # NEXT, put the vline back 
        if {$vline ne ""} {
            set vline ""
            $self CreateMark $xpos
        } else {
            $self CreateMark 0
            set xpos 0
        }
    }

    #------------------------------------------------------------------
    # Helper procs
    #

    # ZuluToISO  z
    #
    # z    a zulu time string
    #
    # This method converts a zulu time string and returns an ISO 8601 time
    # string that the time chart handles for plotting bars

    method ZuluToISO {z} {
        if {$z eq ""} {
            return ""
        }

        set dd [string range $z 0 1]
        set hh [string range $z 2 3]
        set mm [string range $z 4 5]
        set yy [string range $z 10 11]
        set mo $months([string range $z 7 9])

        append iso $yy$mo$dd T $hh$mm 00

        return $iso
    }
}
