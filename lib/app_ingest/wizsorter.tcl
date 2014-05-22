#-----------------------------------------------------------------------
# TITLE:
#    wizsorter.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    wizsorter(n): A wizard manager page for sorting TIGR messages
#    by event type 
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# wizsorter widget


snit::widget wizsorter {
    #-------------------------------------------------------------------
    # Lookup table

    # The HTML help for this widget.
    typevariable helptext {
        <h1>Sort Messages by Event Type</h1>
        
        The next task is to examine the TIGR reports and relate them
        to specific types of Athena simulation event.<p>

        <ul>
        <li> Click on the report headers in the item list to see the details
             of the report.<p>
        <li> Click and drag each report to the appropriate event
             bin on the right.<p>
        <li> Reports for which no appropriate event type exists can
             be "ignored".<p>
        <li> Reports can be related to multiple events.  Shift-Click and
             drag to copy a report to a bin.<p>
        </ul>

        <h1>Event Types</h1>

        The event types are as follows:<p>
    }

    # Event Type Specification
    #
    # TBD: Ultimately, this will come from some other module.

    typevariable eventTypes {
        ACCIDENT   "Accident"
        CIVCAS     "Civilian Casualties"
        DEMO       "Demonstration"
        DROUGHT    "Drought"
        EXPLOSION  "Explosion"
        FLOOD      "Flood"
        RIOT       "Riot"
        TRAFFIC    "Traffic"
        VIOLENCE   "Random Violence"
    }

    
    #-------------------------------------------------------------------
    # Components

    component sorter     ;# sorter(n) widget
    
    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    #-------------------------------------------------------------------
    # Variables

    # Info array: wizard data

    variable info -array {
    }

    #-------------------------------------------------------------------
    # Constructor
    #

    constructor {args} {
        # FIRST, create the sorter.  Note: we don't turn off 
        # pack propagate because the sorter has a well-defined size.
        install sorter using sorter $win.sorter    \
            -itemlabel  "Messages"                 \
            -helptext   [$self helptext]           \
            -binspec    $eventTypes                \
            -detailcmd  [list tigr detail]         \
            -itemcmd    [list tigr view]           \
            -changecmd  [mymethod ChangeCmd]       \
            -itemlayout {
                { cid   "ID"                     }
                { week  "Week"                   }
                { n     "Nbhood"                 }
                { title "Title" -stretchable yes }
            }

        pack $sorter -fill both -expand yes
    }

    #-------------------------------------------------------------------
    # Event handlers

    # ChangeCmd value
    #
    # Tell ingester whether we've got a valid sorting or not.

    method ChangeCmd {value} {
        # Is the sorting complete?  We must have no unsorted
        # messages and at least one non-ignored message.
        set count    [llength [tigr ids]]
        set unsorted [llength [dict get $value unsorted]]
        set ignored  [llength [dict get $value ignored]]

        if {$unsorted == 0 && $count > $ignored} {
            ingester saveSorting $value
        } else {
            ingester saveSorting ""
        }
    }

    #-------------------------------------------------------------------
    # Helpers

    # helptext
    #
    # Returns the help text, with appended event type descriptions.

    method helptext {} {
        set out $helptext

        foreach etype [lsort [simevent types]] {
            append out "<b>[$etype typename]</b>: "
            append out [$etype meaning]
            append out "<p>\n\n"
        }

        return $out
    }
    

    #-------------------------------------------------------------------
    # Wizard Page Interface

    # enter
    #
    # This command is called when wizman selects this page for
    # display.  It should do any necessary set up (i.e., pull
    # data from the data model).

    method enter {} {
        $sorter sortset [tigr ids]
        return
    }


    # finished
    #
    # This command is called to determine whether or not the user has
    # completed all necessary tasks on this page.  It returns 1
    # if we can go on to the next page, and 0 otherwise.

    method finished {} {
        return [ingester gotSorting]
    }


    # leave
    #
    # This command is called when the user presses the wizman's
    # "Next" button to go on to the next page.  It should trigger
    # any processing that needs to be done as the result of the
    # choices made on this page, before the next page is entered.

    method leave {} {
        # TBD: This will change when I implement an event type
        # that requires more sorting.
        ingester ingestEvents
        return
    }
}