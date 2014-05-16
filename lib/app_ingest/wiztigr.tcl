#-----------------------------------------------------------------------
# TITLE:
#    wiztigr.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    wiztigr(n): A wizard manager page for retrieving TIGR messages. 
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# wiztigr widget


snit::widget wiztigr {
    #-------------------------------------------------------------------
    # Layout

    # The HTML layout for this widget.
    typevariable layout {
        <h1>Retrieve TIGR Messages</h1>
        
        Ideally, this page would contain controls for selecting a
        a time interval and possibly other search terms, to be used
        in retrieving some set of TIGR messages.  For the present,
        however, we have a canned set of TIGR messages.  Press the
        button, below, to retrieve them.<p>

        <input name="bretrieve"><p>

        <input name="status"><p>
    }
    
    #-------------------------------------------------------------------
    # Components

    component hframe     ;# htmlframe(n) widget to contain the content.
    component bretrieve  ;# retrieval button
    component status     ;# Status message
    
    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    #-------------------------------------------------------------------
    # Variables

    # Info array: wizard data
    #
    # status  - A status message

    variable info -array {
        status {}
    }

    #-------------------------------------------------------------------
    # Constructor
    #

    constructor {args} {
        # FIRST, set the default size of this page.
        $hull configure \
            -height 300 \
            -width  600

        pack propagate $win off

        # NEXT, create the HTML frame.
        install hframe using htmlframe $win.hframe

        pack $hframe -fill both -expand yes

        # NEXT, create the widgets
        install bretrieve using ttk::button $hframe.bretrieve \
            -text    "Retrieve"                               \
            -command [mymethod RetrieveMessages]

        install status using ttk::label $hframe.status \
            -textvariable [myvar info(status)]

        # NEXT, lay it out.
        $hframe layout $layout
    }

    #-------------------------------------------------------------------
    # Event handlers

    # RetrieveMessages
    #
    # Tells ingester to retrieve the messages.  TBD: This will
    # ultimately involve an asynchronous event.

    method RetrieveMessages {} {
        ingester retrieveMessages
        set number [llength [tigr ids]]
        set info(status) "Retrieved $number messages"
    }


    #-------------------------------------------------------------------
    # Wizard Page Interface

    # enter
    #
    # This command is called when wizman selects this page for
    # display.  It should do any necessary set up (i.e., pull
    # data from the data model).

    method enter {} {
        set info(status) ""
        return
    }


    # finished
    #
    # This command is called to determine whether or not the user has
    # completed all necessary tasks on this page.  It returns 1
    # if we can go on to the next page, and 0 otherwise.

    method finished {} {
        return [ingester gotMessages]
    }


    # leave
    #
    # This command is called when the user presses the wizman's
    # "Next" button to go on to the next page.  It should trigger
    # any processing that needs to be done as the result of the
    # choices made on this page, before the next page is entered.

    method leave {} {
        # Nothing to do
        return
    }
}