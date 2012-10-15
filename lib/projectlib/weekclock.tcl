#-----------------------------------------------------------------------
# TITLE:
#	weekclock.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#   week(n)-based simclock(i) object.
#
# This package defines a simlock(i) object based on julian weeks.  It
# has only the features required by Athena, as compared to simclock(n)
# which implements a GEEP-like game ratio mechanism and is ultimately
# based on seconds.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Exported commands

namespace eval ::projectlib:: {
    namespace export weekclock
}


#-----------------------------------------------------------------------
# week Ensemble

snit::type ::projectlib::weekclock {
    #-------------------------------------------------------------------
    # Options

    # -t0
    #
    # A Zulu-time string representing the simulation start date.
    
    option -t0 -default "2012W01" -configuremethod CfgT0

    method CfgT0 {opt val} {
        # First, set t0 in absolute weeks.
        set info(t0) [week toInteger $val]

        # Next, it's valid, so save it.
        set options($opt) $val
    }

    #-------------------------------------------------------------------
    # Instance variables
    
    # info array
    #
    # t0   - Integer value for -t0 start date.  Initially, 2012W01.
    # tsim - The simulation time in ticks since T0

    variable info -array {
        t0   0
        tsim 0
    }

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # Save default -t0
        $self configure -t0 $options(-t0)

        # Save user's input
        $self configurelist $args
    }

    #-------------------------------------------------------------------
    # Public methods

    # advance t
    #
    # t    - A time in ticks no less than $info(tsim).
    #
    # Advances sim time to time t. 
    
    method advance {t} {
        require {[string is integer -strict $t]} \
            "expected integer ticks: \"$t\""
        require {$t >= 0} \
            "expected t >= 0, got \"$t\""

        set info(tsim) $t
        return
    }

    # reset
    #
    # Resets sim time to 0.

    method reset {} {
        set info(tsim) 0
        return
    }

    #-------------------------------------------------------------------
    # Queries

    # now ?offset?
    #
    # offset  - Ticks; defaults to 0.
    #
    # Returns the current sim time (plus the offset) in ticks.

    method now {{offset 0}} {
        return [expr {$info(tsim) + $offset}]
    }

    # asString ?offset?
    #
    # offset  - Ticks; defaults to 0.
    #
    # Return the current time (plus the offset) as a time string.

    method asString {{offset 0}} {
        $self toString $info(tsim) $offset
    }

    #-------------------------------------------------------------------
    # Conversions

    # toString ticks ?offset?
    #
    # ticks      - A sim time in ticks.
    # offset     - Interval in ticks; defaults to 0.
    #
    # Converts the sim time plus offset to a time string.

    method toString {ticks {offset 0}} {
        return [week toString [expr {$info(t0) + $ticks + $offset}]]
    }

    # fromString wstring
    #
    # wstring    - A week string
    #
    # Converts the week string into a sim time in weeks.

    method fromString {wstring} {
        return [expr {[week toInteger $wstring] - $info(t0)}]
    }

    # timespec validate spec
    #
    # spec         - A time-spec string
    #
    # Converts a time-spec string to a sim time in ticks.
    #
    # A time-spec string specifies a time in ticks as a base time 
    # optionally plus or minus an offset.  The offset is always in ticks;
    # the base time can be a time in ticks, a week time-string, or
    # a "named" time, e.g., "T0" or "NOW".  If the base time is omitted, 
    # "NOW" is assumed.  For example,
    #
    #    +5             simclock now 5
    #    -5             simclock now -5
    #    <week>+30      Week string time plus 30 ticks
    #    NOW-30         simclock now -30
    #    40             40
    #    40+5           45
    #    T0+45          45
    #    T0             0

    method {timespec validate} {spec} {
        # FIRST, split the spec into base time, op, and offset.
        set result [regexp -expanded {
            # FIRST, Start from beginning of string
            ^

            # NEXT, capture the base time, which (at this point)
            # can be any string that doesn't contain +, -, or whitespace.
            # It can, however, be empty.
            ([^-+[:space:]]*)

            # NEXT, skip any amount of white space
            \s*

            # NEXT, capture the offset, if any
            (

            # NEXT, it begins with a + or -, which we need to capture
            ([-+])

            # NEXT, skip any amount of white space
            \s*
 
            # NEXT, the actual offset is an arbitrary integer at least
            # one character long
            (\d+)

            # NEXT, we need 0 or 1 offsets, including the operator and
            # the number.
            )?

            # NEXT, continue to the end of the string.
            $
        } $spec dummy basetime dummy2 op offset]

        if {!$result} {
            throw INVALID \
                "invalid time spec \"$spec\", should be <basetime><+/-><offset>"
        }

        # NEXT, convert the base time to ticks
        set basetime [string toupper $basetime]

        if {$basetime eq "T0"} {
            set t 0
        } elseif {$basetime eq "NOW" || $basetime eq ""} {
            set t [$self now]
        } elseif {[string is integer -strict $basetime]} {
            set t $basetime
        } elseif {![catch {$self fromString $basetime} result]} {
            set t $result
        } else {
            throw INVALID \
                "invalid time spec \"$spec\", base time should be \"NOW\", \"T0\", an integer tick, or a week string"
        }

        if {$offset ne ""} {
            incr t $op$offset
        }

        return $t
    }
}

