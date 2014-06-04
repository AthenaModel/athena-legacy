#-----------------------------------------------------------------------
# TITLE:
#    simevent.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_ingest(1): Ingested Simulation Event
#
#    A simevent is a bean that represents a simulation event, to be 
#    ingested into Athena as one or more tactics.
#
#    This module defines a base class for event types.
#
#-----------------------------------------------------------------------

# FIRST, create the class.
beanclass create simevent

# NEXT, define class methods
oo::objdefine simevent {
    # List of defined event types
    variable types

    # define typename title script
    #
    # typename - The event type name
    # title    - A event title
    # meaning  - HTML text explaining what the event represents.
    # effects  - HTML text explaining how the event will appear in Athena.
    # script   - The event's oo::define script
    #
    # Defines a new event type.

    method define {typename title meaning effects script} {
        # FIRST, create the new type
        set fullname ::simevent::$typename
        lappend types $fullname

        beanclass create $fullname {
            superclass ::simevent
        }

        # NEXT, define the instance members.
        oo::define $fullname $script

        # NEXT, define type commands

        oo::objdefine $fullname [format {
            method typename {} {
                return "%s"
            }

            method title {} {
                return %s
            }

            method meaning {} {
                return %s
            }

            method effects {} {
                return %s
            }
        } $typename [list $title] [list $meaning] [list $effects]]
    }

    # types
    #
    # Returns a list of the available types.  The type is the
    # fully-qualified class name, e.g., ::simevent::FLOOD.

    method types {} {
        return $types
    }

    # typenames
    #
    # Returns a list of the names of the available types.  The
    # type name is the tail of the fully-qualified class name, e.g.,
    # "FLOOD".

    method typenames {} {
        set result [list]

        foreach type [my types] {
            lappend result [$type typename]
        }

        return $result
    }

    # type typename
    #
    # name   A typename
    #
    # Returns the actual type object given the typename.

    method type {typename} {
        return ::simevent::$typename
    }

    # typedict
    #
    # Returns a dictionary of type objects and titles.

    method typedict {} {
        set result [dict create]

        foreach type [my types] {
            dict set result $type "[$type typename]: [$type title]"
        }

        return $result
    }

    # typenamedict
    #
    # Returns a dictionary of type names and titles.

    method typenamedict {} {
        set result [dict create]

        foreach type [my types] {
            dict set result [$type typename] [$type title]
        }

        return $result
    }

    # normals
    #
    # Returns the IDs of the events whose state is "normal", i.e.,
    # not disabled.

    method normals {} {
        set result [list]

        foreach id [my ids] {
            if {[[my get $id] state] eq "normal"} {
                lappend result $id
            }
        }

        return $result

    }

    #-------------------------------------------------------------------
    # Ingestion

    # ingest
    #
    # Ingests events of all types.

    method ingest {} {
        foreach typename [my typenames] {
            my IngestEtype $typename
        }
    }

    # IngestEtype etype
    #
    # "Ingests" the messages associated with this event type, using
    # the related rdb view ingest_$typename, and turns them into
    # event instances.

    method IngestEtype {etype} {
        set lastEvent ""

        rdb eval "
            SELECT * FROM ingest_$etype
        " row {
            # FIRST, create a new event.
            set e [simevent::$etype new {*}$row(optlist)]

            # NEXT, if it can extend the previous event,
            # extend the previous event.
            if {$lastEvent ne "" && [$lastEvent canmerge $e]} {
                $lastEvent merge $e
                bean uncreate $e  ;# Reuses $e's bean ID
            } else {
                set lastEvent $e
            }
        }
    }
   
    #-------------------------------------------------------------------
    # Order Helpers

    # TBD

}


# NEXT, define instance methods
oo::define simevent {
    #-------------------------------------------------------------------
    # Instance Variables

    # Every event has a "id", due to being a bean.

    variable state      ;# The event's state: normal, disabled, invalid
    variable n          ;# The neighborhood
    variable week       ;# The start week, as a week(n) string.
    variable t          ;# The start week, as a sim week integer.
    variable duration   ;# The duration in weeks.
    variable cidlist    ;# The message ID list: messages that drove this
                         # event.

    # Event types will add their own variables.

    #-------------------------------------------------------------------
    # Constructor

    constructor {} {
        next
        set state normal
        set n        ""
        set week     ""
        set t        ""
        set duration 1
        set cidlist  [list]
    }

    #-------------------------------------------------------------------
    # Queries
    #
    # These methods will rarely if ever be overridden by subclasses.

    # subject
    #
    # Set subject for notifier events.

    method subject {} {
        return "::simevent"
    }


    # typename
    #
    # Returns the event's typename

    method typename {} {
        return [namespace tail [info object class [self]]]
    }

    # state
    #
    # Returns the event's state: normal, disabled, invalid

    method state {} {
        return $state
    }

    # endtime
    #
    # Returns the sim week in which the event will have its last
    # effect, given t and the duration.

    method endtime {} {
        expr {$t + $duration - 1}
    }

    # intent
    #
    # An "intent" string for the event's strategy block.

    method intent {} {
        return "Event [my id]: [my narrative]"
    }

    # timeopts ?duration?
    #
    # duration   - The event duration.
    #
    # Returns strategy block options for configuring the time.
    # The duration defaults to the event duration.

    method timeopts {{dur ""}} {
        if {$dur eq ""} {
            set dur $duration
        }

        if {$dur == 1} {
            return [list -tmode AT -t1 $week]
        } else {
            set t2 "$week+[expr {$dur - 1}]"
            return [list -tmode DURING -t1 $week -t2 $t2]
        }
    }

    #-------------------------------------------------------------------
    # Views

    # view ?view?
    #
    # view - The flavor of view to retrieve
    #
    # Returns a view dictionary.

    method view {{view ""}} {
        set vdict [next $view]

        dict set vdict typename  [my typename]
        dict set vdict narrative [my narrative]
        dict set vdict cidcount  [llength $cidlist]

        return $vdict
    }

    # htmltext
    #
    # Returns an HTML page describing this event, including the 
    # TIGR events associated with it.

    method htmltext {} {
        set ht [htools %AUTO%]

        try {
            $ht h1 "Event [my id]: [my typename]"
            $ht putln "At time $week: "
            $ht putln [my narrative]
            $ht para

            $ht putln [[info object class [self]] meaning]
            $ht para

            $ht h2 "Event Effects"

            $ht putln [[info object class [self]] effects]

            $ht para

            $ht h2 "Event Sources"

            $ht putln {
                The TIGR messages for which this event was 
                created are listed below.
            }

            $ht para

            $ht hr 

            $ht para

            foreach cid $cidlist {
                $ht putln [tigr detail $cid]
                $ht para
                $ht hr
                $ht para
            }

            return [$ht get]
        } finally {
            $ht destroy            
        }
    }

    #-------------------------------------------------------------------
    # Merging Events

    # canmerge evt
    #
    # evt   - Another event of the same type.
    #
    # This method determines whether this event and the given evt can
    # be merged into a single event.  In general, two events can be 
    # merged if they share the same distinguishing attributes and
    # compatible times.
    #
    # The default assumption is that two events can be merged if they
    # have the same n, and the second event's t is either the same week
    # or only one week later.
    #
    # Other possibilities are as follows:
    #
    # * This event type has additional distinguishing variables, i.e.,
    #   a group or an actor.
    #
    # * This event type can not extend over multiple weeks, and so
    #   t must be the same.

    method canmerge {evt} {
        assert {[$evt typename] eq [my typename]}

        # FIRST, to merge events the distinguishing attributes must
        # be identical.
        foreach var [my distinguishers] {
            if {[$evt cget -$var] ne [my cget -$var]} {
                return 0
            }
        }

        # NEXT, we can always merge events with the same distinguishing
        # attributes that take place at exactly the same time.
        if {[$evt cget -t] == $t} {
            return 1
        }

        # NEXT, we cannot always extend an event over into subsequent
        # weeks.  But if we can, we can merge if the new event takes
        # place during the same duration or in the week immediately
        # following.

        if {[my canextend]} {
            set tnew [$evt cget -t]

            if {$t <= $tnew && $tnew <= $t + $duration} {
                return 1
            }
        }

        # FINALLY, the time settings are inconsistent; no merge.
        return 0
    }

    # merge evt
    #
    # evt   - Another event of the same type.
    #
    # Merges evt into this event, incrementing the duration if
    # necessary.

    method merge {evt} {
        assert {[$evt typename] eq [my typename]}
        assert {[$evt cget -t] <= $t + $duration}

        lappend cidlist {*}[$evt cget -cidlist]

        if {[$evt cget -t] == $t + $duration} {
            incr duration
        }
    }


    

    #-------------------------------------------------------------------
    # Operations
    #
    # These methods represent operations whose actions may
    # vary by event type.
    #
    # Subclasses will usually need to override the SanityCheck, narrative,
    # obligate, and IngestEvent methods.  If they define additional
    # distinguishing attributes, they will need to extend 
    # "distinguishers" as well.  If they cannot have an extended duration,
    # then canextend should be override to return false.

    # canextend
    #
    # Returns 1 if the event type allows duration > 1, and 0 otherwise.

    method canextend {} {
        return 1
    }

    # distinguishers
    #
    # Returns the names of the variables that distinguish between
    # events of the same type.

    method distinguishers {} {
        return [list n]
    }

    # check
    #
    # Sanity checks the event, returning a dict of variable names
    # and error strings:
    #
    #   $var -> $errmsg 
    #
    # If the dict is empty, there are no problems.

    method check {} {
        set errdict [my SanityCheck [dict create]]

        if {[dict size $errdict] > 0} {
            my set state invalid
        } elseif {$state eq "invalid"} {
            my set state normal
        }

        return $errdict
    }

    # SanityCheck errdict
    #
    # errdict   - A dictionary of instance variable names and error
    #             messages.
    #
    # This command should check the class's variables for errors, and
    # add the error messages to the errdict, returning the errdict
    # on completion.  The usual pattern for subclasses is this:
    #
    #    ... check for errors ...
    #    return [next $errdict]
    #
    # Thus allowing parent classes their chance at it.

    method SanityCheck {errdict} {
        # No necessary checks at this level.
        return $errdict
    }

    # narrative
    #
    # Computes a narrative for this event, for use in the GUI.

    method narrative {} {
        return "no narrative defined"
    }


    # export
    #
    # Exports the event as an Athena executive script relative to the
    # scenario.

    method export {} {
        # Every event should override this.
        error "Event export is undefined"
    }
}


# EVENT:STATE
#
# Sets a event's state to normal or disabled.  The order dialog
# is not generally used.

order define EVENT:STATE {
    title "Set Event State"

    options -sendstates PREP

    form {
        label "Event ID:" -for event_id
        text event_id -context yes

        rc "State:" -for state
        text state
    }
} {
    # FIRST, prepare and validate the parameters
    prepare event_id -required          -type event
    prepare state    -required -tolower -type ebeanstate
    returnOnError    -final

    set event [event get $parms(event_id)]

    # NEXT, update the event.
    setundo [$event update_ {state} [array get parms]]
}




