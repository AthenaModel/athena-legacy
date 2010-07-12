#-----------------------------------------------------------------------
# FILE: calpattern.tcl
#
#   Calendar Scheduling Pattern Validation Type
#
# PACKAGE:
#   projectlib(n) -- Athena project infrastructure package
#
# PROJECT:
#   Athena S&RO Simulation
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

namespace eval ::projectlib:: {
    namespace export calpattern ecalpattern edayname 
}

#-----------------------------------------------------------------------
# Module: calpattern
#
# This module is a validation type for calendar scheduling patterns.  It
# validates pattern values; it also computes whether a given pattern is
# satisfied on a given day.
#
# Note that calpattern presumes that the simclock in use is called
# "::simclock".

snit::type ::projectlib::calpattern {
    # Make it a singleton
    pragma -hasinstances no

    
    #-------------------------------------------------------------------
    # Public Methods

    # Type Method: isactive
    #
    # Checks whether a calendar item is scheduled to occur today,
    # given the pattern.
    #
    # Syntax:
    #   scheduled _pattern start tick_
    #
    #   pattern - The cal pattern, as validated by <validate>
    #   start   - The start of the interval, in ticks, during which
    #             the item is scheduled
    #   tick    - The day, in ticks.
    #
    # Note:
    #   This method assumes that 1 simclock tick <= 1 day.

    typemethod isactive {pattern start tick} {
        # FIRST, check start
        if {$start > $tick} {
            return 0
        }

        # NEXT, check pattern.
        switch -exact -- [lindex $pattern 0] {
            daily -
            once  {
                return 1
            }

            byweekday {
                # FIRST, get the day of week.
                set day [$type dayofweek $tick]

                if {$day in [lrange $pattern 1 end]} {
                    return 1
                } else {
                    return 0
                }
            }

            default {
                error "Unexpected pattern: \"$pattern\""
            }
        }
    }

    # Type Method: dayofweek
    #
    # Returns the day of the week as an edayname value.
    #
    # Syntax:
    #   dayofweek _tick_
    #
    #   tick - The tick to compute the day of the week for.

    typemethod dayofweek {tick} {
        # TBD: simclock should provide a conversion to clock seconds.
        set cs [zulu tosec [simclock toZulu $tick]]
        set dayIndex [clock format $cs -format %w -timezone :UTC]
        set day [lindex [edayname names] $dayIndex]
    }
    
    # Type Method: validate
    #
    # Validates a pattern, canonicalizing the pattern name and arguments.
    #
    # Syntax:
    #   validate _value_
    #
    #   value - Possibly, a valid calendar scheduling pattern.

    typemethod validate {value} {
        # FIRST, separate the value into pattern name and args.
        set name [lindex $value 0]
        set pargs [lrange $value 1 end]
        set pattern [list]

        # NEXT, validate the pattern name
        lappend pattern [ecalpattern validate $name]

        # NEXT, validate the args.
        switch -exact -- $pattern {
            daily -
            once  {
                if {[llength $pargs] > 0} {
                    return -code error -errorcode INVALID \
                        "Pattern \"$pattern\" takes no arguments"
                }
            }

            byweekday {
                if {[llength $pargs] == 0} {
                    return -code error -errorcode INVALID \
                        "No day names given for \"byweekday\" pattern"
                    
                }
                foreach day $pargs {
                    lappend pattern [edayname validate $day]
                }
            }

            default {
                error "Unexpected pattern name: \"$pattern\""
            }
        }

        # NEXT, return the canonicalized value.
        return $pattern
    }

    # Type Method: narrative
    #
    # Returns narrative text for the pattern.
    #
    # Syntax:
    #   narrative _pattern start finish__
    #
    #   pattern - A calpattern
    #   start   - The start tick
    #   finish  - The end tick, or "" for no end.
    
    typemethod narrative {pattern start finish} {
        # FIRST, separate the value into pattern name and args.
        set name [lindex $pattern 0]
        set pargs [lrange $pattern 1 end]

        # NEXT, validate the args.
        switch -exact -- $name {
            daily {
                if {$start eq $finish} {
                    if {$start == [simclock now]} {
                        set text "Today"
                    } else {
                        set text "On [simclock toZulu $start]"
                    }
                } else {
                    set text "Daily from "

                    if {$start == [simclock now]} {
                        append text "now"
                    } else {
                        append text [simclock toZulu $start]
                    }
                    
                    if {$finish eq ""} {
                        append text " on"
                    } else {
                        append text " until [simclock toZulu $finish]"
                    }
                }
            }

            once  {
                set text "Once "

                if {$start == [simclock now]} {
                    append text "today"
                } else {
                    append text "on "
                    append text [simclock toZulu $start]
                }

                if {$finish ne ""} {
                    if {$finish != $start} {
                        append text " returning [simclock toZulu $finish]"
                    }
                } else {
                    append text " with no return"
                }

                append text " (no restaffing)"
            }

            byweekday {
                set text "Every [join $pargs {, }] from "

                if {$start == [simclock now]} {
                    append text "now"
                } else {
                    append text [simclock toZulu $start]
                }
                    
                if {$finish eq ""} {
                    append text " on"
                } else {
                    append text " until [simclock toZulu $finish]"
                }
            }

            default {
                error "Unexpected pattern name: \"$name\""
            }
        }

        return $text
    }
}

#-----------------------------------------------------------------------
# Type: ecalpattern
#
# Enumeration of calendar scheduling pattern names.

::marsutil::enum ::projectlib::ecalpattern {
    daily     "Daily"
    byweekday "By Week Day"
    once      "Once"
}

#-----------------------------------------------------------------------
# Type: edayname
#
# Names of weekdays as used by calpattern.
# Note that the index matches clock(n)'s %w pattern.

::marsutil::enum ::projectlib::edayname {
    Su Sunday
    M  Monday
    T  Tuesday
    W  Wednesday
    Th Thursday
    F  Friday
    Sa Saturday
}


